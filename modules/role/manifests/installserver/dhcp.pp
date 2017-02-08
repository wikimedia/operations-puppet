# Installs a DHCP server and configures it for WMF
class role::installserver::dhcp {

    system::role { 'role::installserver::dhcp':
        description => 'WMF DHCP server',
    }

    include install_server::dhcp_server

    include ::standard
    include ::base::firewall

    ferm::rule { 'dhcp':
        rule => 'proto udp dport bootps { saddr $PRODUCTION_NETWORKS ACCEPT; }'
    }

}

