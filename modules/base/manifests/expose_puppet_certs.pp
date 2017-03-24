# == Define: base::expose_puppet_certs
# Copies appropriate cert files from the puppet CA infrastructure
# To be usable by the other applications
# Note: Only copies public components, no private keys, unless specifically
# asked.
#
# === Parameters
#
# [*title*]
#   The directory in which the certificates will be exposed. A subdirectory
#   named "ssl" will be created.
#
# [*ensure*]
#   If 'present', certificates will be exposed, otherwise they will be removed.
#   Defaults to present
#
# [*provide_private*]
#   Should the private keys also be exposed? Defaults to false
#
# [*provide_keypair*]
#   Should the single file containing concatenated the private key and the cert
#   be exposed? The order is [key, cert] Defaults to false. Unrelated to
#   provide_private parameter
#
# [*user/group*]
#   User who will own the exposed SSL certificates. Default to root
#
# [*ssldir*]
#   The source directory containing the original SSL certificates. Avoid
#   supplying this unless you know what you are doing
#
define base::expose_puppet_certs(
    $ensure          = 'present',
    $provide_private = false,
    $provide_keypair = false,
    $user            = 'root',
    $group           = 'root',
    $ssldir          = puppet_ssldir(),
) {
    validate_absolute_path($ssldir)

    $target_basedir = $title
    $puppet_cert_name = $::fqdn

    File {
        owner  => $user,
        group  => $group,
    }

    file { "${target_basedir}/ssl":
        ensure => ensure_directory($ensure),
        mode   => '0555',
    }

    file { "${target_basedir}/ssl/cert.pem":
        ensure => $ensure,
        mode   => '0444',
        source => "${ssldir}/certs/${puppet_cert_name}.pem",
    }

    # Provide the private key
    $private_key_ensure = $ensure ? {
        'present' => $provide_private ? {
            true    => 'present',
            default => 'absent',
        },
        default => 'absent',
    }
    file { "${target_basedir}/ssl/server.key":
        ensure => $private_key_ensure,
        mode   => '0400',
        source => "${ssldir}/private_keys/${puppet_cert_name}.pem",
    }

    # Provide a keypair of key and cert concatenated. The file resource is used
    # to ensure file attributes/presence and the exec resource the contents
    $keypair_ensure = $ensure ? {
        'present' => $provide_keypair ? {
            true    => 'present',
            default => 'absent',
        },
        default => 'absent',
    }
    file { "${target_basedir}/ssl/server-keypair.pem":
        ensure  => $keypair_ensure,
        mode    => '0400',
    }
    if $provide_keypair {
        exec { "create-${title}-keypair":
            before  => File["${target_basedir}/ssl/server-keypair.pem"],
            creates => "${target_basedir}/ssl/server-keypair.pem",
            command => "/bin/cat \
                         ${ssldir}/private_keys/${puppet_cert_name}.pem \
                         ${ssldir}/certs/${puppet_cert_name}.pem \
                        > ${target_basedir}/ssl/server-keypair.pem",
        }
    }
}
