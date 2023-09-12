# SPDX-License-Identifier: Apache-2.0

class idm::jobs (
    String         $base_dir,
    String         $etc_dir,
    Wmflib::Ensure $present,
    String         $project,
    String         $venv,
    String         $user
){
    systemd::timer::job { 'sync_bitu_username_block':
        ensure      => $present,
        description => 'Update blocklist with data from meta and wikitech',
        user        => $user,
        command     => "${base_dir}/venv/bin/python ${base_dir}/${project}/manage.py blocklist_wmf",
        environment => {
            'PYTHONPATH'             => "${etc_dir}:\$PYTHONPATH",
            'DJANGO_SETTINGS_MODULE' => 'settings'},
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 06:00'},
    }

    systemd::timer::job { 'expire_bitu_signups':
        ensure      => $present,
        description => 'Delete signup requests that have not been activated for 5 days',
        user        => $user,
        command     => "${base_dir}/venv/bin/python ${base_dir}/${project}/manage.py deleteexpired 5",
        environment => {
            'PYTHONPATH'             => "${etc_dir}:\$PYTHONPATH",
            'DJANGO_SETTINGS_MODULE' => 'settings'},
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 07:00'},
    }

}
