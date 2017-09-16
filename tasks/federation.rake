import File.join Gem.loaded_specs['aquae'].loaded_from.pathmap('%d'), 'tasks', 'certificates.rake'

file 'blue-badge.federation' => ['bb-web-client.crt', 'bb-query-server.crt', 'bb-da-pip.crt', 'bb-da-dla.crt'] do |file|
  require 'aquae/protos/metadata.pb'
  require 'aquae/federation'
  include Aquae::Metadata

  m = Federation.new
  m.validity = Validity.new version: '1', validFrom: Time.now.strftime('%FT%TZ'), validTo: (Time.now + 60 * 60 * 24 * 365).strftime('%FT%TZ')
  m.node << Node.new(name: 'bb-web-client', location: Endpoint.new(hostname: '127.0.0.1', port_number: 8091), certificate: File.binread('./bb-web-client.crt'))
  m.node << Node.new(name: 'bb-query-server', location: Endpoint.new(hostname: '127.0.0.1', port_number: 8092), certificate: File.binread('./bb-query-server.crt'))
  m.node << Node.new(name: 'bb-da-pip', location: Endpoint.new(hostname: '127.0.0.1', port_number: 8093), certificate: File.binread('./bb-da-pip.crt'))
  m.node << Node.new(name: 'bb-da-dla', location: Endpoint.new(hostname: '127.0.0.1', port_number: 8094), certificate: File.binread('./bb-da-dla.crt'))
  m.query << QuerySpec.new(
    name: 'pip>8?',
    node: [
      ImplementingNode.new(
        nodeId: 'bb-da-pip',
        matchingRequirements: MatchingSpec.new(
          required: [MatchingSpec::IdFields::SURNAME, MatchingSpec::IdFields::YEAR_OF_BIRTH],
          disambiguators: [MatchingSpec::IdFields::HOUSE_NUMBER, MatchingSpec::IdFields::DATE_OF_BIRTH]
        )
      )
    ])
  m.query << QuerySpec.new(
    name: 'dla-higher?',
    node: [
      ImplementingNode.new(
        nodeId: 'bb-da-dla',
        matchingRequirements: MatchingSpec.new(
          required: [MatchingSpec::IdFields::SURNAME, MatchingSpec::IdFields::POSTCODE],
          disambiguators: [MatchingSpec::IdFields::HOUSE_NUMBER]
        )
      )
    ])
  m.query << QuerySpec.new(
    name: 'bb?',
    node: [ImplementingNode.new(nodeId: 'bb-query-server')],
    choice: [
      Choice.new(requiredQuery: ['pip>8?']),
      Choice.new(requiredQuery: ['dla-higher?'])
    ])

  File.binwrite file.name, m.encode
end