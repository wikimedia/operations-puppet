# SPDX-License-Identifier: Apache-2.0
# automate subscribing users to certain lists
# introduced for steward-related lists (T351202)
#
class profile::lists::automation (
    Stdlib::Unixpath $data_dir = lookup('profile::lists::automation::data_dir', {default_value => '/srv/exports'}),
    Stdlib::Host $lists_host = lookup('lists_primary_host'),
    Stdlib::Host $stewards_host = lookup('stewards_primary_host'),
    Wmflib::Ensure $ensure = lookup('profile::lists::automation::ensure', { default_value => 'absent' }),
    Array[String] $lists_to_sync_dry = lookup('profile::lists::automation::lists_to_sync_dry_run'),
    Array[String] $lists_to_sync_wet = lookup('profile::lists::automation::lists_to_sync_wet_run'),
){

    wmflib::dir::mkdir_p($data_dir, {
        mode  => '0775',
    })

    systemd::timer::job { 'stewards_subscriber_data_sync':
        ensure      => $ensure,
        user        => 'root',
        description => 'copy exported stewards subscriber data from primary steward machine',
        command     => "/usr/bin/rsync --address ${lists_host} -ap rsync://${stewards_host}/steward-data-export-dir ${data_dir}",
        interval    => {'start' => 'OnCalendar', 'interval' => 'hourly'},
    }

    $list_sync_ensure = $lists_host ? {
        $::fqdn => 'present',
        default => 'absent',
    }

    each($lists_to_sync_dry) |$list_name| {
        mailman3::sync_list_members { "sync-members-${list_name}":
            ensure    => $list_sync_ensure,
            list_name => $list_name,
            dry_run   => 'y',
        }
    }

    each($lists_to_sync_wet) |$list_name| {
        mailman3::sync_list_members { "sync-members-${list_name}":
            ensure    => $list_sync_ensure,
            list_name => $list_name,
            dry_run   => 'n',
        }
    }
}
