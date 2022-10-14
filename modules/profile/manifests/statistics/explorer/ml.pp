# SPDX-License-Identifier: Apache-2.0
# == Class profile::statistics::explorer::ml
#
# This class is meant to collect scripts and configs related
# to the Machine Learning team.
#
class profile::statistics::explorer::ml(
    $swift_s3_access_key = lookup('profile::statistics::explorer::ml::swift_s3_access_key'),
    $swift_s3_secret_key = lookup('profile::statistics::explorer::ml::swift_s3_password'),
    $swift_endpoint      = lookup('profile::statistics::explorer::ml::swift_endpoint', {'default_value' => 'https://thanos-swift.discovery.wmnet'}),
) {
    ensure_packages('s3cmd')

    file { '/etc/s3cmd':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/s3cmd/cfg.d':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    $swift_cfg_file = '/etc/s3cmd/cfg.d/ml-team.cfg'
    file { $swift_cfg_file:
        ensure  => file,
        owner   => 'root',
        group   => 'deploy-ml-service',
        mode    => '0440',
        content => template('profile/statistics/explorer/ml/s3cfg.erb'),
    }

    file {'/usr/local/bin/model_upload':
        ensure  => file,
        owner   => 'root',
        group   => 'deploy-ml-service',
        mode    => '0550',
        content => template('profile/statistics/explorer/ml/model_upload.sh.erb'),
    }
}