# mysql.pp

# These classes contain a bunch of stuff that's specific to
# the wmf production DB systems.  If you want to construct
# a general-purpose DB server or client, best look elsewhere.

class mysql_wmf(
    $mariadb = false,
    ) {
    nrpe::monitor_service { 'mysql_disk_space':
        description  => 'MySQL disk space',
        nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 6% -c 3% -l -e',
        critical     => true,
    }
    nrpe::monitor_service { 'mysqld':
        description  => 'mysqld processes',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C mysqld',
        critical     => true,
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

