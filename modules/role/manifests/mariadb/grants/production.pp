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
        content => template('mariadb/production-grants.sql.erb'),
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

        file { '/etc/mysql/production-grants-shard.sql':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            content => template("mariadb/production-grants-${shard}.sql.erb"),
        }
    }
}

