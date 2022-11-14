class profile::lvs::configuration {

    $lvs_class_hosts = {
        'high-traffic1' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1017', 'lvs1020' ],
                'codfw' => [ 'lvs2007', 'lvs2010' ],
                'esams' => [ 'lvs3005', 'lvs3007' ],
                'ulsfo' => [ 'lvs4008', 'lvs4007' ],
                'eqsin' => [ 'lvs5001', 'lvs5003' ],
                'drmrs' => [ 'lvs6001', 'lvs6003' ],
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
                'codfw' => [ 'lvs2008', 'lvs2010' ],
                'esams' => [ 'lvs3006', 'lvs3007' ],
                'ulsfo' => [ 'lvs4006', 'lvs4007' ],
                'eqsin' => [ 'lvs5002', 'lvs5003' ],
                'drmrs' => [ 'lvs6002', 'lvs6003' ],
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
                'codfw' => [ 'lvs2009', 'lvs2010' ],
                'esams' => [ ],
                'ulsfo' => [ ],
                'eqsin' => [ ],
                'drmrs' => [ ],
                default => undef,
            },
            'labs' => $::labsproject ? {
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
        'lvs2007'      => 'high-traffic1',
        'lvs2008'      => 'high-traffic2',
        'lvs2009'      => 'low-traffic',
        'lvs2010'      => 'secondary',
        'lvs3005'      => 'high-traffic1',
        'lvs3006'      => 'high-traffic2',
        'lvs3007'      => 'secondary',
        'lvs4006'      => 'high-traffic2',
        'lvs4007'      => 'secondary',
        'lvs4008'      => 'high-traffic1',
        'lvs5001'      => 'high-traffic1',
        'lvs5002'      => 'high-traffic2',
        'lvs5003'      => 'secondary',
        'lvs6001'      => 'high-traffic1',
        'lvs6002'      => 'high-traffic2',
        'lvs6003'      => 'secondary',
    }
    $lvs_class = pick($lvs_classes[$::hostname], 'unknown')
}
