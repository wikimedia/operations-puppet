# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::ipsec_exporter {

    class { '::prometheus::ipsec_exporter': }
}
