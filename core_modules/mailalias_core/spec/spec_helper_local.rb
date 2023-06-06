dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(dir, 'lib')

# So everyone else doesn't have to include this base constant.
module PuppetSpec
  FIXTURE_DIR = File.join(File.expand_path(File.dirname(__FILE__)), 'fixtures') unless defined?(FIXTURE_DIR)
end

require 'puppet_spec/files'

Pathname.glob("#{dir}/shared_behaviours/**/*.rb") do |behaviour|
  require behaviour.relative_path_from(Pathname.new(dir))
end
