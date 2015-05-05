# == Class etcd
#
# Installs an etcd server and defines all its clustering

class etcd (
    $client_netloc    ='127.0.0.1:2378',
    $peer_netloc      = '127.0.0.1:2379',
    $cluster_name     = $::domain,
    $cluster_state    = undef,
    $srv_dns          = undef,
    $peers_list       = undef,
    $use_ssl          = false,
    $use_client_certs = false,
    $cert_name        = $::fqdn,
    ) {
    # This module is jessie only for now
    require_os('Debian >= jessie')

    # Validation of parameters
    if ($use_ssl and ! $cert_name) {
            fail("Can't set up ssl without a cert_name")
    }
    if ($use_client_certs and ! $use_ssl) {
        fail("Can't use SSL client certs if we don't use SSL")
    }
    unless $srv_dns or $peers_list {
        fail("We need either the domain name for DNS discovery or an explicit peers list")
    }

    package { 'etcd':
        ensure => present,
    }

    # SSL setup
    if $use_ssl {
        $scheme = 'https'

        file { '/var/lib/etcd/ssl':
            ensure  => directory,
            owner   => 'etcd',
            group   => 'etcd',
            mode    => '0500',
            require => Package['etcd']
        }
        file { '/var/lib/etcd/ssl/ca.pem':
            ensure => present,
            owner  => 'etcd',
            group  => 'etcd',
            mode   => '0400',
            source => '/var/lib/puppet/ssl/certs/ca.pem',
            notify => Service['etcd'],
        }
        file { '/var/lib/etcd/ssl/cert.pem':
            ensure  => present,
            owner   => 'etcd',
            group   => 'etcd',
            mode    => '0400',
            source  => "/var/lib/puppet/ssl/certs/${cert_name}.pem",
            require => File['/var/lib/etcd/ssl/ca.pem'],
            notify  => Service['etcd']
        }
    } else {
        $scheme = 'http'
    }

    $client_url = "${scheme}://${client_netloc}"
    $peer_url = "${scheme}://${peer_netloc}"
    $etcd_data_dir = "/var/lib/etcd/${cluster_name}"

    file { $etcd_data_dir:
        ensure  => directory,
        owner   => 'etcd',
        group   => 'etcd',
        mode    => '0700',
        require => Package['etcd'],
    }

    base::service_unit{ 'etcd':
        ensure  => present,
        systemd => true,
        refresh => true,
        require => File[$etcd_data_dir],
    }
}
