# SPDX-License-Identifier: Apache-2.0

class pontoon::pki_root (
    Array[String[3]] $intermediates,
) {
    include cfssl  # lint:ignore:wmf_styleguide

    $pki_base = '/etc/pontoon/pki'
    file { $pki_base:
        ensure => directory,
        owner  => 'root',
        group  => 'puppet',
        mode   => '0440',
    }

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
    }
}
