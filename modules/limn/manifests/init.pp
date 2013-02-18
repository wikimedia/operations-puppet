# == Class limn
# Installs limn.
# To spawn up a limn server instance, use the limn::instance define.
#
# == Parameters
# $var_directory  - Default path to Limn var directory.  This will also be limn user's home directory.  Default: /var/lib/limn
# $log_directory  - Default path to Limn server logs.  Default: /var/log/limn
# $user           - Limn user.  Default: limn
# $group          - Limn group.  Default: limn
# $install        - Boolean.  If true, the limn package will be installed.
#
class limn(
  $var_directory  = '/var/lib/limn',
  $log_directory  = '/var/log/limn',
  $install        = false)
{
  $user  = 'limn'
  $group = 'limn'
  
  # Make sure nodejs is installed.
  if (!defined(Package['nodejs'])) {
    package { 'nodejs':
      ensure => installed,
    }
  }

  # Only install using limn package if
  # $install is true.
  if ($install) {
    package { 'limn':
      ensure  => present,
      require => Package['nodejs'],
    }
  }


  group { $group:
    ensure => present,
    system => true,
  }

  user { $user:
    ensure     => present,
    gid        => $group,
    home       => $var_directory,
    managehome => false,
    system     => true,
    require    => Group[$group],
  }

  # Default limn containing data directory.
  # Instances default to storing data in
  # $var_directory/$name
  file { $var_directory:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => [User[$limn], Group[$limn]],

  }

  # Default limn log directory.
  # Instances will log to
  # $log_directory/limn-$name.log
  file { $log_directory:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => [User[$limn], Group[$limn]],
  }
}