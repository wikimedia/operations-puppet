# Copy of etcd::ssl
# Copies appropriate cert files from the puppet CA infrastructure
# To be usable by the k8s binaries
# Note: Only copies public components, no private keys
class k8s::ssl(
    Boolean $provide_private = false,
    String $user = 'root',
    String $group = 'root',
    String $ssldir = '/var/lib/puppet/ssl',
    String $target_basedir = '/var/lib/kubernetes'
) {
    $puppet_cert_name = $::fqdn

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


    file { "${target_basedir}/ssl/certs/ca.pem":
        ensure  => present,
        owner   => $user,
        group   => $group,
        mode    => '0444',
        source  => "${ssldir}/certs/ca.pem",
        require => File["${target_basedir}/ssl/certs"],
    }

    file { "${target_basedir}/ssl/certs/cert.pem":
        ensure  => present,
        owner   => $user,
        group   => $group,
        mode    => '0400',
        source  => "${ssldir}/certs/${puppet_cert_name}.pem",
        require => File["${target_basedir}/ssl/certs/ca.pem"],
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
