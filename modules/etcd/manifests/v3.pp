# == Class: etcd::v3
#
# Installs an etcd 3 server and defines all its clustering. Some sane defaults are
# assumed - for instance TLS is enforced between nodes and with the client.
#
# Things not covered here and that will need an external management:
# * RBAC (both v3 with native RBAC and v2 with a tls proxy)
# * SSL certificate management. You'll have to provide those
# * Monitoring/alerting
#
# === Parameters
# [*member_name*]
#   The name of the peer inside the cluster. Defaults to the hostname
#
# [*client_listen_host*]
#   Host on which we will listen for client connections
#
# [*client_listen_ip*]
#   IP on which we will listen for client connections
#
# [*peer_listen_host*]
#   Host on which we will listen for client connections
#
# [*peer_listen_ip*]
#   IP on which we will listen for peer connections
#
# [*adv_client_port*]
#   The TCP port the ETCD server will advertise to clients. Useful if you
#   proxy to etcd via nginx or some similar https terminator while we move to
#   using the v3 storage.
#
# [*max_latency_ms*]
#   Maximum network RTT between nodes, in milliseconds
#
# [*cluster_name*]
#   Name of the cluster - defaults to the domain
#
# [*cluster_state*]
#   State of the cluster at bootstrap, if any.
#
# [*srv_dns*]
#   Domain to use for DNS-based cluster discovery.
#
# [*peers_list*]
#   When DNS-based cluster discovery is not available, provide a peers list as a string
#
# [*use_client_certs*]
#   Whether to require use of SSL certificates to connect to etcd.
#
# [*trusted_ca*]
#   Path of the ca file to use. Default /etc/etcd/ssl/ca.pem
#
# [*client_cert*]
#   Path to the cert file to use for client connections.
#
# [*client_key*]
#   Path to the private key file to use for client connections.
#
# [*peer_cert*]
#   Path to the cert file to use for client connections.
#
# [*peer_key*]
#   Path to the private key file to use for client connections.
#
class etcd::v3 (
    String $member_name = $::hostname,
    String $client_listen_host = $::fqdn,
    Stdlib::Compat::Ipv4 $client_listen_ip = $::facts['ipaddress'],
    String $peer_listen_host = $::fqdn,
    Stdlib::Compat::Ipv4 $peer_listen_ip = $::facts['ipaddress'],
    String $cluster_name = $::domain,
    Stdlib::Port $adv_client_port = 2379,
    Integer $max_latency_ms = 10,
    Enum['new', 'existing'] $cluster_state = 'existing',
    Stdlib::Compat::String $srv_dns = undef,
    Stdlib::Compat::String $peers_list = undef,
    Boolean $use_client_certs = false,
    Stdlib::Unixpath $trusted_ca = '/etc/etcd/ssl/ca.pem',
    Stdlib::Unixpath $client_cert = "/etc/etcd/ssl/${client_listen_host}.pem",
    Stdlib::Unixpath $client_key = "/etc/etcd/ssl/private/${client_listen_host}.pem",
    Stdlib::Unixpath $peer_cert = "/etc/etcd/ssl/${peer_listen_host}.pem",
    Stdlib::Unixpath $peer_key = "/etc/etcd/ssl/private/${peer_listen_host}.pem"
) {
    ## Parameters validation
    unless $srv_dns or $peers_list {
        fail('We need either the domain name for DNS discovery or an explicit peers list')
    }
    # This module is stretch only for now
    requires_os('debian >= stretch')

    # Base parameters
    # All parameters are listed here, and will end up in
    # /etc/default/etcd
    $data_dir = "/var/lib/etcd/${cluster_name}"
    $heartbeat_interval = 10 * $max_latency_ms
    $election_timeout = 10 * $heartbeat_interval
    $peer_url = "https://${peer_listen_ip}:2380"
    $adv_peer_url = "https://${peer_listen_host}:2380"
    $client_url = "https://${client_listen_ip}:2379"
    $adv_client_url = "https://${client_listen_host}:${adv_client_port}"

    # Packages installation and setup
    class { '::etcd::logging': }

    package { ['etcd-server', 'etcd-client']:
        ensure => present,
    }

    file { '/etc/default/etcd':
        ensure  => present,
        content => template('etcd/v3.etcd.default.erb'),
        notify  => Service['etcd'],
    }

    file { '/var/lib/etcd':
        ensure => directory,
        owner  => 'etcd',
        group  => 'etcd',
        mode   => '0700',
    }

    service { 'etcd':
        ensure   => running,
    }
}
