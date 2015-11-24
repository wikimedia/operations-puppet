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
    $host      = '127.0.0.1',
    $client_port      = 2379,
    $peer_port        = 2380,
    $cluster_name     = $::domain,
    $cluster_state    = undef,
    $srv_dns          = undef,
    $peers_list       = undef,
    $use_ssl          = false,
    $use_client_certs = false,
    ) {
    # This module is jessie only for now
    requires_os('Debian >= jessie')

    # Validation of parameters
    if ($use_client_certs and ! $use_ssl) {
        fail("Can't use SSL client certs if we don't use SSL")
    }
    unless $srv_dns or $peers_list {
        fail('We need either the domain name for DNS discovery or an explicit peers list')
    }

    require etcd::logging

    require_package 'etcd'

    # SSL setup
    if $use_ssl {
        $scheme = 'https'
        include etcd::ssl
    } else {
        $scheme = 'http'
    }

    $client_url = "${scheme}://${host}:${client_port}"
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
