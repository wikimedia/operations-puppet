# SPDX-License-Identifier: Apache-2.0
# automate subscribing users to certain lists
# intoduced for steward-related lists (T351202)
#
class profile::lists::automation (
    Stdlib::Unixpath $data_dir = lookup('profile::lists::automation::data_dir', {default_value => '/srv/exports'}),
    Stdlib::Host $lists_host = lookup('lists_primary_host'),
    Stdlib::Host $stewards_host = lookup('stewards_primary_host'),
    Wmflib::Ensure $ensure = lookup('profile::lists::automation::ensure', { default_value => 'absent' })
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

    systemd::timer::job { 'stewards_subscriber_list_sync':
        ensure       => $ensure,
        user         => 'root',
        description  => 'sync stewards lists members with imported subscriber data',
        command      => @(CMD/L),
          "/usr/bin/mailman-wrapper syncmembers -n\
          /${data_dir}/mailman_list/lists.wikimedia.org/stewards-l\
          stewards-l@lists.wikimedia.org\"
          | CMD
        interval     => {'start' => 'OnCalendar', 'interval' => 'hourly'},
        logfile_name => 'stewards_subscriber_list_sync.log',
    }
}
