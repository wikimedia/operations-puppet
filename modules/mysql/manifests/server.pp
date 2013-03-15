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
  $manage_service   = false
) inherits mysql::params {

  Class['mysql::server'] -> Class['mysql::config']

  $config_class = { 'mysql::config' => $config_hash }

  create_resources( 'class', $config_class )

  if $package_name =~ /mariadb/ {
    file { "/etc/apt/sources.list.d/wikimedia-mariadb.list":
      owner => root,
      group => root,
      mode => 0444,
      source => "puppet:///modules/coredb_mysql/wikimedia-mariadb.list"
    }
    exec { "update_mysql_apt":
      subscribe => File['/etc/apt/sources.list.d/wikimedia-mariadb.list'],
      command => "/usr/bin/apt-get update",
      refreshonly => true;
    }
  }

  package { 'mysql-server':
    ensure   => $package_ensure,
    name     => $package_name,
    require  => $package_name ? {
      "mariadb-server-5.5" => File["/etc/apt/sources.list.d/wikimedia-mariadb.list"],
      ## not sure about this...
      default => true,
    }
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  if $manage_service {
    service { 'mysqld':
      ensure   => $service_ensure,
      name     => $service_name,
      enable   => $enabled,
      require  => Package['mysql-server'],
      provider => $service_provider,
    }
  }
}
