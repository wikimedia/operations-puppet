# coredb_mysql required packages
class coredb_mysql::conf {

    file { '/etc/db.cluster':
        content => $coredb_mysql::shard,
    }

    file { '/etc/my.cnf':
        content => template('coredb_mysql/prod.my.cnf.erb'),
    }

    file { '/etc/mysql/my.cnf':
        ensure => link,
        target => '/etc/my.cnf',
    }
}
