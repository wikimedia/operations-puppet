# coredb_mysql heartbeat capability
class coredb_mysql::heartbeat {
    require coredb_mysql::packages
    include passwords::misc::scripts

    file { '/root/.my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('coredb_mysql/root.my.cnf.erb'),
    }

    file { '/etc/init.d/pt-heartbeat':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/coredb_mysql/utils/pt-heartbeat.init',
    }

    service { 'pt-heartbeat':
        ensure    => running,
        require   => File['/etc/init.d/pt-heartbeat'],
        subscribe => File['/etc/init.d/pt-heartbeat'],
        hasstatus => false,
    }
}
