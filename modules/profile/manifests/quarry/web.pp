# SPDX-License-Identifier: Apache-2.0
# = Class: profile::quarry::web
#
# This class sets up a web frontend for Quarry, which lets
# users run SQL queries against LabsDB.
# Deployment is handled using fabric
class profile::quarry::web(
    Stdlib::Unixpath $clone_path = lookup('profile::quarry::base::clone_path'),
    Stdlib::Unixpath $venv_path  = lookup('profile::quarry::base::venv_path'),
) {
    require ::profile::quarry::base

    $metrics_dir = '/run/quarry-metrics'

    # Needed for prometheus exporter to share metrics between uwsgi processes
    file { $metrics_dir:
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
    }
    systemd::tmpfile { 'quarry-shared-metrics':
        content => "d ${metrics_dir} 0755 www-data www-data",
    }

    uwsgi::app { 'quarry-web':
        require            => Git::Clone['quarry'],
        settings           => {
            uwsgi => {
                'plugins'   => 'python3',
                'socket'    => '/run/uwsgi/quarry-web.sock',
                'wsgi-file' => "${clone_path}/quarry.wsgi",
                'master'    => true,
                'processes' => 8,
                'chdir'     => $clone_path,
                'venv'      => $venv_path,
                'env'       => [
                    # fix prometheus exporter for multiple uwsgi processes/workers
                    "PROMETHEUS_MULTIPROC_DIR=${metrics_dir}",
                ],
            },
        },
        extra_systemd_opts => {
            'ExecStartPre' => [
                # Clear out metrics caches for previous runs
                "/bin/bash -c \"rm -rf ${metrics_dir}/*\"",
            ],
        },
    }

    nginx::site { 'quarry-web-nginx':
        require => Uwsgi::App['quarry-web'],
        content => template('quarry/quarry-web.nginx.erb'),
    }

    # Install tmpreaper to clean up tempfiles leaked by xlsxwriter
    #  T238375
    package { 'tmpreaper':
        ensure => 'installed',
    }
    file { '/etc/tmpreaper.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/profile/quarry/tmpreaper.conf',
        require => Package['tmpreaper'],
    }
}
