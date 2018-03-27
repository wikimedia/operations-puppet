# deploy scripts and its dependencies to create replica views
class profile::labs::db::views (
    $view_user = hiera('profile::labsdb::maintainviews::user'),
    $view_pass = hiera('profile::labsdb::maintainviews::db_pass'),
    $idx_user = hiera('profile::labsdb::maintainindexes::user'),
    $idx_pass = hiera('profile::labsdb::maintainindexes::db_pass'),
){

    package { [
        'python-pymysql',
        'python-requests',
        'python-simplejson',
        'python3-psutil'
    ]:
        ensure => present,
    }

    file { '/etc/maintain-views.yaml':
        ensure  => file,
        content => template('profile/labs/db/views/maintain-views.yaml'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/usr/local/sbin/maintain-views':
        ensure  => file,
        source  => 'puppet:///modules/profile/labs/db/views/maintain-views.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0655',
        require => [Package['python3-yaml', 'python3-pymysql'],
                    Git::Clone['operations/mediawiki-config'],
        ],
    }

    file { '/etc/index-conf.yaml':
        ensure  => file,
        content => template('profile/labs/db/views/index-conf.yaml'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/usr/local/sbin/maintain_replica_indexes.py':
        ensure  => file,
        source  => 'puppet:///modules/profile/labs/db/views/maintain_replica_indexes.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0655',
        require => [Package['python3-yaml', 'python3-pymysql', 'python3-psutil'],
                    Git::Clone['operations/mediawiki-config'],
        ],
    }

    file { '/usr/local/sbin/maintain-meta_p':
        ensure  => file,
        source  => 'puppet:///modules/profile/labs/db/views/maintain-meta_p.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0655',
        require => [Package['python-simplejson', 'python-pymysql']],
    }

    file { '/usr/local/src/heartbeat-views.sql':
        ensure => file,
        source => 'puppet:///modules/profile/labs/db/views/heartbeat-views.sql',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
