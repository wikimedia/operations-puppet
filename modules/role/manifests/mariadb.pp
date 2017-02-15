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

class role::mariadb::ferm {

    # Common ferm class for database access. The actual databases are listening on 3306
    # and are initially limited to the internal network. More specialised sub classes
    # can grant additional access to other hosts

    ferm::service{ 'mariadb_internal':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '$INTERNAL',
    }

    # for DBA purposes
    ferm::rule { 'mariadb_dba':
        rule => 'saddr @resolve((db1011.eqiad.wmnet)) proto tcp dport (3307) ACCEPT;',
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
class role::mariadb::groups(
    $mysql_group,
    $mysql_role,
    $mysql_shard = '',
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

    # hacky workaround until we get rid of precise hosts
    # T123525
    if os_version('debian >= jessie || ubuntu >= trusty') {
        include role::prometheus::node_exporter
        include role::prometheus::mysqld_exporter
    }
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
        true  => 0,
        false => 1,
    }

    $mysql_role = $master ? {
        true  => 'master',
        false => 'slave',
    }

    include ::standard
    include role::mariadb::monitor
    include passwords::misc::scripts
    include role::mariadb::ferm
    class { 'role::mariadb::groups':
        mysql_group => 'misc',
        mysql_shard => $shard,
        mysql_role  => $mysql_role,
    }

    include mariadb::packages_wmf
    include mariadb::service

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/misc.my.cnf.erb',
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        ssl       => 'puppet-cert',
        read_only => $read_only,
    }

    class { 'role::mariadb::grants::production':
        shard    => $shard,
        prompt   => "MISC ${shard}",
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $master,
    }
}

# Phab pretty much requires its own sandbox
# strict sql_mode -- nice! but other services moan
# admin tool that needs non-trivial permissions
class role::mariadb::misc::phabricator(
    $shard     = 'm3',
    $master    = false,
    $snapshot  = false,
    $ssl       = 'puppet-cert',
    $p_s       = 'on',
    $mariadb10 = true,
    ) {

    system::role { 'role::mariadb::misc':
        description => "Misc Services Database ${shard} (phabricator)",
    }

    include ::standard
    include mariadb::packages_wmf
    include mariadb::service

    $mysql_role = $master ? {
        true  => 'master',
        false => 'slave',
    }

    include role::mariadb::monitor
    include passwords::misc::scripts
    include role::mariadb::ferm

    class { 'role::mariadb::groups':
        mysql_group => 'misc',
        mysql_shard => $shard,
        mysql_role  => $mysql_role,
    }

    $read_only = $master ? {
        true  => 0,
        false => 1,
    }

    $stopwords_database = 'phabricator_search'

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/phabricator.my.cnf.erb',
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        sql_mode  => 'STRICT_ALL_TABLES',
        read_only => $read_only,
        ssl       => $ssl,
        p_s       => $p_s,
    }

    file { '/etc/mysql/phabricator-stopwords.txt':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('mariadb/phabricator-stopwords.txt.erb'),
    }

    file { '/etc/mysql/phabricator-stopwords-update.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('mariadb/phabricator-stopwords-update.sql.erb'),
    }

    file { '/etc/mysql/phabricator-init.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('mariadb/phabricator-init.sql.erb'),
    }

    class { 'role::mariadb::grants::production':
        shard    => $shard,
        prompt   => "MISC ${shard}",
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $master,
    }

    unless $master {
        mariadb::monitor_replication { [ $shard ]:
            is_critical   => false,
            contact_group => 'admins',
            multisource   => false,
        }
    }
}

# Eventlogging needs to be sandboxed by itself. It can consume resources
# unpredictably, especially during backfilling. It also benefits greatly
# from a setup tuned for TokuDB.
class role::mariadb::misc::eventlogging(
    $shard  = 'm4',
    $master = false,
    ) {

    system::role { 'role::mariadb::misc':
        description => 'Eventlogging Database',
    }

    $mysql_role = $master ? {
        true  => 'master',
        false => 'slave',
    }

    include ::standard
    include role::mariadb::monitor::dba
    include passwords::misc::scripts
    include role::mariadb::ferm

    class {'role::mariadb::groups':
        mysql_group => 'misc',
        mysql_shard => $shard,
        mysql_role  => $mysql_role,
    }

    include mariadb::packages_wmf
    include mariadb::service

    $read_only = $master ? {
        true  => 0,
        false => 1,
    }

    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/eventlogging.my.cnf.erb',
        datadir       => '/srv/sqldata',
        tmpdir        => '/srv/tmp',
        read_only     => $read_only,
        ssl           => 'puppet-cert',
        p_s           => 'off',
        binlog_format => 'MIXED',
    }

    class { 'role::mariadb::grants::production':
        shard    => $shard,
        prompt   => "EVENTLOGGING ${shard}",
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $master,
    }
}

# Beta Cluster Master
# Should add separate role for slaves
#
# filtertags: labs-project-deployment-prep
class role::mariadb::beta {

    system::role { 'role::mariadb::beta':
        description => 'beta cluster database server',
    }

    include ::standard
    include mariadb::packages_wmf
    include passwords::misc::scripts

