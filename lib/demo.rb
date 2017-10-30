require 'sinatra/base'
require 'liquid'
require_relative '../lib/bodge_file_system'

class Demo < Sinatra::Application
  # If username and password are defined, use them for Basic auth
  if ENV["USERNAME"] && ENV["PASSWORD"]
    use Rack::Auth::Basic, "Demo Visualiser" do |username, password|
      username == ENV["USERNAME"] && password == ENV["PASSWORD"]
    end
  end

  configure do
    Liquid::Template.file_system = BodgeFileSystem.new(File.join(File.dirname(__FILE__),'../', 'views/'), '%s'.freeze)
  end

  LOGLINE_REGEX = /([A-Z]+)\s+\[([a-zA-Z0-9\-]+)\] \(([0-9]+)\): ([a-f0-9\-]+: )?(.*)$/

  def parse_logline line
    LOGLINE_REGEX.match line do |matches|
      query = matches[4] ? matches[4][0..-3] : nil
      {severity: matches[1], node: matches[2], time: matches[3].to_i, query: query, message: matches[5]}
    end
  end

  def all_lines
    settings.logfiles.flat_map do |filename|
      begin
        File.foreach(filename).to_a
      rescue
        []
      end
    end
  end

  def available_queries
    all_lines.map {|l| parse_logline(l) }.reject(&:nil?).map {|l| l[:query] }.uniq.reject(&:nil?)
  end

  def lines_for_query query
    all_lines.select {|l| (parse_logline(l) || {})[:query] == query }
  end

  # Show the single page needed for a demo
  get '/' do
    template = Liquid::Template.parse File.read File.join('./views/', 'demo.liquid')
    template.render
  end

  # Serve the list of available queries
  get '/available' do
    content_type 'application/json'
    available_queries.to_json
  end

  # Output all the lines for the specified query
  get %r{/(?<query>[a-f0-9\-]+)} do
    content_type 'text/plain'
    lines_for_query(params[:query]).join
  end

  # Generate routes to serve all public assets.
  # This is safer than a `get ./public/*` because
  # the glob is expanded up front.
  Dir.glob("./public/**/*") do |path|
    get path[1..-1] do
      send_file path
    end
  end
end