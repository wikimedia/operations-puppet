# == git::config
#
# Generate a git configuration file based on a hash of gitconfig values.
#
# The file will be owned by root since it is fully managed by puppet.
#
# Parameters:
#  [*title*]
#    Full path to the file to be managed.
#  [*settings*]
#    Hash of gitconfig section name, each should be in turn a hash
#    of configuration name => value.
#
define git::config(Hash[String, Hash[String, String]] $settings) {

  file { $title:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template( 'git/gitconfig.erb' ),
  }

}