    # This is essentially the same volume created by role::labs::lvm::srv but
    # ensures it will be created before mariadb is installed and leaves some
    # LVM extents free for a possible second volume for the tmpdir.
    # (see T117446)
    labs_lvm::volume { 'second-local-disk':
        mountat => '/srv',
        size    => '80%FREE',
        before  => Class['mariadb::packages_wmf'],
    }

    class { 'mariadb::config':
        config  => 'role/mariadb/mysqld_config/beta.my.cnf.erb',
    }

    class { 'mariadb::service':
        ensure  => 'running',
        manage  => true,
        enable  => true,
        require => Class['mariadb::config'],
    }

    $password = $passwords::misc::scripts::mysql_beta_root_pass
    $prompt = 'BETA'
    file { '/root/.my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('mariadb/root.my.cnf.erb'),
    }
}

# tendril.wikimedia.org db
class role::mariadb::tendril {

    system::role { 'role::mariadb::tendril':
        description => 'tendril database server',
    }

    include mariadb::packages_wmf
    include mariadb::service

    include ::standard
    include role::mariadb::monitor::dba
    include passwords::misc::scripts
    include role::mariadb::ferm

    class {'role::mariadb::groups':
        mysql_group => 'tendril',
        mysql_role  => 'standalone',
    }

