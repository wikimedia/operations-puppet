# SPDX-License-Identifier: Apache-2.0

class idm::jobs (
    Wmflib::Ensure $present,
    String         $user
){
    systemd::timer::job { 'sync_bitu_username_block':
        ensure      => $present,
        description => 'Update blocklist with data from meta and wikitech',
        user        => $user,
        command     => '/usr/bin/bitu blocklist_wmf',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 06:00'},
    }

    systemd::timer::job { 'expire_bitu_signups':
        ensure      => $present,
        description => 'Delete signup requests that have not been activated for 5 days',
        user        => $user,
        command     => '/usr/bin/bitu deleteexpired 5',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 07:00'},
    }
}
