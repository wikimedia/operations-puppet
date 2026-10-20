# SPDX-License-Identifier: Apache-2.0
# Envoy's BoringSSL gets confused by the Let's Encrypt root cross-signing
# hack around the expired DST Root CA X3, and the easy fix is to deselect
# the expired cert from the ca-certificates configuration.
#
class sslcert::ca_deselect_dstx3 {
    sslcert::deselect { 'mozilla/DST_Root_CA_X3.crt': }
}
