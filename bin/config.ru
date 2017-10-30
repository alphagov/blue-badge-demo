require_relative '../lib/demo'
require_relative '../lib/prototype'

prototype = FrontEndPrototype.new do |app|
  app.settings.set :configfile, './bb-web-client.config.yml'
  app.settings.set :log_dir, (ENV['TMPDIR'] || '.')
end

demo = Demo.new do |app|
  app.settings.set :logfiles, (['./bb-da-pip.log.txt', './bb-da-dla.log.txt', './bb-query-server.log.txt', './bb-web-client.log.txt'].map do |f|
    File.join(ENV['TMPDIR'] || '.', f)
  end)
end

run Rack::URLMap.new('/' => prototype, '/demo' => demo)