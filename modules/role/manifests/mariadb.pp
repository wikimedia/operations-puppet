# Generic Server
#
# filtertags: labs-project-servermon labs-project-monitoring
# lint:ignore:autoloader_layout
class role::mariadb {

    system::role { 'role::mariadb':
        description => 'database server',
    }

    include ::standard
    include ::mariadb
}

# root, repl, nagios, tendril, prometheus
# WARNING: any root user will have access to these files
# Do not apply to hosts with users with arbitrary roots
# or any non-production mysql, such as labs-support hosts,
# wikitech hosts, etc.
class role::mariadb::grants::production(
    $shard    = false,
    $prompt   = '',
    $password = 'undefined',
    ) {

    include passwords::misc::scripts
    include passwords::tendril
    include passwords::nodepool
    include passwords::testreduce::mysql
    include passwords::racktables
    include passwords::prometheus
    include passwords::servermon
    include passwords::striker
    include passwords::labsdbaccounts

    $root_pass       = $passwords::misc::scripts::mysql_root_pass
    $repl_pass       = $passwords::misc::scripts::mysql_repl_pass
    $nagios_pass     = $passwords::misc::scripts::nagios_sql_pass
    $tendril_user    = $passwords::tendril::db_user
    $tendril_pass    = $passwords::tendril::db_pass
    $prometheus_pass = $passwords::prometheus::db_pass

    file { '/etc/mysql/production-grants.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('role/mariadb/grants/production.sql.erb'),
    }

    file { '/root/.my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('mariadb/root.my.cnf.erb'),
    }

    if $shard {
        $nodepool_pass       = $passwords::nodepool::nodepooldb_pass
        $testreduce_pass     = $passwords::testreduce::mysql::db_pass
        $testreduce_cli_pass = $passwords::testreduce::mysql::mysql_client_pass
        $racktables_user     = $passwords::racktables::racktables_db_user
        $racktables_pass     = $passwords::racktables::racktables_db_pass
        $servermon_pass      = $passwords::servermon::db_password
        $striker_pass        = $passwords::striker::application_db_password
        $striker_admin_pass  = $passwords::striker::admin_db_password
        $labspuppet_pass     = hiera('labspuppetbackend_mysql_password')
        $labsdbaccounts_pass = $passwords::labsdbaccounts::db_password

        file { '/etc/mysql/production-grants-shard.sql':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            content => template("role/mariadb/grants/production-${shard}.sql.erb"),
        }
    }
}

# wikiadmin, wikiuser
class role::mariadb::grants::core {

    include passwords::misc::scripts

    $wikiadmin_pass = $passwords::misc::scripts::wikiadmin_pass
    $wikiuser_pass  = $passwords::misc::scripts::wikiuser_pass

    file { '/etc/mysql/production-grants-core.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('role/mariadb/grants/production-core.sql.erb'),
    }
}

class role::mariadb::grants::wikitech {

    include passwords::misc::scripts
    $wikiadmin_pass = $passwords::misc::scripts::wikiadmin_pass
    $keystoneconfig  = hiera_hash('keystoneconfig', {})
    $oathreader_pass = $keystoneconfig['oath_dbpass']

    file { '/etc/mysql/grants-wikitech.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('role/mariadb/grants/wikitech.sql.erb'),
    }
}

# Annoy people in #wikimedia-operations
class role::mariadb::monitor {

    class { 'mariadb::monitor_disk':
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        contact_group => 'admins',
    }
}

# Annoy Sean
class role::mariadb::monitor::dba {

    include mariadb::monitor_disk
    include mariadb::monitor_process
}

