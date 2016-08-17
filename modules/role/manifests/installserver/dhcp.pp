# Installs a DHCP server and configures it for WMF
class role::installserver::dhcp {
    system::role { 'role::installserver::dhcp':
        description => 'WMF DHCP server',
    }

    include base::firewall
    include role::backup::host

    include install_server::dhcp_server
    ferm::rule { 'dhcp':
        rule => 'proto udp dport bootps { saddr $PRODUCTION_NETWORKS ACCEPT; }'
    }

}

