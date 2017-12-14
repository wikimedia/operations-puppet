# Generic Server
#
# filtertags: labs-project-servermon labs-project-monitoring
# lint:ignore:autoloader_layout
class role::mariadb {

    system::role { 'mariadb':
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
    include passwords::mysql::phabricator

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
        $rddmarc_pass        = $passwords::rddmarc::db_password
        $phab_admin_pass     = $passwords::mysql::phabricator::admin_pass
        $phab_app_pass       = $passwords::mysql::phabricator::app_pass
        $phab_bz_pass        = $passwords::mysql::phabricator::bz_pass
        $phab_rt_pass        = $passwords::mysql::phabricator::rt_pass
        $phab_manifest_pass  = $passwords::mysql::phabricator::manifest_pass
        $phab_metrics_pass   = $passwords::mysql::phabricator::metrics_pass

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

# mysql groups for monitoring
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
    $socket = '/run/mysqld/mysqld.sock',
    ) {

    include role::prometheus::node_exporter
    class { 'role::prometheus::mysqld_exporter':
        socket => $socket,
    }
}

# lint:endignore
