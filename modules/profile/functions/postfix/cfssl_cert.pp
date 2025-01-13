# SPDX-License-Identifier: Apache-2.0
#
# Builds a cfssl TLS cert in the order of key + cert + chain, which is required
# by Postfix for smtpd_tls_chain_files[1]. Returns a Concat resource of the file
# path to be created.
#
# [1]: https://www.postfix.org/postconf.5.html#smtpd_tls_chain_files:~:text=smtpd_tls_chain_files%20(default%3A%20empty)
function profile::postfix::cfssl_cert(
    String[1]           $cert,
    Optional[String[1]] $label,
) >> Type[Concat] {

    $tls_paths = if $label {
        profile::pki::get_cert($label)
    } else {
        profile::pki::get_cert()
    }
    $path = "/etc/ssl/private/${cert}.crt"
    $cert_rsc =
        concat { $path:
            path      => $path,
            show_diff => false,
            backup    => false,
            mode      => '0400',
            require   => [
                File[$tls_paths['key']],
                File[$tls_paths['cert']],
                File[$tls_paths['chain']],
            ],
        }
    concat::fragment { "${cert}-private-key":
        target  => $path,
        order   => '01',
        source  => $tls_paths['key'],
        require => File[$tls_paths['key']],
    }
    concat::fragment { "${cert}-public-key":
        target  => $path,
        order   => '02',
        source  => $tls_paths['cert'],
        require => File[$tls_paths['cert']],
    }
    concat::fragment { "${cert}-public-chain":
        target  => $path,
        order   => '03',
        source  => $tls_paths['chain'],
        require => File[$tls_paths['chain']],
    }
    $cert_rsc[0]
}
