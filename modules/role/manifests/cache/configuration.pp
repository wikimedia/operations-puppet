class role::cache::configuration {
    include lvs::configuration

    $has_ganglia = $::standard::has_ganglia

    $backends = {
        'production' => {
            'appservers'        => {
                'eqiad' => ['appservers.svc.eqiad.wmnet'],
                'codfw' => ['appservers.svc.codfw.wmnet'],
            },
            'api'               => {
                'eqiad' => ['api.svc.eqiad.wmnet'],
                'codfw' => ['api.svc.codfw.wmnet'],
            },
            'rendering'         => {
                'eqiad' => ['rendering.svc.eqiad.wmnet'],
                'codfw' => ['rendering.svc.codfw.wmnet'],
            },
            'appservers_debug' => {
                'eqiad' => ['appservers-debug.svc.eqiad.wmnet'],
            },
            'parsoid' => {
                'eqiad' => ['parsoid.svc.eqiad.wmnet'],
            },
            'cxserver' => {
                'eqiad' => ['cxserver.svc.eqiad.wmnet'],
            },
            'citoid' => {
                'eqiad' => ['citoid.svc.eqiad.wmnet'],
            },
            'restbase' => {
                'eqiad' => ['restbase.svc.eqiad.wmnet'],
            },
            'swift' => {
                'eqiad' => ['ms-fe.svc.eqiad.wmnet'],
                'codfw' => ['ms-fe.svc.codfw.wmnet'],
            },
            'security_audit' => { 'eqiad' => [] }, # no audit backend for prod at this time
            'kartotherian' => {
                'codfw' => ['kartotherian.svc.codfw.wmnet'],
            }
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
            'rendering' => {
                'eqiad' => [
                    '10.68.17.170',  # deployment-mediawiki01
                    '10.68.16.127', # deployment-mediawiki02
                ],
            },
            'security_audit' => {
                'eqiad' => [ '10.68.17.55' ],  # deployment-mediawiki03
            },
            'appservers_debug' => {
                'eqiad' => [ '10.68.17.170' ],  # deployment-mediawiki01
            },
            'parsoid' => {
                'eqiad' => [ '10.68.16.120' ],  # deployment-parsoid05
            },
            'cxserver' => {
                'eqiad' => ['cxserver-beta.wmflabs.org'],
            },
            'citoid' => {
                'eqiad' => ['citoid.wmflabs.org'],
            },
            'restbase' => {
                'eqiad' => ['deployment-restbase01.eqiad.wmflabs'],
            },
            'swift' => {
                # ms emulator set in July 2013. Beta does not have Swift yet.
                # instance is an unpuppetized hack with nginx proxy.
                'eqiad' => ['10.68.16.189'],  # deployment-upload.eqiad.wmflabs
            },
        }
    }
}
