#

# class to satify includes
# lint:ignore:autoloader_layout
class role::cache::configuration {
# lint:endignore
        $active_nodes = {
            'production' => {
                'text' => {
                    'eqiad' => [
                        'cp1052.eqiad.wmnet',
                        'cp1068.eqiad.wmnet',
                    ],
                    'esams' => [
                    ],
                    'ulsfo' => [
                        'cp4008.ulsfo.wmnet',
                        'cp4018.ulsfo.wmnet',
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
                    ],
                },
                'misc' => {
                    'eqiad' => [],
                    'esams' => [],
                    'ulsfo' => [],
                },
            },
            'labs' => {
                'mobile' => {
                    'eqiad' => '127.0.0.1',
                },
                'text'   => {
                    'eqiad' => '127.0.0.1',
                },
                'upload' => {
                    'eqiad' => '127.0.0.1',
                },
            },
        }

        $backends = {
            'production' => {
                'appservers'        => ['1.1.1.1', '2.2.2.2',],
                'api'               => ['1.1.1.1', '2.2.2.2',],
                'rendering'         => ['1.1.1.1', '2.2.2.2',],
                'appservers_debug'  => {
                    'eqiad' => [ 'appservers-debug.svc.eqiad.wmnet' ],
                },
            },
            'labs' => {
                'appservers' => {
                    'eqiad' => [
                        '10.68.19.128', # deployment-mediawiki04
                        '10.68.22.21', # deployment-mediawiki05
                    ],
                },
                'api' => {
                    'eqiad' => [
                        '10.68.19.128', # deployment-mediawiki04
                        '10.68.22.21', # deployment-mediawiki05
                    ],
                },
                'rendering' => {
                    'eqiad' => [
                        '10.68.19.128', # deployment-mediawiki04
                        '10.68.22.21', # deployment-mediawiki05
                    ],
                },
                'appservers_debug' => {
                    'eqiad' => [ '10.68.19.128' ],  # deployment-mediawiki04
                },
            },
        }
}

include ::torrus::xml_generation::cdn
