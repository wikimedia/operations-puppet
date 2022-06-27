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
# [*provide_p12*]
#   Should the p12 file also be exposed, useful for java clients? Defaults to false
#
# [*provide_pem*]
#   Should the public pem file also be exposed? Defaults to true
#
# [*user/group*]
#   User who will own the exposed SSL certificates. Default to root
#
# [*ssldir*]
#   The source directory containing the original SSL certificates. Avoid
#   supplying this unless you know what you are doing
#
define base::expose_puppet_certs (
    Wmflib::Ensure       $ensure          = 'present',
    Boolean              $provide_private = false,
    Boolean              $provide_keypair = false,
    Boolean              $provide_pem     = true,
    Boolean              $provide_p12     = false,
    String               $p12_password    = '',
    String               $user            = 'root',
    String               $group           = 'root',
    Stdlib::Absolutepath $ssldir          = puppet_ssldir(),
) {
    # TODO: move this define to the puppet class
    include puppet::agent # lint:ignore:wmf_styleguide


    $target_basedir = $title
    $puppet_cert_name = $facts['fqdn']

    File {
        owner  => $user,
        group  => $group,
    }

    file { "${target_basedir}/ssl":
        ensure => stdlib::ensure($ensure, 'directory'),
        mode   => '0555',
    }

    if $ensure == 'absent' {
        File["${target_basedir}/ssl"] {
            recurse => true,
            force   => true,
        }
    }

    $pem_ensure = $ensure ? {
        'present' => $provide_pem ? {
            true    => 'present',
            default => 'absent',
        },
        default => 'absent',
    }
    file { "${target_basedir}/ssl/cert.pem":
        ensure => $pem_ensure,
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
        ensure => $keypair_ensure,
        mode   => '0400',
    }
    if $provide_keypair {
        exec { "create-${title}-keypair":
            before  => File["${target_basedir}/ssl/server-keypair.pem"],
            require => File["${target_basedir}/ssl"],
            creates => "${target_basedir}/ssl/server-keypair.pem",
            command => "/bin/cat \
                         ${ssldir}/private_keys/${puppet_cert_name}.pem \
                         ${ssldir}/certs/${puppet_cert_name}.pem \
                        > ${target_basedir}/ssl/server-keypair.pem",
        }
    }
    $p12_key_ensure = $ensure ? {
        'present' => $provide_p12 ? {
            true    => 'present',
            default => 'absent',
        },
        default => 'absent',
    }
    sslcert::x509_to_pkcs12 {"base::expose_puppet_cert: ${title}":
        ensure      => $p12_key_ensure,
        owner       => $user,
        group       => $group,
        public_key  => $facts['puppet_config']['hostcert'],
        private_key => $facts['puppet_config']['hostprivkey'],
        outfile     => "${target_basedir}/ssl/server.p12",
        certfile    => $facts['puppet_config']['localcacert'],
        password    => $p12_password,
    }
}
