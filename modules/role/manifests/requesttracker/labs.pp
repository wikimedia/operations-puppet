#  Labs/testing RT
class role::requesttracker::labs {
    system::role { 'role::requesttracker::labs': description => 'RT (Labs)' }

    include passwords::misc::rt

    # FIXME: needs to reference a wmflabs certificate?
    sslcert::certificate { 'rt.wikimedia.org': }

    $datadir = '/srv/mysql'

    class { '::requesttracker':
        apache_site => $::fqdn,
        dbuser      => $passwords::misc::rt::rt_mysql_user,
        dbpass      => $passwords::misc::rt::rt_mysql_pass,
        datadir     => $datadir,
    }

    class { 'mysql::server':
        config_hash => {
            'datadir' => $datadir,
        },
    }

    exec { 'rt-db-initialize':
        command => "/bin/echo '' | /usr/sbin/rt-setup-database --action init --dba root --prompt-for-dba-password",
        unless  => '/usr/bin/mysqlshow rt4',
        require => Class['::requesttracker', 'mysql::server'],
    }
}