    class { 'mariadb::config':
        config  => 'role/mariadb/mysqld_config/tendril.my.cnf.erb',
        datadir => '/srv/sqldata',
        tmpdir  => '/srv/tmp',
        ssl     => 'puppet-cert',
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
        source => 'puppet:///files/mariadb/eventlogging_sync.sh',
    }
    file { '/etc/init.d/eventlogging_sync':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///files/mariadb/eventlogging_sync.init',
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

class role::mariadb::core(
    $shard,
    $ssl           = 'puppet-cert',
    $binlog_format = 'MIXED',
    $master        = false,
    ) {

    system::role { 'role::mariadb::core':
        description => "Core DB Server ${shard}",
    }

    include ::standard
    include ::base::firewall
    include role::mariadb::monitor
    include passwords::misc::scripts
    include role::mariadb::ferm

    if ($shard == 'es1') {
        $mysql_role = 'standalone'
    } elsif $master == true {
        $mysql_role = 'master'
    } else {
        $mysql_role = 'slave'
    }

    class { 'role::mariadb::groups':
        mysql_group => 'core',
        mysql_shard => $shard,
        mysql_role  => $mysql_role,
    }


    include mariadb::packages_wmf
    include mariadb::service

    # Semi-sync replication
    # off: for non-primary datacenter and read-only shard(s)
    # slave: for slaves in the primary datacenter
    # master: for masters in the primary datacenter
    if ($::mw_primary != $::site or $shard == 'es1') {
        $semi_sync = 'off'
    } elsif ($master) {
        $semi_sync = 'master'
    } else {
        $semi_sync = 'slave'
    }

    # Read only forced on also for the masters of the primary datacenter
    class { 'mariadb::config':
        config           => 'role/mariadb/mysqld_config/production.my.cnf.erb',
        datadir          => '/srv/sqldata',
        tmpdir           => '/srv/tmp',
        p_s              => 'on',
        ssl              => $ssl,
        binlog_format    => $binlog_format,
        semi_sync        => $semi_sync,
        replication_role => $mysql_role,
    }

    include role::mariadb::grants::core
    class { 'role::mariadb::grants::production':
        shard    => 'core',
        prompt   => "PRODUCTION ${shard}",
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    $replication_is_critical = ($::mw_primary == $::site)
    $contact_group = $replication_is_critical ? {
        true  => 'dba',
        false => 'admins',
    }

    mariadb::monitor_replication { [ $shard ]:
        multisource   => false,
        is_critical   => $replication_is_critical,
        contact_group => $contact_group,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $master,
    }
}

class role::mariadb::sanitarium {

    system::role { 'role::mariadb::sanitarium':
        description => 'Sanitarium DB Server',
    }

    include ::standard
    include passwords::misc::scripts
    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
    }

    include mariadb::packages_wmf
    # do not add mariadb::service, multi-instance has its own way

    include role::labs::db::common
    include role::labs::db::check_private_data

    class { 'mariadb::config':
        config   => 'role/mariadb/mysqld_config/sanitarium.my.cnf.erb',
    }

    ferm::service { 'mysqld_sanitarium':
        proto  => 'tcp',
        port   => '3311:3317',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'gmond_udp':
        proto  => 'udp',
        port   => '8649',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'gmond_tcp':
        proto  => 'tcp',
        port   => '8649',
        srange => '$PRODUCTION_NETWORKS',
    }

    # One instance per shard using mysqld_multi.
    # This allows us to send separate replication channels downstream.
    $folders = [
        '/srv/sqldata.s1',
        '/srv/sqldata.s2',
        '/srv/sqldata.s3',
        '/srv/sqldata.s4',
        '/srv/sqldata.s5',
        '/srv/sqldata.s6',
        '/srv/sqldata.s7',
        '/srv/tmp.s1',
        '/srv/tmp.s2',
        '/srv/tmp.s3',
        '/srv/tmp.s4',
        '/srv/tmp.s5',
        '/srv/tmp.s6',
        '/srv/tmp.s7',
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
        content => template('role/mariadb/sanitarium.sysvinit.erb'),
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
        contact_group => 'admins',
    }
}

class role::mariadb::sanitarium2 {
    system::role { 'role::mariadb::sanitarium':
        description => 'Sanitarium DB Server',
    }

    include ::standard
    include passwords::misc::scripts
    include ::base::firewall
    include role::mariadb::ferm
    include role::labs::db::common
    include role::labs::db::check_private_data

    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
    }

    class {'mariadb::packages_wmf':
        package => 'wmf-mariadb101',
    }

    class { 'mariadb::config':
        config => 'role/mariadb/mysqld_config/sanitarium2.my.cnf.erb',
        ssl    => 'puppet-cert',
    }

    class {'mariadb::service':
        package => 'wmf-mariadb101',
    }

    class { 'mariadb::monitor_disk':
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        contact_group => 'admins',
    }

    file { '/usr/local/sbin/redact_sanitarium.sh':
        ensure  => file,
        source  => 'puppet:///modules/role/mariadb/redact_sanitarium.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        require => File['/etc/mysql/filtered_tables.txt'],
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
        config  => 'mariadb/labs.my.cnf.erb',
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

# wikitech instance (silver)
class role::mariadb::wikitech {

    system::role { 'role::mariadb::wikitech':
        description => 'Wikitech Database',
    }

    include ::standard
    include role::mariadb::grants::wikitech
    include role::mariadb::monitor
    include passwords::misc::scripts
    class { 'role::mariadb::groups':
        mysql_group => 'wikitech',
        mysql_role  => 'standalone',
    }

    include mariadb::packages_wmf
    include mariadb::service

    class { 'mariadb::config':
        config  => 'role/mariadb/mysqld_config/wikitech.my.cnf.erb',
        datadir => '/srv/sqldata',
        tmpdir  => '/srv/tmp',
    }

    # mysql monitoring access from tendril (db1011)
    ferm::rule { 'mysql_tendril':
        rule => 'saddr 10.64.0.15 proto tcp dport (3306) ACCEPT;',
    }

    # mysql from deployment master servers and terbium (T98682, T109736)
    ferm::service { 'mysql_deployment_terbium':
        proto  => 'tcp',
        port   => '3306',
        srange => '@resolve((tin.eqiad.wmnet mira.codfw.wmnet terbium.eqiad.wmnet wasat.codfw.wmnet))',
    }

    service { 'mariadb':
        ensure  => running,
        require => Class['mariadb::packages_wmf', 'mariadb::config'],
    }
}

class role::mariadb::proxy(
    $shard
    ) {

    system::role { 'role::mariadb::proxy':
        description => "DB Proxy ${shard}",
    }

    include ::standard

    package { [
        'mysql-client',
        'percona-toolkit',
    ]:
        ensure => present,
    }

    class { 'haproxy':
        template => 'mariadb/haproxy.cfg.erb',
    }
}

class role::mariadb::proxy::master(
    $shard,
    $primary_name,
    $primary_addr,
    $secondary_name,
    $secondary_addr,
    ) {

    include role::mariadb::ferm

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
        nrpe_command => '/usr/lib/nagios/plugins/check_haproxy --check=failover',
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

# parsercache (pc) specific configuration
class role::mariadb::parsercache(
    $shard,
    ) {

    include ::standard

    include role::mariadb::monitor
    include role::mariadb::ferm
    include passwords::misc::scripts
    class { 'role::mariadb::groups':
        mysql_group => 'parsercache',
        mysql_shard => $shard,
        mysql_role  => 'master',
    }

    system::role { 'role::mariadb::parsercache':
        description => "Parser Cache Database ${shard}",
    }

    include mariadb::packages_wmf
    include mariadb::service

    include role::mariadb::grants::core
    class { 'role::mariadb::grants::production':
        shard    => 'parsercache',
        prompt   => 'PARSERCACHE',
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    class { 'mariadb::config':
        config  => 'role/mariadb/mysqld_config/parsercache.my.cnf.erb',
        datadir => '/srv/sqldata-cache',
        tmpdir  => '/srv/tmp',
        ssl     => 'puppet-cert',
        p_s     => 'off',
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => true,
    }

    # mysql monitoring access from tendril (db1011)
    ferm::rule { 'mysql_tendril':
        rule => 'saddr 10.64.0.15 proto tcp dport (3306) ACCEPT;',
    }
}

# the contents of the next 2 classes should go over to
# db_maintenance module on puppet db-classes refactoring
class role::mariadb::maintenance {
    # TODO: check if both of these are still needed
    include mysql
    package { 'percona-toolkit':
        ensure => latest,
    }

    # place from which tendril-related cron jobs are run
    include passwords::tendril

    class { 'tendril::maintenance':
        tendril_host     => 'db1011.eqiad.wmnet',
        tendril_user     => 'watchdog',
        tendril_password => $passwords::tendril::db_pass,
    }
}
# lint:endignore
