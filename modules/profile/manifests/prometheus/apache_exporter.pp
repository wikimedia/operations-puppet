# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::apache_exporter {
    prometheus::apache_exporter { 'default': }
}
