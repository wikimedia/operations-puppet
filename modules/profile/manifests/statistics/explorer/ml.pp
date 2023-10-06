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
    ensure_packages([
      's3cmd',
      # Packages used by the Content Translation team
      # to test a replacement of NLLB on AMD GPUs.
      'ocl-icd-libopencl1',
      'ocl-icd-opencl-dev'])

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

    # Allow the ML team admins only to work on the wmf-ml-models
    # directory on each statistics explorer node. This will add extra safety
    # fences to avoid malicious/accidental tampering of model objects
    # published for the outside community.
    file { '/srv/published/wmf-ml-models':
        ensure  => directory,
        mode    => '0775',
        owner   => 'root',
        group   => 'ml-team-admins',
        require => File['/srv/published'],
    }
}
