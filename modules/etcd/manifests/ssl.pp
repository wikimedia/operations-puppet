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
# [*provide_private*]
#   If true, private keys will be copied too.  Set this to true if you
#   are provisioning an etcd server when including this class.
#   Default: false
#
class etcd::ssl(
    $puppet_cert_name = $::fqdn,
    $ssldir           = '/var/lib/puppet/ssl',
    $provide_private  = false
) {

    file { '/var/lib/etcd/ssl':
        ensure  => directory,
        owner   => 'etcd',
        group   => 'etcd',
        mode    => '0500',
        require => Package['etcd']
    }

    file { '/var/lib/etcd/ssl/certs':
        ensure  => directory,
        owner   => 'etcd',
        group   => 'etcd',
        mode    => '0500',
    }

    file { '/var/lib/etcd/ssl/certs/ca.pem':
        ensure => present,
        owner  => 'etcd',
        group  => 'etcd',
        mode   => '0400',
        source => "${ssldir}/certs/ca.pem",
    }

    # $::etcd::ssl::cert can be used by other classes
    # to make sure they are using the proper
    # cert file when connecting to etcd.
    $cert = '/var/lib/etcd/ssl/certs/cert.pem'
    file { $cert:
        ensure  => present,
        owner   => 'etcd',
        group   => 'etcd',
        mode    => '0400',
        source  => "${ssldir}/certs/${puppet_cert_name}.pem",
        require => File['/var/lib/etcd/ssl/certs/ca.pem'],
    }

    if $provide_private {
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
}
