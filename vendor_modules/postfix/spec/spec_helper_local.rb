require 'pathname'
dir = Pathname.new(__FILE__).parent
$LOAD_PATH.unshift(dir, File.join(dir, 'fixtures/modules/augeasproviders_core/spec/lib'), File.join(dir, '..', 'lib'))
require 'augeas_spec'

Puppet[:modulepath] = File.join(dir, 'fixtures', 'modules')

ver = Gem::Version.new(Puppet.version.split('-').first)
if ver >= Gem::Version.new('2.7.20')
  puts 'augeasproviders: setting $LOAD_PATH to work around broken type autoloading'
  Puppet.initialize_settings
  $LOAD_PATH.unshift(
    dir,
    File.join(dir, 'fixtures/modules/augeasproviders_core/spec/lib'),
    File.join(dir, 'fixtures/modules/augeasproviders_core/lib'),
  )

  $LOAD_PATH.unshift(File.join(dir, '..', 'lib'))
end
