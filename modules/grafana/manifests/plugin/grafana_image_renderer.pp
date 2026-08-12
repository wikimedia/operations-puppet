# SPDX-License-Identifier: Apache-2.0
#
# deploy the grafana-image-renderer plugin as a sidecar service
# https://gitlab.wikimedia.org/repos/sre/grafana-image-renderer/-/tree/bookworm-wikimedia

class grafana::plugin::grafana_image_renderer (
    Wmflib::Ensure    $ensure             = present,
    Stdlib::Unixpath  $grafana_config_dir = '/etc/grafana',
    Stdlib::Unixpath  $chromium_path = '/usr/bin/chromium',
) {

    package { 'grafana-image-renderer':
        ensure => $ensure,
    }

    package { 'chromium':
        ensure => $ensure,
    }

    file { "${grafana_config_dir}/grafana-image-renderer.conf":
        ensure  => stdlib::ensure($ensure, 'file'),
        owner   => 'grafana',
        group   => 'grafana',
        content => epp('grafana/plugin/grafana-image-renderer/grafana-image-renderer.conf.epp', {
            'chromium_path' => $chromium_path,
        }),
    }

    $service_enable = $ensure ? {
        present => true,
        absent => false,
    }

    service { 'grafana-image-renderer':
        ensure => stdlib::ensure($ensure, 'service'),
        enable => $service_enable,
    }

    profile::auto_restarts::service { 'grafana-image-renderer':
        ensure => $ensure,
    }

}
