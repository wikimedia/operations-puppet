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

class thanos::compact (
    Stdlib::Fqdn $run_on_host,
    Hash[String, String] $objstore_account,
    String $objstore_password,
    Wmflib::Ensure $ensure = present,
    String $retention_raw = '60w',
    String $retention_5m = '60w',
    String $retention_1h = '60w',
    Stdlib::Port::Unprivileged $http_port = 12902,
    Integer $concurrency = max($::processorcount / 2, 1),
) {
    ensure_packages(['thanos'])

    $http_address = "0.0.0.0:${http_port}"
    $service_name = 'thanos-compact'
    $data_dir = '/srv/thanos-compact'
    $objstore_config_file = '/etc/thanos-compact/objstore.yaml'

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
    } else { # handle fqdn-based singleton service
        if $run_on_host == $::fqdn {
            $service_ensure = 'present'
            $service_enable = true
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
