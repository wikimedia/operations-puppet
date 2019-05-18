# lvs/configuration.pp

class lvs::configuration {

    $lvs_class_hosts = {
        'high-traffic1' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1001', 'lvs1004', 'lvs1013' ],
                'codfw' => [ 'lvs2001', 'lvs2004' ],
                'esams' => [ 'lvs3001', 'lvs3003' ],
                'ulsfo' => [ 'lvs4005', 'lvs4007' ],
                'eqsin' => [ 'lvs5001', 'lvs5003' ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
        'high-traffic2' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1002', 'lvs1005', 'lvs1014' ],
                'codfw' => [ 'lvs2002', 'lvs2005' ],
                'esams' => [ 'lvs3002', 'lvs3004' ],
                'ulsfo' => [ 'lvs4006', 'lvs4007' ],
                'eqsin' => [ 'lvs5002', 'lvs5003' ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
        'low-traffic' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1016', 'lvs1006', 'lvs1015' ],
                'codfw' => [ 'lvs2003', 'lvs2006' ],
                'esams' => [ ],
                'ulsfo' => [ ],
                'eqsin' => [ ],
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
    $lvs_class = $::hostname ? {
        /^lvs[12]00[14]$/  => 'high-traffic1',
        /^lvs[12]00[25]$/  => 'high-traffic2',
        /^lvs200[36]$/     => 'low-traffic',
        'lvs1006'          => 'low-traffic',
        'lvs1016'          => 'low-traffic',
        /^lvs300[13]$/     => 'high-traffic1',
        /^lvs300[24]$/     => 'high-traffic2',
        'lvs4005'          => 'high-traffic1',
        'lvs4006'          => 'high-traffic2',
        'lvs4007'          => 'secondary',
        'lvs5001'          => 'high-traffic1',
        'lvs5002'          => 'high-traffic2',
        'lvs5003'          => 'secondary',
        default            => 'unknown',
    }

    # NOTE! This hash is referenced in many other manifests
    $service_ips = hiera('lvs::configuration::lvs_service_ips')
    $lvs_services = hiera('lvs::configuration::lvs_services')

}
