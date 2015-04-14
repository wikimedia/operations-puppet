class role::cache::configuration {
    include lvs::configuration

    $has_ganglia = hiera('has_ganglia', true)

    $active_nodes = {
        'production' => {
            'text' => {
                'eqiad' => [
                    'cp1052.eqiad.wmnet',
                    'cp1053.eqiad.wmnet',
                    'cp1054.eqiad.wmnet',
                    'cp1055.eqiad.wmnet',
                    'cp1065.eqiad.wmnet',
                    'cp1066.eqiad.wmnet',
                    'cp1067.eqiad.wmnet',
                    'cp1068.eqiad.wmnet',
                ],
                'esams' => [
                    'cp3003.esams.wmnet',
                    'cp3004.esams.wmnet',
                    'cp3005.esams.wmnet',
                    'cp3006.esams.wmnet',
                    'cp3007.esams.wmnet',
                    'cp3008.esams.wmnet',
                    'cp3009.esams.wmnet',
                    'cp3010.esams.wmnet',
                    # T92306 'cp3011.esams.wmnet', # needs-jessie-install
                    'cp3012.esams.wmnet',
                    'cp3013.esams.wmnet',
                    'cp3014.esams.wmnet',
                    'cp3030.esams.wmnet',
                    'cp3031.esams.wmnet',
                    'cp3040.esams.wmnet',
                    'cp3041.esams.wmnet',
                ],
                'ulsfo' => [
                    'cp4008.ulsfo.wmnet',
                    'cp4009.ulsfo.wmnet',
                    'cp4010.ulsfo.wmnet',
                    'cp4016.ulsfo.wmnet',
                    'cp4017.ulsfo.wmnet',
                    'cp4018.ulsfo.wmnet',
                ]
            },
            'api' => {
                'eqiad' => [],
                'esams' => [],
                'ulsfo' => [],
            },
            'bits' => {
                'eqiad' => [
                    'cp1056.eqiad.wmnet',
                    'cp1057.eqiad.wmnet',
                    'cp1069.eqiad.wmnet',
                    'cp1070.eqiad.wmnet',
                ],
                'esams' => [
                    'cp3019.esams.wmnet',
                    'cp3020.esams.wmnet',
                    'cp3021.esams.wmnet',
                    'cp3022.esams.wmnet',
                ],
                'ulsfo' => [
                    'cp4001.ulsfo.wmnet',
                    'cp4002.ulsfo.wmnet',
                    'cp4003.ulsfo.wmnet',
                    'cp4004.ulsfo.wmnet',
                ],
            },
            'upload' => {
                'eqiad' => [
                    'cp1048.eqiad.wmnet',
                    'cp1049.eqiad.wmnet',
                    'cp1050.eqiad.wmnet',
                    'cp1051.eqiad.wmnet',
                    'cp1061.eqiad.wmnet',
                    'cp1062.eqiad.wmnet',
                    'cp1063.eqiad.wmnet',
                    'cp1064.eqiad.wmnet',
                    'cp1071.eqiad.wmnet',
                    'cp1072.eqiad.wmnet',
                    'cp1073.eqiad.wmnet',
                    'cp1074.eqiad.wmnet',
                ],
                'esams' => [
                    'cp3032.esams.wmnet',
                    'cp3033.esams.wmnet',
                    'cp3034.esams.wmnet',
                    'cp3035.esams.wmnet',
                    'cp3036.esams.wmnet',
                    'cp3037.esams.wmnet',
                    'cp3038.esams.wmnet',
                    'cp3039.esams.wmnet',
                    'cp3042.esams.wmnet',
                    'cp3043.esams.wmnet',
                    'cp3044.esams.wmnet',
                    'cp3045.esams.wmnet',
                    'cp3046.esams.wmnet',
                    'cp3047.esams.wmnet',
                    'cp3048.esams.wmnet',
                    'cp3049.esams.wmnet',
                ],
                'ulsfo' => [
                    'cp4005.ulsfo.wmnet',
                    'cp4006.ulsfo.wmnet',
                    'cp4007.ulsfo.wmnet',
                    'cp4013.ulsfo.wmnet',
                    'cp4014.ulsfo.wmnet',
                    'cp4015.ulsfo.wmnet',
                ],
            },
            'mobile' => {
                'eqiad' => [
                    'cp1046.eqiad.wmnet',
                    'cp1047.eqiad.wmnet',
                    'cp1059.eqiad.wmnet',
                    'cp1060.eqiad.wmnet',
                ],
                'esams' => [
                    'cp3015.esams.wmnet',
                    'cp3016.esams.wmnet',
                    'cp3017.esams.wmnet',
                    'cp3018.esams.wmnet',
                ],
                'ulsfo' => [
                    'cp4011.ulsfo.wmnet',
                    'cp4012.ulsfo.wmnet',
                    'cp4019.ulsfo.wmnet',
                    'cp4020.ulsfo.wmnet',
                ]
            },
            'parsoid' => {
                'eqiad' => [
                    'cp1045.eqiad.wmnet',
                    'cp1058.eqiad.wmnet',
                ],
                'esams' => [],
                'ulsfo' => []
            },
            'misc' => {
                'eqiad' => [
                    'cp1043.eqiad.wmnet',
                    'cp1044.eqiad.wmnet',
                ],
                'esams' => [],
                'ulsfo' => [],
            },
        },
        'labs' => {
            'api'    => {
                'eqiad' => '127.0.0.1',
            },
            'bits'   => {
                'eqiad' => '127.0.0.1',
            },
            'mobile' => {
                'eqiad' => '127.0.0.1',
            },
            'text'   => {
                'eqiad' => '127.0.0.1',
            },
            'upload' => {
                'eqiad' => '127.0.0.1',
            },
            'parsoid' => {
                'eqiad' => '127.0.0.1',
            },
        },
    }

    $decommissioned_nodes = {
        'text' => {
            'eqiad' => [

            ],
            'esams' => [
                'knsq1.knams.wikimedia.org',
                'knsq2.knams.wikimedia.org',
                'knsq3.knams.wikimedia.org',
                'knsq4.knams.wikimedia.org',
                'knsq5.knams.wikimedia.org',
                'knsq6.knams.wikimedia.org',
                'knsq7.knams.wikimedia.org',
                'knsq23.knams.wikimedia.org',
                'knsq24.knams.wikimedia.org',
                'knsq25.knams.wikimedia.org',
                'knsq26.knams.wikimedia.org',
                'knsq27.knams.wikimedia.org',
                'knsq28.knams.wikimedia.org',
                'knsq29.knams.wikimedia.org',
                'knsq30.knams.wikimedia.org',
            ]
        },
        'api' => {
            'eqiad' => [],
            'esams' => [],
        },
        'bits' => {
            'eqiad' => [],
            'esams' => [
                'knsq1.esams.wikimedia.org',
                'knsq2.esams.wikimedia.org',
                'knsq4.esams.wikimedia.org',
                'knsq5.esams.wikimedia.org',
                'knsq6.esams.wikimedia.org',
                'knsq7.esams.wikimedia.org',
            ],
            'ulsfo' => [],
        },
        'upload' => {
            'eqiad' => [
                'cp1021.eqiad.wmnet',
                'cp1022.eqiad.wmnet',
                'cp1023.eqiad.wmnet',
                'cp1024.eqiad.wmnet',
                'cp1025.eqiad.wmnet',
                'cp1026.eqiad.wmnet',
                'cp1027.eqiad.wmnet',
                'cp1028.eqiad.wmnet',
                'cp1029.eqiad.wmnet',
                'cp1030.eqiad.wmnet',
                'cp1031.eqiad.wmnet',
                'cp1032.eqiad.wmnet',
                'cp1033.eqiad.wmnet',
                'cp1034.eqiad.wmnet',
                'cp1035.eqiad.wmnet',
                'cp1036.eqiad.wmnet',
            ],
            'esams' => [
                'knsq8.knams.wikimedia.org',
                'knsq9.knams.wikimedia.org',
                'knsq10.knams.wikimedia.org',
                'knsq11.knams.wikimedia.org',
                'knsq12.knams.wikimedia.org',
                'knsq13.knams.wikimedia.org',
                'knsq14.knams.wikimedia.org',
                'knsq15.knams.wikimedia.org'
            ],
            'ulsfo' => [],
        },
        'mobile' => {
            'eqiad' => ['cp1041.eqiad.wmnet', 'cp1042.eqiad.wmnet'],
            'esams' => [],
            'ulsfo' => [],
        },
        'parsoid' => {
            'eqiad' => [],
            'esams' => [],
            'ulsfo' => [],
        },
        'misc' => {
            'eqiad' => [],
            'esams' => [],
            'ulsfo' => [],
        }
    }

    $backends = {
        'production' => {
            'appservers'        => $lvs::configuration::lvs_service_ips['production']['apaches'],
            'api'               => $lvs::configuration::lvs_service_ips['production']['api'],
            'rendering'         => $lvs::configuration::lvs_service_ips['production']['rendering'],
            'bits' => {
                'eqiad' => flatten([$lvs::configuration::lvs_service_ips['production']['bits']['eqiad']['bitslb']]),
            },
            'bits_appservers' => {
                'eqiad' => flatten([$lvs::configuration::lvs_service_ips['production']['apaches']['eqiad']]),
            },
            'test_appservers' => {
                'eqiad' => [ 'mw1017.eqiad.wmnet' ],
            },
            'parsoid' => $lvs::configuration::lvs_service_ips['production']['parsoid'],
            'cxserver' => {
                'eqiad' => 'cxserver.svc.eqiad.wmnet',
            },
            'citoid' => {
                'eqiad' => 'citoid.svc.eqiad.wmnet',
            },
            'restbase' => {
                'eqiad' => 'restbase.svc.eqiad.wmnet',
            },
        },
        'labs' => {
            'appservers' => {
                'eqiad' => [
                    '10.68.17.170',  # deployment-mediawiki01
                    '10.68.16.127', # deployment-mediawiki02
                ],
            },
            'api' => {
                'eqiad' => [
                    '10.68.17.170',  # deployment-mediawiki01
                    '10.68.16.127', # deployment-mediawiki02
                ],
            },
            'bits' => {
                'eqiad' => [
                    '10.68.17.170',  # deployment-mediawiki01
                    '10.68.16.127', # deployment-mediawiki02
                ],
            },
            'bits_appservers' => {
                'eqiad' => [
                    '10.68.17.170',  # deployment-mediawiki01
                    '10.68.16.127', # deployment-mediawiki02
                ],
            },
            'rendering' => {
                'eqiad' => [
                    '10.68.17.170',  # deployment-mediawiki01
                    '10.68.16.127', # deployment-mediawiki02
                ],
            },
            'test_appservers' => {
                'eqiad' => [ '10.68.17.170' ],  # deployment-mediawiki01
            },
            'parsoid' => {
                'eqiad' => [ '10.68.16.120' ],  # deployment-parsoid05
            },
            'cxserver' => {
                'eqiad' => 'cxserver-beta.wmflabs.org',
            },
            'citoid' => {
                'eqiad' => 'citoid.wmflabs.org',
            },
        }
    }
}
