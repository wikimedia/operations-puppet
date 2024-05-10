# SPDX-License-Identifier: Apache-2.0
# @summary Set up PKI material for Pontoon server

class pontoon::pki_root (
    Array[String[3]] $intermediates,
    Cfssl::Ca_name $root_ca_name,
    Stdlib::Unixpath $volatile,
) {
    include cfssl  # lint:ignore:wmf_styleguide

    $pki_base = '/etc/pontoon/pki'
    $public_base = "${volatile}/pontoon/pki"

    file { $pki_base:
        ensure => directory,
        owner  => 'root',
        group  => 'puppet',
        mode   => '0440',
    }

    wmflib::dir::mkdir_p($public_base)

    # The CA public cert for clients to trust (via profile::pontoon::base)
    ["${pki_base}/ca.pem", "${public_base}/ca.pem"].each |$dest| {
        file { $dest:
            ensure    => present,
            owner     => 'root',
            group     => 'puppet',
            mode      => '0440',
            source    => "${cfssl::signer_dir}/${root_ca_name}/ca/ca.pem",
            require   => Cfssl::Signer[$root_ca_name],
            subscribe => Cfssl::Signer[$root_ca_name],
        }
    }

    # The intermediates keypairs to serve to the multiroot CA host.
    $intermediates.each |$int| {
        file { "${pki_base}/${int}-key.pem":
            source    => "${cfssl::ssl_dir}/${int}/${int}-key.pem",
            show_diff => false,
            mode      => '0440',
            owner     => 'root',
            group     => 'puppet',
            subscribe => Cfssl::Cert[$int]
        }

        # Key and cert are not symmetric in naming. multirootca expects
        # intermediate public material name to end with -cert.pem and
        # cfssl generates the cert without said suffix.
        file { "${pki_base}/${int}-cert.pem":
            source    => "${cfssl::ssl_dir}/${int}/${int}.pem",
            show_diff => false,
            mode      => '0440',
            owner     => 'root',
            group     => 'puppet',
            subscribe => Cfssl::Cert[$int]
        }

        # Make the public cert available via puppet:///
        file { "${public_base}/${int}-cert.pem":
            source    => "${cfssl::ssl_dir}/${int}/${int}.pem",
            subscribe => Cfssl::Cert[$int],
        }
    }
}
