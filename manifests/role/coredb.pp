## for describing replication topology
## hosts must be added here in addition to site.pp
class role::coredb::config {
    $topology = {
        's1' => {
            'hosts' => { 'eqiad' => [ 'db1050', 'db1051', 'db1052', 'db1055', 'db1061', 'db1062', 'db1065', 'db1066', 'db1070', 'db1071' ] },
            'primary_site' => $::mw_primary,
            'masters'      => { 'eqiad' => 'db1052' },
            'snapshot'     => [ 'db1050' ],
            'no_master'    => [ 'db1050', 'db1055' ]
        },
        's2' => {
            'hosts' => { 'eqiad' => [ 'db1009', 'db1018', 'db1024', 'db1036', 'db1060', 'db1063', 'db1067' ] },
            'primary_site' => $::mw_primary,
            'masters'      => { 'eqiad' => 'db1024' },
            'snapshot'     => [ 'db1018' ],
            'no_master'    => [ 'db1018' ]
        },
        's3' => {
            'hosts' => { 'eqiad' => [ 'db1019', 'db1027', 'db1035', 'db1038' ] },
            'primary_site' => $::mw_primary,
            'masters'      => { 'eqiad' => 'db1038' },
            'snapshot'     => [ 'db1035' ],
            'no_master'    => [ 'db1035' ]
        },
        's4' => {
            'hosts' => { 'eqiad' => [ 'db1040', 'db1042', 'db1056', 'db1059', 'db1064', 'db1068' ] },
            'primary_site' => $::mw_primary,
            'masters'      => { 'eqiad' => 'db1040' },
            'snapshot'     => [ 'db1042' ],
            'no_master'    => [ 'db1042' ]
        },
        's5' => {
            'hosts' => { 'eqiad' => [ 'db1021', 'db1026', 'db1037', 'db1045', 'db1049', 'db1058' ] },
            'primary_site' => $::mw_primary,
            'masters'      => { 'eqiad' => 'db1058' },
            'snapshot'     => [ ],
            'no_master'    => [ 'db1026' ]
        },
        's6' => {
            'hosts' => { 'eqiad' => [ 'db1010', 'db1015', 'db1022', 'db1023', 'db1030' ] },
            'primary_site' => $::mw_primary,
            'masters'      => { 'eqiad' => 'db1023' },
            'snapshot'     => [ 'db1022' ],
            'no_master'    => [ 'db1022', 'db1010' ]
        },
        's7' => {
            'hosts' => { 'eqiad' => [ 'db1028', 'db1033', 'db1034', 'db1039', 'db1041' ] },
            'primary_site' => $::mw_primary,
            'masters'      => { 'eqiad' => 'db1033' },
            'snapshot'     => [ ],
            'no_master'    => [ 'db1041' ]
        },
        'x1' => {
            'hosts' => {
                'eqiad' => [ 'db1029', 'db1031' ] },
            'primary_site' => $::mw_primary,
            'masters'      => { 'eqiad' => 'db1029' },
            'snapshot'     => [ 'db1031' ],
            'no_master'    => []
        },
        'm1' => {
            'hosts' => {
                'eqiad' => ['db1001', 'db1016'] },
            'primary_site' => $::mw_primary,
            'masters'      => { 'eqiad' => 'db1001' },
            'snapshot'     => ['db1016' ],
            'no_master'    => []
        },
        # m2 role::mariadb::misc
        # m3 role::mariadb::misc::phabricator
        'es1' => {
            'hosts' => { 'eqiad' => [ 'es1001', 'es1002', 'es1003', 'es1004' ] },
            'primary_site' => false,
            'masters'      => {},
            'snapshot'     => [],
            'no_master'    => []
        },
        'es2' => {
            'hosts' => { 'eqiad' => [ 'es1005', 'es1006', 'es1007' ] },
            'primary_site' => $::mw_primary,
            'masters'      => { 'eqiad' => 'es1006' },
            'snapshot'     => [],
            'no_master'    => []
        },
        'es3' => {
            'hosts' => { 'eqiad' => [ 'es1008', 'es1009', 'es1010' ] },
            'primary_site' => $::mw_primary,
            'masters'      => { 'eqiad' => 'es1009' },
            'snapshot'     => [],
            'no_master'    => []
        },
    }
}

