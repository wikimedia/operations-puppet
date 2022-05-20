# SPDX-License-Identifier: Apache-2.0
# == Class: thanos::bucket_web
#
# Web interface for remote storage bucket.
#
# = Parameters
# [*http_port*] The port to use for HTTP

class thanos::bucket_web (
    Hash[String, String] $objstore_account,
    String $objstore_password,
    Stdlib::Port::Unprivileged $http_port = 15902,
) {
    ensure_packages(['thanos'])

    $http_address = "0.0.0.0:${http_port}"
    $service_name = 'thanos-bucket-web'
    $objstore_config_file = '/etc/thanos-bucket-web/objstore.yaml'

    file { '/etc/thanos-bucket-web':
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { $objstore_config_file:
        ensure    => present,
        mode      => '0440',
        owner     => 'thanos',
        group     => 'root',
        show_diff => false,
        content   => template('thanos/objstore.yaml.erb'),
    }

    systemd::service { $service_name:
        ensure         => present,
        restart        => true,
        content        => systemd_template('thanos-bucket-web'),
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }
}
