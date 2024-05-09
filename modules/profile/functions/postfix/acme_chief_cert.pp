# SPDX-License-Identifier: Apache-2.0
# 
# Builds a TLS cert in the order of key + cert + chain, which is required by
# Postfix for smtpd_tls_chain_files[1]. Returns a Concat resource of the
# file path to be created.
#
# [1]: https://www.postfix.org/postconf.5.html#smtpd_tls_chain_files:~:text=smtpd_tls_chain_files%20(default%3A%20empty)
function profile::postfix::acme_chief_cert(
    Stdlib::Host $acme_chief_host,
    String[1]    $cert,
    String[1]    $tls_key_type,
) >> Type[Concat] {
    require acme_chief

    $path = "/etc/ssl/private/${cert}.${tls_key_type}.crt"
    $cert_rsc =
        concat { $path:
            path => $path,
            mode => '0400',
        }
    $src_base = "${acme_chief_host}/acmedata/${cert}/live"
    # lint:ignore:puppet_url_without_modules
    concat::fragment { "${cert}-${tls_key_type}-private-key":
        target => $path,
        order  => '01',
        source => "puppet://${src_base}/${tls_key_type}.key",
    }
    concat::fragment { "${cert}-${tls_key_type}-public-key":
        target => $path,
        order  => '02',
        source => "puppet://${src_base}/${tls_key_type}.crt",
    }
    concat::fragment { "${cert}-${tls_key_type}-public-chain":
        target => $path,
        order  => '03',
        source => "puppet://${src_base}/${tls_key_type}.chain.crt",
    }
    # lint:endignore
    $cert_rsc[0]
}
