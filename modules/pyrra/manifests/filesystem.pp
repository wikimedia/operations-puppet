# SPDX-License-Identifier: Apache-2.0
# == Class: pyrra::filesystem
#
# Pyrra filesystem operator and backend for the API.
#
# = Parameters
# [*config_files*] The folder where Pyrra finds the config files to use.
# [*prometheus_folder*] The folder where Pyrra writes the generated Prometheus rules and alerts.

class pyrra::filesystem(
    String $config_files      = '/etc/pyrra/config/*.yaml',
    String $prometheus_folder = '/etc/pyrra/output-rules/',
){

    ensure_packages(['pyrra'])

    $config_folder = dirname($config_files)

    file { [ $prometheus_folder, $config_folder ]:
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    systemd::service { 'pyrra-filesystem':
        ensure         => present,
        restart        => true,
        override       => true,
        content        => systemd_template('pyrra-filesystem'),
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }

}
