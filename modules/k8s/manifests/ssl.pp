# Copy of etcd::ssl
# Copies appropriate cert files from the puppet CA infrastructure
# Also installs the puppet CA system-wide
# To be usable by the k8s binaries
# Note: Only copies public components, no private keys
class k8s::ssl(
    $provide_private = false,
    $user = 'root',
    $group = 'root',
) {
    $puppet_cert_name = $::fqdn
    $ssldir = '/var/lib/puppet/ssl'

    include base::puppet::ssl

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

    file { '/var/lib/kubernetes/ssl/certs/cert.pem':
        ensure  => present,
        owner   => $user,
        group   => $group,
        mode    => '0400',
        source  => "${ssldir}/certs/${puppet_cert_name}.pem",
    }

    if $provide_private {
        file { '/var/lib/kubernetes/ssl/private_keys/server.key':
            ensure  => present,
            owner   => $user,
            group   => $group,
            mode    => '0400',
            source  => "${ssldir}/private_keys/${puppet_cert_name}.pem",
        }
    }
}
