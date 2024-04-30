# SPDX-License-Identifier: Apache-2.0
class profile::lvs::configuration {

    $lvs_class_hosts = {
        'high-traffic1' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1017', 'lvs1020' ],
                'codfw' => [ 'lvs2011', 'lvs2014' ],
                'esams' => [ 'lvs3008', 'lvs3010' ],
                'ulsfo' => [ 'lvs4008', 'lvs4010' ],
                'eqsin' => [ 'lvs5004', 'lvs5006' ],
                'drmrs' => [ 'lvs6001', 'lvs6003' ],
                'magru' => [ 'lvs7001', 'lvs7003' ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
        'high-traffic2' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1018', 'lvs1020' ],
                'codfw' => [ 'lvs2012', 'lvs2014' ],
                'esams' => [ 'lvs3009', 'lvs3010' ],
                'ulsfo' => [ 'lvs4009', 'lvs4010' ],
                'eqsin' => [ 'lvs5005', 'lvs5006'],
                'drmrs' => [ 'lvs6002', 'lvs6003' ],
                'magru' => [ 'lvs7002', 'lvs7003' ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
        'low-traffic' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1019', 'lvs1020' ],
                'codfw' => [ 'lvs2013', 'lvs2014' ],
                'esams' => [ ],
                'ulsfo' => [ ],
                'eqsin' => [ ],
                'drmrs' => [ ],
                default => undef,
            },
            'labs' => $::wmcs_project ? {
                'deployment-prep' => [ ],
                default => undef,
            },
            default => undef,
        },
    }

    # This is technically redundant information from $lvs_class_hosts, but
    # transforming one into the other in puppet is a huge PITA.
    # Warning: if you change this, look out for the usage of this data structure
    # in profile::mediawiki::maintenance::wikidata
    $lvs_classes =  {
        'lvs1017'      => 'high-traffic1',
        'lvs1018'      => 'high-traffic2',
        'lvs1019'      => 'low-traffic',
        'lvs1020'      => 'secondary',
        'lvs2011'      => 'high-traffic1',
        'lvs2012'      => 'high-traffic2',
        'lvs2013'      => 'low-traffic',
        'lvs2014'      => 'secondary',
        'lvs3008'      => 'high-traffic1',
        'lvs3009'      => 'high-traffic2',
        'lvs3010'      => 'secondary',
        'lvs4008'      => 'high-traffic1',
        'lvs4009'      => 'high-traffic2',
        'lvs4010'      => 'secondary',
        'lvs5004'      => 'high-traffic1',
        'lvs5005'      => 'high-traffic2',
        'lvs5006'      => 'secondary',
        'lvs6001'      => 'high-traffic1',
        'lvs6002'      => 'high-traffic2',
        'lvs6003'      => 'secondary',
        'lvs7001'      => 'high-traffic1',
        'lvs7002'      => 'high-traffic2',
        'lvs7003'      => 'secondary',
    }
    $lvs_class = pick($lvs_classes[$::hostname], 'unknown')
}
