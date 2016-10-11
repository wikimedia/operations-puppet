# hosts with client utilities to conect to remote servers
class role::mariadb::client {
    include mysql
    include passwords::misc::scripts

    class { 'mariadb::config':
        ssl => 'puppet-cert',
    }

    $password = $passwords::misc::scripts::mysql_root_pass
    $prompt = 'MARIADB'
    file { '/root/.my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('mariadb/root.my.cnf.erb'),
    }

    package {
        [ 'percona-toolkit',
          'parallel',
        ]:
        ensure => latest,
    }
}

