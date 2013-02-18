# == Define limn::instance
# Starts up a Limn Server instance.
#
# == Parameters:
# $port           - Listen port for Limn instance.  Default: 8081
# $environment    - Node environment.  Default: production
# $var_directory  - Limn instance var directory.  Default: /var/lib/limn/$name
# $log_file       - Limn instance log file.  Default: /var/log/lim/limn-$name.log
# $user           - Limn instance will run as this user.  Default: limn
# $group          - Limn instance will run in this group.  Default: limn
# $base_directory - Limn install base directory.  Default: /usr/lib/limn
# $proxy          - Boolean.  If true, the apache module will be used to set up an Apache VirtualHost using mod_proxy to proxy HTTP requests to Limn.  Default: true
# $ensure         - present|absent.  Default: present
#
define limn::instance (
  $port           = 8081,
  $environment    = 'production',
  $var_directory  = "/var/lib/limn/${name}",
  $log_file       = "/var/log/limn/limn-${name}.log",
  $user           = 'limn',
  $group          = 'limn',
  $base_directory = '/usr/lib/limn',
  $proxy          = true,
  $ensure         = 'present')
{
  require limn

  file { $base_directory:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => '0775',
  }

  file { $var_directory:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => '0775',
  }

  # The upstart init conf will start server.co
  # logging to this file.
  file { $log_file:
    ensure => 'file',
    owner  => $user,
    group  => $group,
    mode   => '0775',
  }

  # Install an upstart init file for this limn server instance.
  file { "/etc/init/limn-${name}.conf":
    ensure    => $ensure,
    content   => template('limn/limn.init.erb'),
    owner     => 'root',
    group     => 'root',
    mode      => '0644',
    require   => [File[$var_directory], File[$log_file]],
  }

  # Symlink an /etc/init.d script to upstart-job
  # for SysV compatibility.
  $sysv_ensure = $ensure ? {
    present   => 'link',
    default   => 'absent',
  }
  file { "/etc/init.d/limn-${name}":
    ensure  => $sysv_ensure,
    target  => '/lib/init/upstart-job',
    require => File["/etc/init/limn-${name}.conf"],
  }

  # Start the service.
  $service_ensure = $ensure ? {
    present   => 'running',
    default   => 'stopped',
  }
  service { "limn-${name}":
    ensure     => $service_ensure,
    provider   => 'upstart',
    subscribe  => File["/etc/init/limn-${name}.conf"],
  }

  # if we are to set up Apache proxy
  if ($proxy) {
    limn::instance::proxy { $name:
      limn_port  => $port,
    }
  }
}