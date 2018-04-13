# Installs a DHCP server and configures it for WMF
class profile::installserver::dhcp {

    system::role { 'installserver::dhcp':
        description => 'WMF DHCP server',
    }

    include install_server::dhcp_server

    ferm::rule { 'dhcp':
        rule => 'proto udp dport bootps { saddr $PRODUCTION_NETWORKS ACCEPT; }'
    }

}

