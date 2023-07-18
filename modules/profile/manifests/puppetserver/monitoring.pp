# SPDX-License-Identifier: Apache-2.0
# @summary add monitoring for puppetserver
class profile::puppetserver::monitoring {

    include profile::puppetserver
    profile::prometheus::jmx_exporter { 'puppetserver':
        hostname    => $facts['networking']['hostname'],
        port        => 8141,
        config_file => "${profile::puppetserver::config_dir}/jmx_exporter.yaml",
        source      => 'puppet:///modules/profile/puppetserver/jmx_exporter.yaml',
    }
}
