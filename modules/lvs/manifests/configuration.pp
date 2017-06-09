# lvs/configuration.pp

class lvs::configuration {

    $lvs_class_hosts = {
        'high-traffic1' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1001', 'lvs1004', 'lvs1007', 'lvs1010' ],
                'codfw' => [ 'lvs2001', 'lvs2004' ],
                'esams' => [ 'lvs3001', 'lvs3003' ],
                'ulsfo' => [ 'lvs4001', 'lvs4003', 'lvs4005', 'lvs4007' ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
        'high-traffic2' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1002', 'lvs1005', 'lvs1008', 'lvs1010' ],
                'codfw' => [ 'lvs2002', 'lvs2005' ],
                'esams' => [ 'lvs3002', 'lvs3004' ],
                'ulsfo' => [ 'lvs4002', 'lvs4004', 'lvs4006', 'lvs4007' ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
        'low-traffic' => $::realm ? {
            'production' => $::site ? {
                'eqiad' => [ 'lvs1003', 'lvs1006', 'lvs1009', 'lvs1010' ],
                'codfw' => [ 'lvs2003', 'lvs2006' ],
                'esams' => [ ],
                'ulsfo' => [ ],
                default => undef,
            },
            'labs' => $::site ? {
                default => undef,
            },
            default => undef,
        },
    }

    # NOTE: This is for informational purposes only. The actual configuration
    # that decides primary/secondary is done at the BGP level on the routers.
    $lvs_grain = $::hostname ? {
        /^lvs100[123789]$/  => 'primary',
        /^lvs200[123]$/     => 'primary',
        /^lvs[34]00[1256]$/ => 'primary',
        default => 'secondary'
    }

    # This is technically redundant information from $lvs_class_hosts, but
    # transforming one into the other in puppet is a huge PITA.
    $lvs_grain_class = $::hostname ? {
        'lvs1007'          => 'high-traffic1',
        'lvs1008'          => 'high-traffic2',
        'lvs1009'          => 'low-traffic',
        'lvs1010'          => 'secondary',
        /^lvs[12]00[14]$/  => 'high-traffic1',
        /^lvs[12]00[25]$/  => 'high-traffic2',
        /^lvs[12]00[36]$/  => 'low-traffic',
        /^lvs[34]00[135]$/ => 'high-traffic1',
        /^lvs[34]00[246]$/ => 'high-traffic2',
        /^lvs[34]007$/     => 'secondary',
        default            => 'unknown',
    }

    # NOTE! This hash is referenced in many other manifests
    $service_ips = hiera('lvs::configuration::lvs_service_ips')
    $lvs_services = hiera('lvs::configuration::lvs_services')

}
