# == Define: sslcert::expose_puppet_certs
# Copies appropriate cert files from the puppet CA infrastructure
# To be usable by the other applications
# Note: Only copies public components, no private keys, unless specifically
# asked.
#
# === Parameters
#
# [*title*]
#   The directory in which the certificates will be exported. A subdirectory
#   named "ssl" will be created.
#
# [*ensure*]
#   If 'present', certificates will be copied, otherwise they will be removed.
#
# [*provide_private*]
#   Should the private keys also be exposed?
#
# [*user/group*]
#   User who will own the exposed SSL certificates.
#
# [*ssldir*]
#   The source directory containing the original SSL certificates.
#
define sslcert::expose_puppet_certs(
    $ensure          = 'present',
    $provide_private = false,
    $user            = 'root',
    $group           = 'root',
    $ssldir          = '/var/lib/puppet/ssl',
) {
    $target_basedir = $title
    $puppet_cert_name = $::fqdn

    file { $target_basedir:
        ensure => ensure_directory($ensure),
        owner  => $user,
        group  => $group,
        mode   => '0755', # more permissive!
    }

    file { [
        "${target_basedir}/ssl",
        "${target_basedir}/ssl/certs",
        "${target_basedir}/ssl/private_keys",
    ]:
        ensure  => ensure_directory($ensure),
        owner   => $user,
        group   => $group,
        mode    => '0555',
        require => File[$target_basedir], # less permissive
    }


    file { "${target_basedir}/ssl/certs/ca.pem":
        ensure  => $ensure,
        owner   => $user,
        group   => $group,
        mode    => '0444',
        source  => "${ssldir}/certs/ca.pem",
        require => File["${target_basedir}/ssl/certs"],
    }

    file { "${target_basedir}/ssl/certs/cert.pem":
        ensure  => $ensure,
        owner   => $user,
        group   => $group,
        mode    => '0400',
        source  => "${ssldir}/certs/${puppet_cert_name}.pem",
        require => File["${target_basedir}/ssl/certs/ca.pem"],
    }

    if $provide_private {
        file { "${target_basedir}/ssl/private_keys/server.key":
            ensure  => $ensure,
            owner   => $user,
            group   => $group,
            mode    => '0400',
            source  => "${ssldir}/private_keys/${puppet_cert_name}.pem",
            require => File["${target_basedir}/ssl/private_keys"],
        }
    }
}
