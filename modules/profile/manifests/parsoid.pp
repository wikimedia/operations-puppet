class profile::parsoid(
    $mw_host = hiera('profile::parsoid::mw_host', '')
) {

    system::role { 'role::parsoid':
        description => "Parsoid ${::realm}"
    }


    # If we are in the primary datacenter, go directly to the unencrypted api endpoint
    it $::realm == 'labs' {
        $mwapi_proxy = undef
        $wmapi_server = undef
    } elsif $::site == $::mwprimary {
        $mwapi_proxy = 'http://${mw_host}'
        $mwapi_server = undef
    } else {
        # Use the TLS endpoint
        $mwapi_proxy = undef
        $mwapi_server = "https://${mw_host}/w/api.php"
    }

    class { 'parsoid':
        mwapi_server => $mwapi_server,
        mwapi_proxy  => $mwapi_proxy,
    }

    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }
}
