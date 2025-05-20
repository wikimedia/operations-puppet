# SPDX-License-Identifier: Apache-2.0
#
# role to (ironically) apply on unpuppetized systems, has Kerberos enabled
#
class role::test_krb {
    include profile::base::production
    include profile::firewall
    include profile::kerberos::client
    include profile::kerberos::keytabs
}
