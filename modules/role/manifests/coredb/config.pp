## DEPRECATED: to be deleted once all hosts have been migrated to the
## mariadb class; topology will be handled by orchestration
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
