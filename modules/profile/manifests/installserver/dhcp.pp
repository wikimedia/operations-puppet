# Installs a DHCP server and configures it for WMF
class profile::installserver::dhcp(
    Enum['stopped', 'running'] $ensure_service = lookup('profile::installserver::dhcp::ensure_service'),
){

    class { 'install_server::dhcp_server':
        ensure_service => $ensure_service,
    }

    ferm::service { 'dhcp':
        proto  => 'udp',
        port   => 'bootps',
        srange => '$PRODUCTION_NETWORKS',
    }
}
