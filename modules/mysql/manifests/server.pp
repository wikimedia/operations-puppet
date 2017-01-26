# Class: mysql::server
#
# manages the installation of the mysql server.  manages the package, service,
# my.cnf
#
# Parameters:
#   [*package_name*] - name of package
#   [*service_name*] - name of service
#   [*config_hash*]  - hash of config parameters that need to be set.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class mysql::server (
  $package_name     = $mysql::params::server_package_name,
  $package_ensure   = 'present',
  $service_name     = $mysql::params::service_name,
  $service_provider = $mysql::params::service_provider,
  $config_hash      = {},
  $enabled          = true,
  $manage_service   = false,
  $use_apparmor     = true,
# FIXME - class inheriting from params class
# lint:ignore:class_inherits_from_params_class
) inherits mysql::params {
# lint:endignore

  Class['mysql::server::package'] -> Class['mysql::config']

  $config_class = { 'mysql::config' => $config_hash }

  create_resources( 'class', $config_class )

  class {'::mysql::server::package':
    package_name => $package_name,
  }

  if $manage_service {
    service { 'mysqld':
      ensure   => ensure_service($enabled),
      name     => $service_name,
      enable   => $enabled,
      require  => Package['mysql-server'],
      provider => $service_provider,
    }
  }

  if $use_apparmor {
      include ::apparmor
      # mysql is protected by apparmor.  Need to
      # reload apparmor if the file changes.
      file { '/etc/apparmor.d/usr.sbin.mysqld':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('mysql/apparmor.template.usr.sbin.mysqld.erb'),
        require => Package['mysql-server'],
        notify  => Service['apparmor'],
      }

      # This is needed because reconfigure creates $datadir and the necessary files inside.
      # The sleep is to avoid mysql getting canned for speedy respawn;
      #   the retry is to give apparmor a chance to settle in.
      exec { 'dpkg-reconfigure mysql-server':
        command     => "/bin/sleep 30; /usr/sbin/dpkg-reconfigure -fnoninteractive ${package_name}",
        require     => [File['/etc/apparmor.d/usr.sbin.mysqld']],
        tries       => 2,
        refreshonly => true,
        subscribe   => File['/etc/mysql/my.cnf'],
      }
  }
}

