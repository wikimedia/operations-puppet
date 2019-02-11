# == Class: etcd
#
# Installs an etcd server and defines all its clustering
#
# SSL between peers is not supported at the moment as it's
# broken upstream
#
# === Parameters
# [*host*]
#   host (or IP) of the etcd server
#
# [*client_port*]
#   TCP port for the client connections
#
# [*adv_client_port*]
#   The TCP port the ETCD server will advertise to clients. Useful if you
#   proxy to etcd via nginx or some similar https terminator
#
# [*peer_port*]
#   TCP port for the cluster traffic
#
# [*cluster_name*]
#   Name of the cluster - defaults to the datacenter
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
# [*use_ssl*]
#   set to true if you want to impose use of HTTPS to communicate with
#   clients
#
# [*use_client_certs*]
#   Whether to require use of SSL certificates to connect to etcd.
#
# [*heartbeat_interval*]
#   Interval (in ms) at which etcd sends heartbeats to other peers. See
#   https://github.com/coreos/etcd/blob/release-2.2/Documentation/tuning.md for
#   details. Default value: 100
#
# [*election_timeout*]
#   Timeout for receiving election responses. Should usually be at least 10x the
#   heartbeat_interval. See the tuning document as well for details. Should be raised
#   whenever some latencies are present. Default value: 1000
#
class etcd (
    String $host = '127.0.0.1',
    Integer $client_port = 2379,
    Integer $adv_client_port = 2379,
    Integer $peer_port = 2380,
    String $cluster_name = $::domain,
    Stdlib::Compat::String $cluster_state = undef,
    Stdlib::Compat::String $srv_dns = undef,
    Stdlib::Compat::String $peers_list = undef,
    Boolean $use_ssl = false,
    Boolean $use_client_certs = false,
    Integer $heartbeat_interval = 100,
    Integer $election_timeout = 1000,
) {
    # Validation of parameters
    if ($use_client_certs and ! $use_ssl) {
        fail("Can't use SSL client certs if we don't use SSL")
    }
    unless $srv_dns or $peers_list {
        fail('We need either the domain name for DNS discovery or an explicit peers list')
    }

    require ::etcd::logging

    require_package('etcd')

    # SSL setup
    if $use_ssl {
        $adv_scheme = 'https'
        # If we're being proxied from a TLS terminator
        # let's keep it into account
        if ($adv_client_port == $client_port) {
            include ::etcd::ssl
            $scheme = 'https'
            $listen_host = $host
        } else {
            $scheme = 'http'
            $listen_host = '127.0.0.1'
        }
    } else {
        $adv_scheme = 'http'
        $scheme = 'http'
    }

    $client_url = "${scheme}://${listen_host}:${client_port}"
    $adv_client_url = "${adv_scheme}://${host}:${adv_client_port}"
    $peer_url = "http://${host}:${peer_port}" # Peer TLS is currently broken?
    $etcd_data_dir = "/var/lib/etcd/${cluster_name}"

    file { '/var/lib/etcd':
        ensure  => directory,
        owner   => 'etcd',
        group   => 'etcd',
        mode    => '0700',
        before  => Service['etcd'],
        require => Package['etcd'],
    }

    file { $etcd_data_dir:
        ensure => directory,
        owner  => 'etcd',
        group  => 'etcd',
        mode   => '0700',
    }

    systemd::service{ 'etcd':
        ensure  => present,
        content => template('etcd/initscripts/etcd.systemd.erb'),
        restart => true,
        require => File[$etcd_data_dir],
    }
}
