
class mysql_multi_instance {

    apt::repository { 'wikimedia-mariadb':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => 'precise-wikimedia',
        components => 'mariadb',
    }

    package { 'mysql-server':
        ensure   => present,
        name     => 'mariadb-server-5.5',
        require  => Apt::Repository['wikimedia-mariadb'],
    }

    package { ['percona-xtrabackup', 
            'percona-toolkit',
            'libaio1',
            'lvm2' ]:
        ensure => latest,
    }

    generic::systemuser { 'mysql':
        name  => 'mysql',
        shell => '/bin/sh',
        home  => '/home/mysql',
    }

    file { '/a/tmp/':
      ensure  => directory,
      owner   => 'mysql',
      group   => 'mysql',
      mode    => '0755',
      require => User['mysql'],
    }

    file { '/etc/mysql':
      ensure  => directory,
      mode    => '0755',
    }

    file { '/etc/mysql/conf.d':
      ensure  => directory,
      mode    => '0755',
    }

    file { '/root/.my.cnf':
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => template('mysql_multi_instance/root.my.cnf.erb'),
  }
}
