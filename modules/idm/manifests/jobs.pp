# SPDX-License-Identifier: Apache-2.0

class idm::jobs (
    String         $base_dir,
    String         $etc_dir,
    Wmflib::Ensure $present,
    String         $project,
    String         $venv
){

    systemd::timer::job { 'idm-sync-permissions':
        ensure          => absent,
        description     => 'Syncronize permissions from backend to IDM',
        command         => "${venv}/bin/python ${base_dir}/${project}/manage.py systems_sync",
        logging_enabled => true,
        user            => 'www-data',
        environment     => { 'PYTHONPATH' => $etc_dir, 'DJANGO_SETTINGS_MODULE' =>'settings' },
        interval        => { 'start' => 'OnCalendar', 'interval' => '0/1:00:00'},
    }

    systemd::service { 'rq-idm':
        ensure  => $present,
        content => file('idm/rq-idm.service')
    }

    profile::auto_restarts::service {'rq-idm':
        ensure => $present,
    }
}
