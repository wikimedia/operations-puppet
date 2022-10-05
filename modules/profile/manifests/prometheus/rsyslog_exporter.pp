# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::rsyslog_exporter {
    class { '::prometheus::rsyslog_exporter': }
}
