class profile::parsoid(
    Boolean $has_lvs = hiera('has_lvs', true),
) {
    if $has_lvs {
        require ::profile::lvs::realserver
    }

    class { '::service::configuration': }

    class { '::parsoid':
        port         => 8000,
        mwapi_server => $::service::configuration::mwapi_uri,
        mwapi_proxy  => ''
    }

    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        ensure => absent,
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }

}
