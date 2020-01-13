# Installs a DHCP server and configures it for WMF
class profile::installserver::dhcp {

    include install_server::dhcp_server

    ferm::service { 'dhcp':
        proto  => 'udp',
        port   => 'bootps',
        srange => '$PRODUCTION_NETWORKS',
    }
}

