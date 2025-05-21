# SPDX-License-Identifier: Apache-2.0
# @summary Uninstalls remains of the Puppet StatsD reporter.
class puppet_statsd () {
    file { "${::puppet_config_dir}/statsd.yaml":
        ensure => absent,
    }
}