# mysql groups for monitoring and salt
# * mysql_group (required): general usage of the server, for example:
#   - 'core': production mediawiki servers
#   - 'dbstore': servers for backup and analytics
#   - 'labs': production and labs replicas of production
#   - 'misc': other services
# * mysql_shard (optional): for 'core', 'misc' and 'pc' services, vertical
#   slices:
#   - 's1': English Wikipedia (see dblists on mediawiki-config)
#   - 'm1': puppet, bacula, etc.
#   - most services are not segmented and will return the empty string ('')
# * mysql_role (required). One of three:
# - 'master': for the masters of each datacenter (one per shard and
#   datacenter). Only the one on the active datacenter is read-write of
#   all the ones on the same shard.
# - 'slave': for read-only slave
# - 'standalone': single servers that are not part of replication,
#   such as read-only 'es1' hosts; wikitech, or tendril

#FIXME: move node_exporter to standard and remove it from here when ready
#FIXME: temporarely make the socket '/tmp/mysql.sock' until all manifests
#       are updated
class role::mariadb::groups(
    $mysql_group,
    $mysql_role,
    $mysql_shard = '',
    $socket = '/tmp/mysql.sock',
    ) {

    salt::grain { 'mysql_group':
        ensure  => present,
        replace => true,
        value   => $mysql_group,
    }

    salt::grain { 'mysql_role':
        ensure  => present,
        replace => true,
        value   => $mysql_role,
    }

    if $mysql_shard != '' {
        salt::grain { 'mysql_shard':
            ensure  => present,
            replace => true,
            value   => $mysql_shard,
        }
    }

    include role::prometheus::node_exporter
    class { 'role::prometheus::mysqld_exporter':
        socket => $socket,
    }
}

# MariaDB 10 Analytics all-shards slave, with scratch space and TokuDB
# analytics slaves are already either dbstores or eventlogging slaves
# so they just need the extra core monitoring
class role::mariadb::analytics {
    mariadb::monitor_replication { ['s1','s2']:
        is_critical   => false,
        contact_group => 'admins', # only show on nagios/irc
        multisource   => true,
    }
}

class role::mariadb::analytics::custom_repl_slave {

    # move files to module?
    # lint:ignore:puppet_url_without_modules
    file { '/usr/local/bin/eventlogging_sync.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
        source => 'puppet:///modules/mariadb/eventlogging_sync.sh',
    }
    file { '/etc/init.d/eventlogging_sync':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/mariadb/eventlogging_sync.init',
        require => File['/usr/local/bin/eventlogging_sync.sh'],
        notify  => Service['eventlogging_sync'],
    }
    # lint:endignore

    service { 'eventlogging_sync':
        ensure => running,
        enable => true,
    }
    nrpe::monitor_service { 'eventlogging_sync':
        description   => 'eventlogging_sync processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:2 -u root -a "/bin/bash /usr/local/bin/eventlogging_sync.sh"',
        critical      => false,
        contact_group => 'admins', # show on icinga/irc only
    }
}

# MariaDB 10 labsdb multiple-shards slave.
# This role is deprecated but still in use
# It should be migrated to labs::db::slave
class role::mariadb::labs {

    system::role { 'role::mariadb::labs':
        description => 'Labs DB Slave',
    }

    include ::standard
    include role::mariadb::monitor
    include passwords::misc::scripts
    include role::mariadb::ferm
    include ::base::firewall
    include role::labs::db::common
    include role::labs::db::views
    include role::labs::db::check_private_data

    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
    }

    include mariadb::packages_wmf
    include mariadb::service

    class { 'mariadb::config':
        config  => 'role/mariadb/mysqld_config/labs.my.cnf.erb',
        datadir => '/srv/sqldata',
        tmpdir  => '/srv/tmp',
    }

    file { '/srv/innodb':
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    file { '/srv/tokudb':
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    # Required for TokuDB to start
    # See https://mariadb.com/kb/en/mariadb/enabling-tokudb/#check-for-transparent-hugepage-support-on-linux
    sysfs::parameters { 'disable-transparent-hugepages':
        values => {
            'kernel/mm/transparent_hugepage/enabled' => 'never',
            'kernel/mm/transparent_hugepage/defrag'  => 'never',
        }
    }
}

# lint:endignore
