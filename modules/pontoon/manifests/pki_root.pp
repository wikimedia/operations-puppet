# SPDX-License-Identifier: Apache-2.0
# @summary Set up PKI material for Pontoon server

class pontoon::pki_root (
    Array[String[3]] $intermediates,
    String $root_ca_name,
) {
    include cfssl  # lint:ignore:wmf_styleguide

    $pki_base = '/etc/pontoon/pki'
    $public_base = '/var/lib/puppet/volatile/pontoon/pki'

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
            ensure => present,
            owner  => 'root',
            group  => 'puppet',
            mode   => '0440',
            source => "${cfssl::signer_dir}/${root_ca_name}/ca/ca.pem",
        }
    }

    # The intermediates keypairs to serve to the multiroot CA host.
    $intermediates.each |$int| {
        ["${int}.pem", "${int}-key.pem"].each |$file| {
            $source = "${cfssl::ssl_dir}/${int}/${file}"
            $dest = "${pki_base}/${file}"
            file { $dest:
                source    => $source,
                show_diff => false,
                mode      => '0440',
                owner     => 'root',
                group     => 'puppet',
                subscribe => Cfssl::Cert[$int]
            }
        }

        # Make the public cert available via puppet:///
        file { "${public_base}/${int}.pem":
            source    => "${cfssl::ssl_dir}/${int}/${int}.pem",
            subscribe => Cfssl::Cert[$int],
        }
    }
}
