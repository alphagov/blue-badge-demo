AQUAE_SPEC = Gem.loaded_specs['aquae']
if AQUAE_SPEC.nil?
  STDERR.puts "Gem `aquae` not found - certificate tasks will not be available. You may need to use `bundle exec`."
else
  import File.join AQUAE_SPEC.full_gem_path, 'tasks', 'certificates.rake'
end

task :config => ['bb-web-client.config.yml', 'bb-query-server.config.yml', 'bb-da-pip.config.yml', 'bb-da-dla.config.yml']

desc 'Generate a federation for use with the demo'
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
      Choice.new(requiredQuery: ['pip>8?', 'dla-higher?']),
    ])

  File.binwrite file.name, m.encode
end

rule /\.config\.yml$/ => lambda {|n| ['blue-badge.federation', n.pathmap('%{.config,}n.private.pem')]} do |file|
  require 'yaml'
  keys = {
    'metadata' => file.sources.first,
    'keyfile' => file.sources.last,
    'this_node' => file.name.pathmap('%{.config,}n')}
  queryfile = file.name.pathmap '%{.config,.queries}X.rb'
  keys['queryfiles'] = [queryfile] if File.exists?(queryfile)
  File.write file.name, YAML.dump(keys)
end