class role::ci::docker::registry {
    require ::role::labs::lvm::srv

    include ::docker::registry
    include ::sslcert::dhparam

    class { '::docker::registry::web':
        ssl_settings => ssl_ciphersuite('nginx', 'mid'),
        require => Class['::sslcert::dhparam'],
    }
}
