# SPDX-License-Identifier: Apache-2.0
# Envoy's BoringSSL gets confused by the Let's Encrypt root cross-signing
# hack around the expired DST Root CA X3, and the easy fix is to deselect
# the expired cert from the ca-certificates configuration.
#
class sslcert::ca_deselect_dstx3 {
    include sslcert

    file_line { 'deselect_dst_root_ca_x3':
        path               => '/etc/ca-certificates.conf',
        match              => '^!?mozilla/DST_Root_CA_X3\.crt$',
        line               => '!mozilla/DST_Root_CA_X3.crt',
        append_on_no_match => false,
        # These are in the sslcert init.pp:
        notify             => Exec['update-ca-certificates'],
        require            => Package['ca-certificates'],
    }
}
