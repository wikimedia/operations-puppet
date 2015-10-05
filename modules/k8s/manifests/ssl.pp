# Copy of etcd::ssl
# Copies appropriate cert files from the puppet CA infrastructure
# Also installs the puppet CA system-wide
# To be usable by the k8s binaries
# Note: Only copies public components, no private keys
class k8s::ssl(
    $provide_private = false,
    $user = 'root',
    $group = 'root',
    $target_basedir = '/var/lib/kubernetes'
) {
    $puppet_cert_name = $::fqdn

    $ssldir = puppet_ssldir(
        hiera('role::puppet::self::master', $::puppetmaster)
    )

    file { $target_basedir:
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0755', # more permissive!
    }

    file { [
        "${target_basedir}/ssl",
        "${target_basedir}/ssl/certs",
        "${target_basedir}/ssl/private_keys",
    ]:
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0555',
        require => File[$target_basedir], # less permissive
    }

    file { "${target_basedir}/ssl/certs/cert.pem":
        ensure  => present,
        owner   => $user,
        group   => $group,
        mode    => '0400',
        source  => "${ssldir}/certs/${puppet_cert_name}.pem",
        require => File["${target_basedir}/ssl/certs"],
    }

    if $provide_private {
        file { "${target_basedir}/ssl/private_keys/server.key":
            ensure  => present,
            owner   => $user,
            group   => $group,
            mode    => '0400',
            source  => "${ssldir}/private_keys/${puppet_cert_name}.pem",
            require => File["${target_basedir}/ssl/private_keys"],
        }
    }
}
