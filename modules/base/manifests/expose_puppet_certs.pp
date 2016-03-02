# == Define: base::expose_puppet_certs
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
define base::expose_puppet_certs(
    $ensure          = 'present',
    $provide_private = false,
    $user            = 'root',
    $group           = 'root',
    $ssldir          = '/var/lib/puppet/ssl',
) {
    $target_basedir = $title
    $puppet_cert_name = $::fqdn

    File {
        owner  => $user,
        group  => $group,
    }

    file { $target_basedir:
        ensure => ensure_directory($ensure),
        mode   => '0755', # more permissive!
    }

    file { [
        "${target_basedir}/ssl",
        "${target_basedir}/ssl/certs",
    ]:
        ensure  => ensure_directory($ensure),
        mode    => '0555',
    }

    file { "${target_basedir}/ssl/private_keys":
        ensure  => ensure_directory($ensure),
        mode    => '0550',
    }


    file { "${target_basedir}/ssl/certs/ca.pem":
        ensure  => $ensure,
        mode    => '0444',
        source  => "${ssldir}/certs/ca.pem",
    }

    file { "${target_basedir}/ssl/certs/cert.pem":
        ensure  => $ensure,
        mode    => '0400',
        source  => "${ssldir}/certs/${puppet_cert_name}.pem",
    }

    if $provide_private {
        file { "${target_basedir}/ssl/private_keys/server.key":
            ensure  => $ensure,
            mode    => '0400',
            source  => "${ssldir}/private_keys/${puppet_cert_name}.pem",
        }
    }
}
