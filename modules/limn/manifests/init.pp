# == Class limn
# Sets up limn.
# To spawn up a limn server instance, use the limn::instance define.
#
# NOTE: This does not install limn.  You must do that youself.
# When you use limn::instance, set $base_directory to the location
# in which you installed limn.
#
# == Parameters
# $var_directory  - Default path to Limn var directory.  This will also be limn user's home directory.  Default: /var/lib/limn
# $log_directory  - Default path to Limn server logs.  Default: /var/log/limn
#
class limn(
  $var_directory  = '/var/lib/limn',
  $log_directory  = '/var/log/limn')
{
  $user  = 'limn'
  $group = 'limn'

  # Make sure nodejs is installed.
  if (!defined(Package['nodejs'])) {
    package { 'nodejs':
      ensure => installed,
    }
  }

  generic::systemuser { $user:
    name          => $user,
    gid           => $group,
    managehome    => false,
    home          => $var_directory,
    default_group => $group,
  }

  # Default limn containing data directory.
  # Instances default to storing data in
  
  # $var_directory/$name
  file { $var_directory:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => [System::User[$user], Group[$group]],
  }

  # Default limn log directory.
  # Instances will log to
  # $log_directory/limn-$name.log
  file { $log_directory:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => [System::User[$user], Group[$group]],
  }
}
