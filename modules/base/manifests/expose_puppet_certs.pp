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
# [*notify*]
#   Can be used to notify a service that SSL certificates have changed. For
#   example, nginx should be restarted in case of certificate changes.
define base::expose_puppet_certs(
    $ensure          = 'present',
    $provide_private = false,
    $user            = 'root',
    $group           = 'root',
    $ssldir          = puppet_ssldir(),
    $notify          = undef,
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
        notify => $notify,
    }

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
        notify => $notify,
    }
}
