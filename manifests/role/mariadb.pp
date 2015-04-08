# Generic Server
class role::mariadb {

    system::role { 'role::mariadb':
        description => 'database server',
    }

    include standard
    include mariadb
}

# root, repl, nagios, tendril
class role::mariadb::grants(
    $shard = false,
    ) {

    include passwords::misc::scripts
    include passwords::tendril

    $root_pass    = $passwords::misc::scripts::mysql_root_pass
    $repl_pass    = $passwords::misc::scripts::mysql_repl_pass
    $nagios_pass  = $passwords::misc::scripts::nagios_sql_pass
    $tendril_user = $passwords::tendril::db_user
    $tendril_pass = $passwords::tendril::db_pass

    file { '/etc/mysql/production-grants.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('mariadb/production-grants.sql.erb'),
    }

    if $shard {

        file { "/etc/mysql/production-grants-shard.sql":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            content => template("mariadb/production-grants-${shard}.sql.erb"),
        }
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

# miscellaneous services clusters
class role::mariadb::misc(
    $shard  = 'm1',
    $master = false,
    ) {

    system::role { 'role::mariadb::misc':
        description => "Misc Services Database ${shard}",
    }

    $read_only = $master ? {
        true  => 'off',
        false => 'on',
    }

    include standard
    include role::mariadb::monitor
    include passwords::misc::scripts

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    class { 'mariadb::config':
        prompt    => "MISC ${shard}",
        config    => 'mariadb/misc.my.cnf.erb',
        password  => $passwords::misc::scripts::mysql_root_pass,
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        read_only => $read_only,
    }

    class { 'role::mariadb::grants':
        shard => $shard,
    }
}

# Phab pretty much requires its own sandbox
# strict sql_mode -- nice! but other services moan
# admin tool that needs non-trivial permissions
class role::mariadb::misc::phabricator(
    $shard    = 'm3',
    $master   = false,
    $snapshot = false,
    ) {

    system::role { 'role::mariadb::misc':
        description => "Misc Services Database ${shard} (phabricator)",
    }

    include standard
    include mariadb::packages_wmf
    include role::mariadb::monitor
    include passwords::misc::scripts

    $read_only = $master ? {
        true  => 'off',
        false => 'on',
    }

    class { 'mariadb::config':
        prompt    => "MISC ${shard}",
        config    => 'mariadb/phabricator.my.cnf.erb',
        password  => $passwords::misc::scripts::mysql_root_pass,
        datadir   => '/a/sqldata',
        tmpdir    => '/a/tmp',
        sql_mode  => 'STRICT_ALL_TABLES',
        read_only => $read_only,
    }

    file { '/etc/mysql/phabricator-init.sql':
        ensure  => present,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0644',
        content => template('mariadb/phabricator-init.sql.erb'),
    }

    file { '/etc/mysql/phabricator-stopwords.txt':
        ensure  => present,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0644',
        content => template('mariadb/phabricator-stopwords.txt.erb'),
    }

    class { 'role::mariadb::grants':
        shard => $shard,
    }

    if $snapshot {
        include coredb_mysql::snapshot
    }

    unless $master {
        mariadb::monitor_replication { [ $shard ]:
            multisource => false,
        }
    }
}

# Eventlogging needs tobe sandboxed by itself. It can consume resources
# unpredictably, especially during backfilling. It also benefits greatly
# from a setup tuned for TokuDB.
class role::mariadb::misc::eventlogging(
    $shard  = 'm4',
    $master = false,
    ) {

    system::role { 'role::mariadb::misc':
        description => "Eventlogging Database",
    }

    include standard
    include role::mariadb::monitor::dba
    include passwords::misc::scripts

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    $read_only = $master ? {
        true  => 'off',
        false => 'on',
    }

    class { 'mariadb::config':
        prompt    => "EVENTLOGGING ${shard}",
        config    => 'mariadb/eventlogging.my.cnf.erb',
        password  => $passwords::misc::scripts::mysql_root_pass,
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        read_only => $read_only,
    }

    class { 'role::mariadb::grants':
        shard => $shard,
    }
}

# Beta Cluster Master
# Should add separate role for slaves
class role::mariadb::beta {

    system::role { 'role::mariadb::beta':
        description => 'beta cluster database server',
    }

    include standard
    include mariadb::packages
    include passwords::misc::scripts

    class { 'mariadb::config':
        prompt   => 'BETA',
        config   => 'mariadb/beta.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_beta_root_pass,
        datadir  => '/mnt/sqldata',
        tmpdir   => '/mnt/tmp',
    }
}

# tendril.wikimedia.org db
class role::mariadb::tendril {

    system::role { 'role::mariadb::tendril':
        description => 'tendril database server',
    }

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    include standard
    include role::mariadb::grants
    include role::mariadb::monitor::dba
    include passwords::misc::scripts

    class { 'mariadb::config':
        prompt   => 'TENDRIL',
        config   => 'mariadb/tendril.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_root_pass,
        datadir  => '/a/sqldata',
        tmpdir   => '/a/tmp',
    }
}

# MariaDB 10 slaves replicating all shards
class role::mariadb::dbstore(
    $lag_warn = 300,
    $lag_crit = 600,
    $warn_stopped = true,
    ) {

    system::role { 'role::mariadb::dbstore':
        description => 'Delayed Slave',
    }

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    include standard
    include role::mariadb::grants
    include role::mariadb::monitor::dba
    include passwords::misc::scripts

    class { 'mariadb::config':
        prompt   => 'DBSTORE',
        config   => 'mariadb/dbstore.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_root_pass,
        datadir  => '/srv/sqldata',
        tmpdir   => '/srv/tmp',
    }

    mariadb::monitor_replication { ['s1','s2','s3','s4','s5','s6','s7','m2','m3']:
        lag_warn     => $lag_warn,
        lag_crit     => $lag_crit,
        warn_stopped => $warn_stopped,
    }
}

# MariaDB 10 Analytics all-shards slave, with scratch space and TokuDB
class role::mariadb::analytics {

    system::role { 'role::mariadb::analytics':
        description => 'Analytics All-Shards Slave',
    }

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    include standard
    include role::mariadb::grants
    include role::mariadb::monitor
    include passwords::misc::scripts

    class { 'mariadb::config':
        prompt   => 'ANALYTICS',
        config   => 'mariadb/analytics.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_root_pass,
        datadir  => '/a/sqldata',
        tmpdir   => '/a/tmp',
    }

    mariadb::monitor_replication { ['s1','s2','m2']: }
}

class role::mariadb::backup {
    include role::backup::host
    include passwords::mysql::dump

    file { '/srv/backups':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0600', # implicitly 0700 for dirs
    }

    file { '/etc/mysql/conf.d/dumps.cnf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => "[client]\nuser=${passwords::mysql::dump::user}\npassword=${passwords::mysql::dump::pass}\n",
    }

    backup::mysqlset {'dbstore':
        xtrabackup       => false,
        per_db           => true,
        innodb_only      => true,
        local_dump_dir   => '/srv/backups',
        password_file    => '/etc/mysql/conf.d/dumps.cnf',
        method           => 'predump',
        mysql_binary     => '/usr/local/bin/mysql',
        mysqldump_binary => '/usr/local/bin/mysqldump',
        jobdefaults      => "Weekly-${role::backup::host::day}-${role::backup::host::pool}",
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
        content => template('mariadb/production-grants-core.sql.erb'),
    }
}

class role::mariadb::core(
    $shard
    ) {

    system::role { "role::mariadb::core":
        description => "Core DB Server ${shard}",
    }

    include standard
    include role::mariadb::grants
    include role::mariadb::grants::core
    include role::mariadb::monitor
    include passwords::misc::scripts

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    class { 'mariadb::config':
        prompt   => "PRODUCTION ${shard}",
        config   => 'mariadb/production.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_root_pass,
        datadir  => '/srv/sqldata',
        tmpdir   => '/srv/tmp',
    }

    mariadb::monitor_replication { [ $shard ]:
        multisource => false,
    }
}

class role::mariadb::sanitarium {

    system::role { "role::mariadb::sanitarium":
        description => "Sanitarium DB Server",
    }

    include standard
    include role::mariadb::grants
    include passwords::misc::scripts

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    class { 'mariadb::config':
        prompt   => "SANITARIUM",
        config   => 'mariadb/sanitarium.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    # One instance per shard using mysqld_multi.
    # This allows us to send separate replication channels downstream.
    $folders = [
        "/srv/sqldata.s1",
        "/srv/sqldata.s2",
        "/srv/sqldata.s3",
        "/srv/sqldata.s4",
        "/srv/sqldata.s5",
        "/srv/sqldata.s6",
        "/srv/sqldata.s7",
        "/srv/tmp.s1",
        "/srv/tmp.s2",
        "/srv/tmp.s3",
        "/srv/tmp.s4",
        "/srv/tmp.s5",
        "/srv/tmp.s6",
        "/srv/tmp.s7",
    ]

    file { $folders:
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    # mysqld_multi wrapper
    file { '/etc/init.d/mariadb':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('mariadb/sanitarium.sysvinit.erb'),
    }
    file { '/etc/init.d/mysql':
        ensure => link,
        target => '/etc/init.d/mariadb',
    }

    class { 'mariadb::monitor_disk':
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        process_count => 7,
        contact_group => 'admins'
    }
}

# MariaDB 10 labsdb multiple-shards slave.
class role::mariadb::labs {

    system::role { 'role::mariadb::labs':
        description => 'Labs DB Slave',
    }

    include standard
    include role::mariadb::grants
    include role::mariadb::monitor
    include passwords::misc::scripts

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    class { 'mariadb::config':
        prompt   => "LABS",
        config   => 'mariadb/labs.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_root_pass,
        datadir  => '/srv/sqldata',
        tmpdir   => '/srv/tmp',
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
}

# wikitech instance (silver)
class role::mariadb::wikitech {

    system::role { 'role::mariadb::wikitech':
        description => "Wikitech Database",
    }

    include standard
    include role::mariadb::grants
    include role::mariadb::monitor
    include passwords::misc::scripts

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    class { 'mariadb::config':
        prompt   => "WIKITECH",
        config   => 'mariadb/wikitech.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_root_pass,
        datadir  => '/srv/sqldata',
        tmpdir   => '/srv/tmp',
    }

    # mysql monitoring access from tendril (db1011)
    ferm::rule { 'mysql_tendril':
        rule => "saddr 10.64.0.15 proto tcp dport (3306) ACCEPT;",
    }
}

class role::mariadb::proxy(
    $shard
    ) {

    system::role { 'role::mariadb::proxy':
        description => "DB Proxy ${shard}",
    }

    include standard

    package { [
        'mysql-client',
        'percona-toolkit',
    ]:
        ensure => present,
    }

    class { 'haproxy':
        template => "mariadb/haproxy.cfg.erb",
    }
}

class role::mariadb::proxy::master(
    $shard,
    $primary_name,
    $primary_addr,
    $secondary_name,
    $secondary_addr,
    ) {

    class { 'role::mariadb::proxy':
        shard => $shard,
    }

    file { '/etc/haproxy/conf.d/db-master.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mariadb/haproxy-master.cfg.erb'),
    }

    nrpe::monitor_service { 'haproxy_failover':
        description  => 'haproxy failover',
        nrpe_command => "/usr/lib/nagios/plugins/check_haproxy --check=failover",
    }
}

class role::mariadb::proxy::slaves(
    $shard,
    $servers,
    ) {

    class { 'role::mariadb::proxy':
        shard => $shard,
    }

    file { '/etc/haproxy/conf.d/db-slaves.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('mariadb/haproxy-slaves.cfg.erb'),
    }
}
