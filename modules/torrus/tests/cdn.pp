#

# class to satify includes
class role::cache::configuration {
        $active_nodes = {
            'production' => {
                'text' => {
                    'eqiad' => [
                        'cp1052.eqiad.wmnet',
                        'cp1068.eqiad.wmnet',
                    ],
                    'esams' => [
                        'amssq31.esams.wmnet',
                        'amssq62.esams.wmnet',
                    ],
                    'ulsfo' => [
                        'cp4008.ulsfo.wmnet',
                        'cp4018.ulsfo.wmnet',
                    ]
                },
                'api' => {
                    'eqiad' => [],
                    'esams' => [],
                    'ulsfo' => [],
                },
                'bits' => {
                    'eqiad' => ['cp1056.eqiad.wmnet',
                                'cp1070.eqiad.wmnet',
                    ],
                    'esams' => ['cp3019.esams.wmnet',
                                'cp3022.esams.wmnet',
                    ],
                    'ulsfo' => ['cp4001.ulsfo.wmnet',
                                'cp4004.ulsfo.wmnet',
                    ],
                },
                'upload' => {
                    'eqiad' => [
                        'cp1048.eqiad.wmnet',
                        'cp1064.eqiad.wmnet',
                    ],
                    'esams' => [
                        'cp3003.esams.wmnet',
                        'cp3018.esams.wmnet',
                    ],
                    'ulsfo' => [
                        'cp4005.ulsfo.wmnet',
                        'cp4015.ulsfo.wmnet',
                    ],
                },
                'mobile' => {
                    'eqiad' => ['cp1046.eqiad.wmnet',
                                'cp1060.eqiad.wmnet',
                    ],
                    'esams' => ['cp3011.esams.wmnet',
                                'cp3014.esams.wmnet',
                    ],
                    'ulsfo' => ['cp4011.ulsfo.wmnet',
                                'cp4020.ulsfo.wmnet',
                    ]
                },
                'parsoid' => {
                    'eqiad' => ['cp1045.eqiad.wmnet', 'cp1058.eqiad.wmnet'],
                    'esams' => [],
                    'ulsfo' => []
                },
                'misc' => {
                    'eqiad' => ['cp1043.eqiad.wmnet', 'cp1044.eqiad.wmnet'],
                    'esams' => [],
                    'ulsfo' => [],
                }
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

        $backends = {
            'production' => {
                'appservers'        => ['1.1.1.1', '2.2.2.2',],
                'api'               => ['1.1.1.1', '2.2.2.2',],
                'rendering'         => ['1.1.1.1', '2.2.2.2',],
                'bits' => {
                    'eqiad' => flatten(['1.1.1.1', '2.2.2.2',]),
                },
                'bits_appservers' => {
                    'eqiad' => flatten(['1.1.1.1', '2.2.2.2',]),
                },
                'test_appservers' => {
                    'eqiad' => [ 'mw1017.eqiad.wmnet' ],
                },
                'parsoid' => ['1.1.1.1'],
            },
            'labs' => {
                'appservers' => {
                    'eqiad' => [
                        '10.68.17.96',  # deployment-mediawiki01
                        '10.68.17.208', # deployment-mediawiki02
                    ],
                },
                'api' => {
                    'eqiad' => [
                        '10.68.17.96',  # deployment-mediawiki01
                        '10.68.17.208', # deployment-mediawiki02
                    ],
                },
                'bits' => {
                    'eqiad' => [
                        '10.68.17.96',  # deployment-mediawiki01
                        '10.68.17.208', # deployment-mediawiki02
                    ],
                },
                'bits_appservers' => {
                    'eqiad' => [
                        '10.68.17.96',  # deployment-mediawiki01
                        '10.68.17.208', # deployment-mediawiki02
                    ],
                },
                'rendering' => {
                    'eqiad' => [
                        '10.68.17.96',  # deployment-mediawiki01
                        '10.68.17.208', # deployment-mediawiki02
                    ],
                },
                'test_appservers' => {
                    'eqiad' => [ '10.68.17.96' ],  # deployment-mediawiki01
                },
                'parsoid' => {
                    'eqiad' => [ '10.68.16.17' ],  # deployment-parsoid04
                }
            }
        }
}

include torrus::xml_generation::cdn
