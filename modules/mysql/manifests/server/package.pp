# This is handled by a separate class in case we want to just
# install the package and configure elsewhere.
class mysql::server::package (
  $package_name     = $mysql::params::server_package_name,
) {
  if $package_name =~ /mariadb/ {
    file { '/etc/apt/sources.list.d/wikimedia-mariadb.list':
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      source => 'puppet:///modules/coredb_mysql/wikimedia-mariadb.list'
    }
    exec { 'update_mysql_apt':
      subscribe   => File['/etc/apt/sources.list.d/wikimedia-mariadb.list'],
      command     => '/usr/bin/apt-get update',
      refreshonly => true;
    }
  }

  package { 'mysql-server':
    ensure    => $package_ensure,
    name      => $package_name,
    require   => $package_name ? {
      'mariadb-server-5.5' => File['/etc/apt/sources.list.d/wikimedia-mariadb.list'],
      default => undef
    }
  }
}
