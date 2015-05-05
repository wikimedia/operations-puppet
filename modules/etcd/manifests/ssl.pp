# == Class etcd::ssl
#
# Copies the relevant certificates from the puppet/ssl directory to here.
class etcd::ssl($puppet_cert_name = $::fqdn,) {

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
        source  => "/var/lib/puppet/ssl/certs/${puppet_cert_name}.pem",
        require => File['/var/lib/etcd/ssl/ca.pem'],
        notify  => Service['etcd']
    }

    file { '/var/lib/etcd/ssl/keys':
        ensure => directory,
        owner   => 'etcd',
        group   => 'etcd',
        mode    => '0500',
    }

    file { '/var/lib/etcd/ssl/keys/server.pem':
        ensure => present,
        owner  => 'etcd',
        group  => 'etcd',
        mode   => '0500',
        source => "/var/lib/puppet/ssl/private_keys/${puppet_cert_name}.pem"
    }
}
