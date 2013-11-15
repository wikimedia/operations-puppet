# mysql.pp

# These classes contain a bunch of stuff that's specific to
# the wmf production DB systems.  If you want to construct
# a general-purpose DB server or client, best look elsewhere.

class mysql_wmf(
    $mariadb = false,
    ) {
    monitor_service { 'mysql disk space': description => 'MySQL disk space', check_command => 'nrpe_check_disk_6_3', critical => true }

    #######################################################################
    ### MASTERS - make sure to update here whenever changing replication
    #######################################################################
    if $::hostname =~ /^blondel/ {
        $master = true
        $writable = true
    } else {
        $master = false
    }

    #######################################################################
    ### Cluster Definitions - update if changing / building new dbs
    #######################################################################
    if $::hostname =~ /^blondel|bellin$/ {
        $db_cluster = 'm1'
    }
    else {
        $db_cluster = undef
    }

    if ($db_cluster) {
        file { '/etc/db.cluster':
            content => $db_cluster;
        }
        # this is for the pt-heartbeat daemon, which needs super privs
        # to write to read_only=1 databases.
        if ($db_cluster !~ /fund/) {
            include passwords::misc::scripts
            file {
                '/root/.my.cnf':
                    owner   => root,
                    group   => root,
                    mode    => '0400',
                    content => template('mysql_wmf/root.my.cnf.erb');
                '/etc/init.d/pt-heartbeat':
                    owner  => root,
                    group  => root,
                    mode   => '0555',
                    source => 'puppet:///modules/mysql_wmf/pt-heartbeat.init';
            }
            service { 'pt-heartbeat':
                ensure    => running,
                require   => [ File['/etc/init.d/pt-heartbeat'], Package[percona-toolkit] ],
                subscribe => File['/etc/init.d/pt-heartbeat'],
                hasstatus => false;
            }
            include mysql_wmf::monitor::percona
            if ($db_cluster =~ /^m1/) {
                include mysql_wmf::slow_digest
            }
        }
    }

    file { '/usr/local/bin/master_id.py':
        owner  => root,
        group  => root,
        mode   => '0555',
        source => 'puppet:///modules/mysql_wmf/master_id.py'
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
    file {
        '/a/sqldata':
            ensure  => directory,
            owner   => mysql,
            group   => mysql,
            mode    => '0755',
            require => User['mysql'];
        '/a/tmp':
            ensure  => directory,
            owner   => mysql,
            group   => mysql,
            mode    => '0755',
            require => User['mysql'];
    }
}

class mysql_wmf::pc::conf inherits mysql_wmf {
    file { '/etc/my.cnf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        content => template('mysql_wmf/paresercache.my.cnf.erb')
    }
    file { '/etc/mysql/my.cnf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/mysql_wmf/empty-my.cnf'
    }
}

class mysql_wmf::mysqlpath {
    file { '/etc/profile.d/mysqlpath.sh':
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///modules/mysql_wmf/mysqlpath.sh'
    }
}

# TODO do we want to have a class for PHP clients (php5-mysql) as well
# and rename this to mysql::client-cli?
class mysql_wmf::client {
    if versioncmp($::lsbdistrelease, '12.04') >= 0 {
        package { 'mysql-client-5.5':
            ensure => latest;
        }
    } else {
        package { 'mysql-client-5.1':
            ensure => latest;
        }
    }
}

class mysql_wmf::slow_digest {
    include passwords::mysql::querydigest
    $mysql_user = 'ops'
    $digest_host = 'db9.pmtpa.wmnet'
    $digest_db = 'query_digests'

    file {
        '/usr/local/bin/send_query_digest.sh':
            owner   => root,
            group   => root,
            mode    => '0500',
            content => template('mysql_wmf/send_query_digest.sh.erb');
    }

    if $mysql_wmf::db_cluster {
        cron { 'slow_digest':
            ensure  => present,
            command => '/usr/local/bin/send_query_digest.sh >/dev/null 2>&1',
            require => File['/usr/local/bin/send_query_digest.sh'],
            user    => root,
            minute  => '*/20',
            hour    => '*';
        }
        cron { 'tcp_query_digest':
            ensure  => present,
            command => '/usr/local/bin/send_query_digest.sh tcpdump >/dev/null 2>&1',
            require => File['/usr/local/bin/send_query_digest.sh'],
            user    => root,
            minute  => [5, 25, 45],
            hour    => '*';
        }
    }
}