class role::coredb::s1( $mariadb = false, $innodb_file_per_table = false ) {
    class { 'role::coredb::common':
        shard                 => 's1',
        slow_query_digest     => false,
        mariadb               => $mariadb,
        innodb_file_per_table => $innodb_file_per_table,
        innodb_log_file_size  => '2000M'
    }
}

class role::coredb::s2( $mariadb = false, $innodb_file_per_table = false ) {
    class { 'role::coredb::common':
        shard                 => 's2',
        slow_query_digest     => false,
        mariadb               => $mariadb,
        innodb_file_per_table => $innodb_file_per_table,
        innodb_log_file_size  => '2000M'
    }
}

class role::coredb::s3( $mariadb = false, $innodb_file_per_table = false ) {
    class { 'role::coredb::common':
        shard                 => 's3',
        slow_query_digest     => false,
        mariadb               => $mariadb,
        innodb_file_per_table => $innodb_file_per_table,
    }
}

class role::coredb::s4( $mariadb = false, $innodb_file_per_table = false ) {
    class { 'role::coredb::common':
        shard                 => 's4',
        slow_query_digest     => false,
        mariadb               => $mariadb,
        innodb_file_per_table => $innodb_file_per_table,
        innodb_log_file_size  => '2000M'
    }
}

class role::coredb::s5( $mariadb = false, $innodb_file_per_table = false ) {
    class { 'role::coredb::common':
        shard                 => 's5',
        slow_query_digest     => false,
        mariadb               => $mariadb,
        innodb_file_per_table => $innodb_file_per_table,
        innodb_log_file_size  => '1000M'
    }
}

class role::coredb::s6( $mariadb = false, $innodb_file_per_table = false ) {
    class { 'role::coredb::common':
        shard                 => 's6',
        slow_query_digest     => false,
        mariadb               => $mariadb,
        innodb_file_per_table => $innodb_file_per_table,
    }
}

class role::coredb::s7( $mariadb = false, $innodb_file_per_table = false ) {
    class { 'role::coredb::common':
        shard                 => 's7',
        slow_query_digest     => false,
        mariadb               => $mariadb,
        innodb_file_per_table => $innodb_file_per_table,
    }
}

class role::coredb::x1( $mariadb = true ) {
    class { 'role::coredb::common':
        shard                 => 'x1',
        mariadb               => $mariadb,
        innodb_file_per_table => true,
    }
}

class role::coredb::m1( $mariadb = false ) {
    class { 'role::coredb::common':
        shard                 => 'm1',
        mariadb               => $mariadb,
        innodb_file_per_table => true,
    }
}

# m2 role::mariadb::misc
# m3 role::mariadb::misc::phabricator

class role::coredb::es1( $mariadb = false ) {
    class { 'role::coredb::common':
        shard                 => 'es1',
        mariadb               => $mariadb,
        innodb_file_per_table => true,
        slow_query_digest     => false,
        heartbeat_enabled     => false,
    }
}

class role::coredb::es2( $mariadb = false ) {
    class { 'role::coredb::common':
        shard                 => 'es2',
        mariadb               => $mariadb,
        innodb_file_per_table => true,
        slow_query_digest     => false,
    }
}

class role::coredb::es3( $mariadb = false ) {
    class { 'role::coredb::common':
        shard                 => 'es3',
        mariadb               => $mariadb,
        innodb_file_per_table => true,
        slow_query_digest     => false,
    }
}

