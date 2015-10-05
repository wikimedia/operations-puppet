# == Class etcd::ssl
#
# Copies the relevant certificates from the puppet/ssl directory to
# where they can used for etcd.
#
# === Parameters
#
# [*puppet_cert_name*]
#   The name on the puppet certificate.
#
# [*ssldir*]
#   The directory where the puppet ssl certs are contained
#
class etcd::ssl(
    $puppet_cert_name = $::fqdn,
    $ssldir           = '/var/lib/puppet/ssl',
    ) {

    $basedir = '/var/lib/etcd/ssl'
    $pubdir = "${basedir}/certs"

    file { [$basedir, $pubdir]:
        ensure  => directory,
        owner   => 'etcd',
        group   => 'etcd',
        mode    => '0500',
        require => Package['etcd'],
    }

    file { '/var/lib/etcd/ssl/certs/cert.pem':
        ensure  => present,
        owner   => 'etcd',
        group   => 'etcd',
        mode    => '0400',
        source  => "${ssldir}/certs/${puppet_cert_name}.pem",
    }

    file { '/var/lib/etcd/ssl/private_keys':
        ensure => directory,
        owner  => 'etcd',
        group  => 'etcd',
        mode   => '0500',
    }

    file { '/var/lib/etcd/ssl/private_keys/server.key':
        ensure => present,
        owner  => 'etcd',
        group  => 'etcd',
        mode   => '0400',
        source => "${ssldir}/private_keys/${puppet_cert_name}.pem",
    }
}
