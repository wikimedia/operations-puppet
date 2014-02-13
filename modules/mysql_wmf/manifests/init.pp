# mysql.pp

# These classes contain a bunch of stuff that's specific to
# the wmf production DB systems.  If you want to construct
# a general-purpose DB server or client, best look elsewhere.

class mysql_wmf(
    $mariadb = false,
    ) {
    nrpe::monitor_service { 'mysql_disk_space':
        description   => 'MySQL disk space',
        nrpe_command  => '/usr/lib/nagios/plugins/check_disk -w 6% -c 3% -l -e',
        critical      => true,
    }
    nrpe::monitor_service { 'mysqld':
        description   => 'mysqld processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C mysqld',
        critical      => true,
    }

    #######################################################################
    ### MASTERS - make sure to update here whenever changing replication
    #######################################################################

    $master = false


    #######################################################################
    ### Cluster Definitions - update if changing / building new dbs
    #######################################################################

    $db_cluster = undef

    if ($db_cluster) {
        file { '/etc/db.cluster':
            content => $db_cluster;
        }
        # this is for the pt-heartbeat daemon, which needs super privs
        # to write to read_only=1 databases.
        if ($db_cluster !~ /fund/) {
            include passwords::misc::scripts
            file { '/root/.my.cnf':
                    owner   => 'root',
                    group   => 'root',
                    mode    => '0400',
                    content => template('mysql_wmf/root.my.cnf.erb'),
            }
            file { '/etc/init.d/pt-heartbeat':
                    owner  => 'root',
                    group  => 'root',
                    mode   => '0555',
                    source => 'puppet:///modules/mysql_wmf/pt-heartbeat.init',
            }
            service { 'pt-heartbeat':
                ensure    => running,
                require   => [ File['/etc/init.d/pt-heartbeat'], Package[percona-toolkit] ],
                subscribe => File['/etc/init.d/pt-heartbeat'],
                hasstatus => false,
            }
            include mysql_wmf::monitor::percona
            if ($db_cluster =~ /^m1/) {
                include mysql_wmf::slow_digest
            }
        }
    }

    file { '/usr/local/bin/master_id.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/mysql_wmf/master_id.py',
    }

    class { 'mysql_wmf::ganglia': mariadb => $mariadb; }
    include mysql_wmf::monitor::percona::files

}

class mysql_wmf::mysqluser {
    user {
        'mysql': ensure => 'present',
    }
}

class mysql_wmf::datadirs {
    file { '/a/sqldata':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0755',
        require => User['mysql'],
    }
    file { '/a/tmp':
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0755',
        require => User['mysql'],
    }
}

class mysql_wmf::pc::conf inherits mysql_wmf {
    file { '/etc/my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mysql_wmf/paresercache.my.cnf.erb'),
    }
    file { '/etc/mysql/my.cnf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/mysql_wmf/empty-my.cnf',
    }
}

class mysql_wmf::mysqlpath {
    file { '/etc/profile.d/mysqlpath.sh':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/mysql_wmf/mysqlpath.sh',
    }
}

# TODO do we want to have a class for PHP clients (php5-mysql) as well
# and rename this to mysql::client-cli?
class mysql_wmf::client {
    if versioncmp($::lsbdistrelease, '12.04') >= 0 {
        package { 'mysql-client-5.5':
            ensure => latest,
        }
    } else {
        package { 'mysql-client-5.1':
            ensure => latest,
        }
    }
}

class mysql_wmf::slow_digest {
    include passwords::mysql::querydigest
    $mysql_user = 'ops'
    $digest_host = 'db1001.pmtpa.wmnet'
    $digest_db = 'query_digests'

    file { '/usr/local/bin/send_query_digest.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
        content => template('mysql_wmf/send_query_digest.sh.erb'),
    }

    if $mysql_wmf::db_cluster {
        cron { 'slow_digest':
            ensure  => present,
            command => '/usr/local/bin/send_query_digest.sh >/dev/null 2>&1',
            require => File['/usr/local/bin/send_query_digest.sh'],
            user    => root,
            minute  => '*/20',
            hour    => '*',
        }
        cron { 'tcp_query_digest':
            ensure  => present,
            command => '/usr/local/bin/send_query_digest.sh tcpdump >/dev/null 2>&1',
            require => File['/usr/local/bin/send_query_digest.sh'],
            user    => root,
            minute  => [5, 25, 45],
            hour    => '*',
        }
    }
}
