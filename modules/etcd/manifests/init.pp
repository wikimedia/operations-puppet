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
#   When DNS-based cluster discovery is not available, provide a peers list
#
# [*use_ssl*]
#   set to true if you want to impose use of HTTPS to communicate with
#   clients
#
# [*use_client_certs*]
#   Whether to require use of SSL certificates to connect to etcd.
#
class etcd (
    $host             = '127.0.0.1',
    $client_port      = 2379,
    $adv_client_port  = 2379,
    $peer_port        = 2380,
    $cluster_name     = $::domain,
    $cluster_state    = undef,
    $srv_dns          = undef,
    $peers_list       = undef,
    $use_ssl          = false,
    $use_client_certs = false,
    ) {
    # This module is jessie only for now
    requires_os('debian >= jessie')

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

    base::service_unit{ 'etcd':
        ensure  => present,
        systemd => true,
        refresh => true,
        require => File[$etcd_data_dir],
    }

}