class role::coredb::researchdb(
    $shard='s1',
    $innodb_log_file_size = '2000M',
    $mariadb = false,
    $innodb_file_per_table = false
){
    class { 'role::coredb::common':
        shard                     => $shard,
        mariadb                   => $mariadb,
        innodb_log_file_size      => $innodb_log_file_size,
        read_only                 => false,
        disable_binlogs           => true,
        long_timeouts             => true,
        enable_unsafe_locks       => true,
        large_slave_trans_retries => true,
        innodb_file_per_table     => $innodb_file_per_table,
        # send researchdb icinga alerts to admins
        # and analytics icinga contact groups.
        contact_group             => 'admins,analytics',
    }
}

class role::coredb::fundraising( $mariadb = true ) {
    class { 'role::coredb::common':
        shard                 => 'fundraisingdb',
        logical_cluster       => 'fundraising',
        mariadb               => $mariadb,
        innodb_file_per_table => true,
        slow_query_digest     => false,
        heartbeat_enabled     => false
    }
}

class role::coredb::common(
    $shard,
    $logical_cluster = 'mysql',
    $mariadb,
    $read_only = true,
    $skip_name_resolve = true,
    $mysql_myisam = false,
    $mysql_max_allowed_packet = '16M',
    $disable_binlogs = false,
    $innodb_log_file_size = '500M',
    $innodb_file_per_table = false,
    $long_timeouts = false,
    $enable_unsafe_locks = false,
    $large_slave_trans_retries = false,
    $slow_query_digest = true,
    $heartbeat_enabled = true,
    $contact_group = 'admins',
    ) inherits role::coredb::config {

    $primary_site = $topology[$shard]['primary_site']
    $masters = $topology[$shard]['masters']
    $snapshots = $topology[$shard]['snapshot']

    system::role { 'dbcore': description => "Shard ${shard} Core Database server" }

    include standard,
        mha::node,
        cpufrequtils
    class { 'mysql_wmf::coredb::ganglia' : mariadb => $mariadb; }

    if $masters[$::site] == $::hostname
        and ( $primary_site == $::site or $primary_site == 'both' ){
        class { 'coredb_mysql':
            shard                     => $shard,
            mariadb                   => $mariadb,
            read_only                 => false,
            skip_name_resolve         => $skip_name_resolve,
            mysql_myisam              => $mysql_myisam,
            mysql_max_allowed_packet  => $mysql_max_allowed_packet,
            disable_binlogs           => $disable_binlogs,
            innodb_log_file_size      => $innodb_log_file_size,
            innodb_file_per_table     => $innodb_file_per_table,
            long_timeouts             => $long_timeouts,
            enable_unsafe_locks       => $enable_unsafe_locks,
            large_slave_trans_retries => $large_slave_trans_retries,
            slow_query_digest         => $slow_query_digest,
            heartbeat_enabled         => $heartbeat_enabled,
        }

        class { 'mysql_wmf::coredb::monitoring':
            crit          => true,
            contact_group => $contact_group,
        }

    }
    else {
        class { 'coredb_mysql':
            shard                     => $shard,
            mariadb                   => $mariadb,
            read_only                 => $read_only,
            skip_name_resolve         => $skip_name_resolve,
            mysql_myisam              => $mysql_myisam,
            mysql_max_allowed_packet  => $mysql_max_allowed_packet,
            disable_binlogs           => $disable_binlogs,
            innodb_log_file_size      => $innodb_log_file_size,
            innodb_file_per_table     => $innodb_file_per_table,
            long_timeouts             => $long_timeouts,
            enable_unsafe_locks       => $enable_unsafe_locks,
            large_slave_trans_retries => $large_slave_trans_retries,
            slow_query_digest         => $slow_query_digest,
            heartbeat_enabled         => $heartbeat_enabled,
        }

        if $primary_site {
            class { 'mysql_wmf::coredb::monitoring': crit => false }
        } else {
            class { 'mysql_wmf::coredb::monitoring': crit => false, no_slave => true }
        }
    }

    if $::hostname in $snapshots {
        include coredb_mysql::snapshot
    }
}
