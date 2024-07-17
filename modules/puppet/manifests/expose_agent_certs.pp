# @summary
# Copies appropriate cert files from the puppet CA infrastructure
# To be usable by the other applications
# Note: Only copies public components, no private keys, unless specifically
# asked.
#
# @param title
#   The directory in which the certificates will be exposed. A subdirectory
#   named "ssl" will be created.
# @param ensure
#   If 'present', certificates will be exposed, otherwise they will be removed.
#   Defaults to present
# @param provide_private
#   Should the private keys also be exposed? Defaults to false
# @param provide_keypair
#   Should the single file containing concatenated the private key and the cert
#   be exposed? The order is [key, cert] Defaults to false. Unrelated to
#   provide_private parameter
# @param provide_p12
#   Should the p12 file also be exposed, useful for java clients? Defaults to false
# @param include_chain if true include the certificate chain. useful when using intermidiates
# @param p12_password
#   password for p12 file
# @param user
#   File user permissions
# @param group
#   File group permissions
# @param provide_pem
#   Should the public pem file also be exposed? Defaults to true
# @param user/group
#   User who will own the exposed SSL certificates. Default to root
# @param ssldir
#   The source directory containing the original SSL certificates. Avoid
#   supplying this unless you know what you are doing
define puppet::expose_agent_certs (
    Wmflib::Ensure       $ensure          = 'present',
    Boolean              $provide_private = false,
    Boolean              $provide_keypair = false,
    Boolean              $provide_pem     = true,
    Boolean              $provide_p12     = false,
    Optional[String[1]]  $p12_password    = undef,
    String[1]            $user            = 'root',
    String[1]            $group           = 'root',
    Stdlib::Absolutepath $ssldir          = puppet_ssldir(),
) {
    include puppet::agent

    # In the puppet7 infrastructure we have an intermediate certificate as
    # such we need to create a bundle wit the chain.  It probably safe to
    # do this everywhere but we restrict to puppet 7 to contain fallout
    $include_chain = versioncmp($facts['puppetversion'], '7') >= 0

    $target_basedir = $title
    $puppet_cert_name = $facts['networking']['fqdn']
    $hostprivkey = "${ssldir}/private_keys/${puppet_cert_name}.pem"
    $hostcert = "${ssldir}/certs/${puppet_cert_name}.pem"
    $localcacert = "${ssldir}/certs/ca.pem"

    file { "${target_basedir}/ssl":
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => $user,
        group  => $group,
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
    $cert_dest = "${target_basedir}/ssl/cert.pem"
    if $include_chain {
        concat { $cert_dest:
            ensure => $pem_ensure,
        }
        concat::fragment { "${title}_puppet_agent_cert":
            target => $cert_dest,
            order  => '01',
            source => $hostcert,
        }
        # Here we add the full chain including the root CA, but we only strictly need
        # the intermediate certificate.  however its much harder to try and extract the
        # intermediate then just adding the hole chain.  The down side of adding the root
        # means we use a bit more bandwith as we are sending more certificates.
        concat::fragment { "${title}_puppet_ca_chain":
            target => $cert_dest,
            order  => '02',
            source => $localcacert,
        }

    } else {
        file { $cert_dest:
            ensure => $pem_ensure,
            mode   => '0444',
            owner  => $user,
            group  => $group,
            source => $hostcert,
        }
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
        ensure    => $private_key_ensure,
        mode      => '0400',
        owner     => $user,
        group     => $group,
        show_diff => false,
        source    => $hostprivkey,
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
        owner  => $user,
        group  => $group,
        mode   => '0400',
    }
    if $provide_keypair {
        exec { "create-${title}-keypair":
            before  => File["${target_basedir}/ssl/server-keypair.pem"],
            require => File["${target_basedir}/ssl"],
            creates => "${target_basedir}/ssl/server-keypair.pem",
            command => "/bin/cat \
                         ${hostprivkey} \
                         ${hostcert} \
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
    sslcert::x509_to_pkcs12 {"puppet::expose_agent_cert: ${title}":
        ensure      => $p12_key_ensure,
        owner       => $user,
        group       => $group,
        public_key  => $hostcert,
        private_key => $hostprivkey,
        outfile     => "${target_basedir}/ssl/server.p12",
        certfile    => $localcacert,
        password    => $p12_password,
    }
}
