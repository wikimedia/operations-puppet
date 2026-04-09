# SPDX-License-Identifier: Apache-2.0
# == Class: thanos::compact
#
# The thanos compact command (also known as Store Gateway) implements the Store
# API on top of historical data in an object storage bucket. It keeps a small
# amount of information about all remote blocks on local disk and keeps it in
# sync with the bucket.
#
# = Parameters
# [*objstore_account*] The account to use to access object storage
# [*objstore_password*] The password to access object storage
# [*http_port*] The port to use for HTTP
# [*retention_raw*] How long to retain raw samples
# [*retention_5m*] How long to retain 5m resolution samples
# [*retention_1h*] How long to retain 1h resolution samples
# [*concurrency*] How many cores to use while compacting
# [*block_meta_fetch_concurrency*] Number of goroutines to fecth block metadata

class thanos::compact (
    Hash[String, String] $objstore_account,
    String $objstore_password,
    Wmflib::Ensure $ensure = present,
    String $retention_raw = '60w',
    String $retention_5m = '60w',
    String $retention_1h = '60w',
    Stdlib::Port::Unprivileged $http_port = 12902,
    Integer $concurrency = max($facts['processors']['count'] / 2, 1),
    Integer $block_meta_fetch_concurrency = 32,
) {
    ensure_packages(['thanos'])

    $http_address = "0.0.0.0:${http_port}"
    $service_name = 'thanos-compact'
    $data_dir = '/srv/thanos-compact'
    $objstore_config_file = '/etc/thanos-compact/objstore.yaml'
    $relabel_config_file = '/etc/thanos-compact/relabel.yaml'

    $compactor_eligible_hosts = wmflib::role::hosts('titan')

    $ruler_blocks_designated_compactor = $compactor_eligible_hosts[0] == $facts['networking']['fqdn']

    prometheus::instances().each |$instance_name, $instance_config| {
        if !($instance_config['designated_compactor'] in $compactor_eligible_hosts) {
            fail("Instance ${instance_name} has designated_compactor ${instance_config['designated_compactor']} which is not eligible to run compactor")
        }
    }

    $owned_instances = (prometheus::instances().reduce([]) |$memo, $data| {
            if $data[1]['designated_compactor'] == $facts['networking']['fqdn'] {
                $memo + [$data[0]]
            } else {
                $memo
            }
    }).sort().unique()

    file { $data_dir:
        ensure => directory,
        mode   => '0750',
        owner  => 'thanos',
        group  => 'thanos',
    }

    file { '/etc/thanos-compact':
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { "${relabel_config_file}.unreferenced":
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0550',
        owner   => 'thanos',
        group   => 'root',
        content => template('thanos/compact-relabel.yaml.erb'),
    }

    exec { 'orchestrated restart needed':
      command => "/bin/sh -c 'cmp -s \"${relabel_config_file}\" \"${relabel_config_file}.unreferenced\" || (echo \"Please run the sre.o11y.thanos-compact-restart cookbook\" >&2; exit 1)'",
      path    => ['/bin', '/usr/bin'],
      require => [File["${relabel_config_file}.unreferenced"], File[$objstore_config_file]],
    }

    file { $objstore_config_file:
        ensure    => $ensure,
        mode      => '0440',
        owner     => 'thanos',
        group     => 'root',
        show_diff => false,
        content   => template('thanos/objstore.yaml.erb'),
    }

    if $ensure != present {
        $service_ensure = $ensure
    } else {
        if (length($owned_instances) > 0) or ($ruler_blocks_designated_compactor) {
            $service_ensure = 'present'
            $service_enable = true
            class { 'thanos::compact::prometheus': }
        } else {
            $service_ensure = 'absent'
            $service_enable = false
        }
    }

    systemd::service { $service_name:
        ensure         => $service_ensure,
        restart        => true,
        override       => true,
        content        => systemd_template('thanos-compact'),
        service_params => {
            enable     => $service_enable,
            hasrestart => true,
        },
    }
}
