# deploy scripts and its dependencies to create replica views
class role::labs::db::views {

    package { [
        'python-pymysql',
        'python-requests',
        'python-simplejson',
    ]:
        ensure => present,
    }

    include passwords::labsdb::maintainviews
    $view_user = $::passwords::labsdb::maintainviews::user
    $view_pass = $::passwords::labsdb::maintainviews::db_pass
    file { '/etc/maintain-views.yaml':
        ensure  => file,
        content => template('role/labs/db/views/maintain-views.yaml'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/usr/local/sbin/maintain-views':
        ensure  => file,
        source  => 'puppet:///modules/role/labs/db/views/maintain-views.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0655',
        require => [Package['python3-yaml', 'python3-pymysql'],
                    Git::Clone['operations/mediawiki-config'],
        ],
    }

    file { '/usr/local/sbin/maintain-meta_p':
        ensure  => file,
        source  => 'puppet:///modules/role/labs/db/views/maintain-meta_p.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0655',
        require => [Package['python-simplejson', 'python-pymysql']],
    }

    file { '/usr/local/src/heartbeat-views.sql':
        ensure => file,
        source => 'puppet:///modules/role/labs/db/views/heartbeat-views.sql',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
