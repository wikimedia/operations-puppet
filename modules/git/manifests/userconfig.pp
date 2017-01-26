# == git::userconfig
#
# Generate a .gitconfig in $homedir based on a hash of gitconfig values.
# The file will be owned by root since it is fully managed by puppet.
#
# Parameters:
#  [*homedir*] - user home dir where .gitconfig will be written
#  [*settings*] - hash of gitconfig section name, each should be in turn a hash
#  of configuration name => value.
#
# Example usage:
#
# git::userconfig{ 'gitconf for jenkins user':
#   homedir => '/var/lib/jenkins',
#   settings => {
#     'user' => {  # '[user]'
#        'name'  => 'Antoine Musso',  # 'name = Antoine Musso'
#        'email' => 'hashar@free.fr', # 'email = hashar@free.fr'
#     },  # end of [user] section
#   }
# }
#
define git::userconfig($homedir, $settings) {

  file { "${homedir}/.gitconfig":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template( 'git/gitconfig.erb' ),
  }

}
