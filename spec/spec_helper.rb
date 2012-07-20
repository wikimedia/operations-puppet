# vim: ts=2 sw=2 noet

require 'rspec-puppet'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))
RSpec.configure do |c|
	c.module_path  = File.join(fixture_path, 'modules'       )
	c.manifest_dir = File.join(fixture_path, 'manifests'     )
	c.template_dir = File.join(fixture_path, 'templates'     )

	# Bootstrap to let us inject puppet global variables
	c.manifest     = File.join(fixture_path, 'bootstrap.pp' )

	#c.config ??
end
