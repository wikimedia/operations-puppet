# SPDX-License-Identifier: Apache-2.0
#
# Builds a TLS cert in the order of key + cert + chain, which is required by
# Postfix for smtpd_tls_chain_files[1]. Returns a Concat resource of the
# file path to be created.
#
# TODO: If acme-chief adds support for retrieving individual files, we can grab
#       the files directly from acme-chief rather than pulling them down with
#       acme_chief::cert and consuming them on disk,
#       https://phabricator.wikimedia.org/T364589
#
# [1]: https://www.postfix.org/postconf.5.html#smtpd_tls_chain_files:~:text=smtpd_tls_chain_files%20(default%3A%20empty)
function profile::postfix::acme_chief_cert(
    String[1]    $cert,
    String[1]    $tls_key_type,
) >> Type[Concat] {
    $path = "/etc/ssl/private/${cert}.${tls_key_type}.crt"
    $cert_rsc =
        concat { $path:
            path      => $path,
            show_diff => false,
            backup    => false,
            mode      => '0400',
        }
    $src_base = '/etc/acmecerts/mx-out/live'
    # lint:ignore:puppet_url_without_modules
    concat::fragment { "${cert}-${tls_key_type}-private-key":
        target => $path,
        order  => '01',
        source => "file://${src_base}/${tls_key_type}.key",
    }
    concat::fragment { "${cert}-${tls_key_type}-public-key":
        target => $path,
        order  => '02',
        source => "file://${src_base}/${tls_key_type}.crt",
    }
    concat::fragment { "${cert}-${tls_key_type}-public-chain":
        target => $path,
        order  => '03',
        source => "file://${src_base}/${tls_key_type}.chain.crt",
    }
    # lint:endignore
    $cert_rsc[0]
}
