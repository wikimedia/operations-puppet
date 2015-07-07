class role::cache::configuration {
    include lvs::configuration

    $has_ganglia = hiera('has_ganglia', true)

    $backends = {
        'production' => {
            'appservers'        => $lvs::configuration::service_ips['apaches'],
            'api'               => $lvs::configuration::service_ips['api'],
            'rendering'         => $lvs::configuration::service_ips['rendering'],
            'bits' => {
                'eqiad' => flatten([$lvs::configuration::service_ips['bits']['eqiad']['bitslb']]),
            },
            'bits_appservers' => {
                'eqiad' => flatten([$lvs::configuration::service_ips['apaches']['eqiad']]),
            },
            'test_appservers' => {
                'eqiad' => [ 'mw1017.eqiad.wmnet' ],
            },
            'parsoid' => $lvs::configuration::service_ips['parsoid'],
            'cxserver' => {
                'eqiad' => 'cxserver.svc.eqiad.wmnet',
            },
            'citoid' => {
                'eqiad' => 'citoid.svc.eqiad.wmnet',
            },
            'graphoid' => {
                'eqiad' => 'graphoid.svc.eqiad.wmnet',
            },
            'restbase' => {
                'eqiad' => 'restbase.svc.eqiad.wmnet',
            },
            'swift' => $lvs::configuration::service_ips['swift'],
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
            'security_audit' => {
                'eqiad' => [ '10.68.17.55' ],  # deployment-mediawiki03
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
            'restbase' => {
                'eqiad' => 'deployment-restbase01.eqiad.wmflabs',
            },
            'graphoid' => {
                'eqiad' => '10.68.16.145', # deployment-sca01
            },
            'swift' => {
                # ms emulator set in July 2013. Beta does not have Swift yet.
                # instance is an unpuppetized hack with nginx proxy.
                'eqiad' => '10.68.16.189',  # deployment-upload.eqiad.wmflabs
            },
        }
    }
}
