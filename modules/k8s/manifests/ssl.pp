# Copy of etcd::ssl
# Copies appropriate cert files from the puppet CA infrastructure
# To be usable by the k8s binaries
# Note: Only copies public components, no private keys
class k8s::ssl(
    $provide_private = false,
    $user = 'root',
    $group = 'root',
    $ssldir = '/var/lib/puppet/client/ssl', # FIXME: This is different for self hosted puppet vs not. WHY?
) {
    $puppet_cert_name = $::fqdn


    file { [
        '/var/lib/kubernetes',
        '/var/lib/kubernetes/ssl',
        '/var/lib/kubernetes/ssl/certs',
        '/var/lib/kubernetes/ssl/private_keys',
    ]:
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0555',
    }


    file { '/var/lib/kubernetes/ssl/certs/ca.pem':
        ensure  => present,
        owner   => $user,
        group   => $group,
        mode    => '0444',
        source  => "${ssldir}/certs/ca.pem",
        require => File['/var/lib/kubernetes/ssl/certs'],
    }

    file { '/var/lib/kubernetes/ssl/certs/cert.pem':
        ensure  => present,
        owner   => $user,
        group   => $group,
        mode    => '0400',
        source  => "${ssldir}/certs/${puppet_cert_name}.pem",
        require => File['/var/lib/kubernetes/ssl/certs/ca.pem'],
    }

    if $provide_private {
        file { '/var/lib/kubernetes/ssl/private_keys/server.key':
            ensure  => present,
            owner   => $user,
            group   => $group,
            mode    => '0400',
            source  => "${ssldir}/private_keys/${puppet_cert_name}.pem",
            require => File['/var/lib/kubernetes/ssl/private_keys'],
        }
    }
}
