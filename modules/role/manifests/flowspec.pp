# == Class role::flowspec
#
# Install and manage a Flowspec controller and its requirements
#
class role::flowspec {

  system::role { 'flowspec':
      description => 'Flowspec network controller',
  }
  include profile::base::production
  include profile::base::firewall
  include profile::flowspec
}
