# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::druid_exporter (
    $druid_version = lookup('profile::prometheus::druid_exporter::druid_version', { 'default_value' => '0.12.3' })
) {
    prometheus::druid_exporter { 'default':
        druid_version => $druid_version
    }
}
