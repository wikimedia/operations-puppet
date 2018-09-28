class profile::parsoid(
    Boolean $has_lvs = hiera('has_lvs', true),
) {
    if $has_lvs {
        require ::profile::lvs::realserver
    }
    class { '::parsoid':
        port      => 8000,
        discovery => 'api-rw'
    }

    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        ensure => absent,
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }

}
