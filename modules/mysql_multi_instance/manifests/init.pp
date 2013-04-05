
class mysql_multi_instance {

  file { "/etc/apt/sources.list.d/wikimedia-mariadb.list":
    owner  => root,
    group  => root,
    mode   => 0444,
    source => "puppet:///modules/coredb_mysql/wikimedia-mariadb.list"
  }
  exec { "update_mysql_apt":
    subscribe   => File['/etc/apt/sources.list.d/wikimedia-mariadb.list'],
    command     => "/usr/bin/apt-get update",
    refreshonly => true;
  }

  package { 'mysql-server':
    ensure   => present,
    name     => "mariadb-server-5.5",
    require  => File["/etc/apt/sources.list.d/wikimedia-mariadb.list"];
  }

  package { ["percona-xtrabackup", "percona-toolkit", "libaio1",  "lvm2" ]:
    ensure => latest,
  }

  systemuser {
    "mysql": name => "mysql", shell => "/bin/sh", home => "/home/mysql"
  }

  file {
    '/a/tmp/':
      owner   => mysql,
      group   => mysql,
      mode    => 0755,
      ensure  => directory,
      require => User["mysql"];
    '/etc/mysql':
      ensure  => directory,
      mode    => '0755';
    '/etc/mysql/conf.d':
      ensure  => directory,
      mode    => '0755';
    '/root/.my.cnf':
      owner => root,
      group => root,
      mode => 0400,
      content => template("mysql_multi_instance/root.my.cnf.erb");
  }
}
