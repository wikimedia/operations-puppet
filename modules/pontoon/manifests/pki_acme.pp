# SPDX-License-Identifier: Apache-2.0
# @summary Shim to request acme-chief certificates from PKI and serve them with puppet fileserver.

class pontoon::pki_acme (
  Hash[String, Acme_chief::Certificate] $acme_certs,
  Stdlib::UnixPath $base_dir = '/srv/puppet_fileserver/acmedata',
  String $cfssl_label = 'discovery',
) {
    $acme_certs.each |$name, $config| {
        $outdir = "${base_dir}/${name}/live"
        $parent = $outdir.dirname
        file { [$parent, $outdir]:
            ensure => directory,
            group  => 'puppet',
            mode   => '0750',
        }

        cfssl::cert { $name:
            common_name   => $config['CN'],
            hosts         => $config['SNI'],
            label         => $cfssl_label,
            outdir        => $outdir,
            provide_chain => true,
            group         => 'puppet',
        }

        # Compat symlinks with what acme-chief issues and clients expect
        ['ec-prime256v1', 'rsa-2048'].each |$key_type| {
            file { "${outdir}/${key_type}.key":
                ensure => link,
                target => "${name}-key.pem",
            }

            file { "${outdir}/${key_type}.chained.crt":
                ensure => link,
                target => "${name}.chained.pem",
            }
        }
    }
}
