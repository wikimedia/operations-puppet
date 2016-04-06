class role::toollabs::docker::registry {
    include ::toollabs::infrastructure

    require role::labs::lvm::srv

    sslcert::certificate { 'star.tools.wmflabs.org':
        skip_private => true,
        before       => Class['::docker::registry'],
    }
    class { '::docker::registry':
        datapath             => '/srv/registry',
        ssl_certificate_name => 'star.tools.wmflabs.org',
        ssl_settings         => ssl_ciphersuite('nginx', 'compat'),
    }
}
