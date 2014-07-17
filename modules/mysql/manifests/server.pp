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

  Class['mysql::server::package'] -> Class['mysql::config']

  $config_class = { 'mysql::config' => $config_hash }

  create_resources( 'class', $config_class )

  class {'mysql::server::package':
    package_name => $package_name,
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

  include apparmor
  # mysql is protected by apparmor.  Need to
  # reload apparmor if the file changes.
  file { "/etc/apparmor.d/usr.sbin.mysqld":
    owner => 'root',
    group => 'root',
    mode => 0644,
    content => template('mysql/apparmor.template.usr.sbin.mysqld.erb'),
    require => Package['mysql-server'],
    notify => Service['apparmor'],
  }


  # This is needed because reconfigure creates $datadir and the necessary files inside.
  # The sleep is to avoid mysql getting canned for speedy respawn;
  #   the retry is to give apparmor a chance to settle in.
  exec { "dpkg-reconfigure mysql-server":
    command => "/bin/sleep 30; /usr/sbin/dpkg-reconfigure -fnoninteractive ${package_name}",
    require => [File["/etc/apparmor.d/usr.sbin.mysqld"]],
    tries => 2,
    refreshonly => true,
    subscribe => File['/etc/mysql/my.cnf']
  }
}

# This is handled by a separate class in case we want to just
# install the package and configure elsewhere.
class mysql::server::package (
  $package_name     = $mysql::params::server_package_name,
) {
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
      default => undef
    }
  }
}
