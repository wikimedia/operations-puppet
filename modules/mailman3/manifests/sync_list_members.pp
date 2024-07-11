# SPDX-License-Identifier: Apache-2.0
# A defined type to sync the members of a mailman3 list.
#
# Ensures that actual members of a given list are in sync
# with an externally provided list of people who should be members.
#
# Both ADDs and DELetes members as needed to achieve sync status.
#
# list_name - name of the mailing list, the only required parameter
# list_domain - FQDN of the lists server, defaults to WMF server
# ensure - the usual parameter to enable or disable a resource
# dry_run -  if yes, don't actually sync data and just show what would happen
# interval - how often to run the sync command, defaults to hourly
# data_dir - directory to read subscriber data from, defaults to /srv/exports
#
define mailman3::sync_list_members(
    String $list_name,
    String $list_domain = 'lists.wikimedia.org',
    Wmflib::Ensure $ensure = 'present',
    Enum['n','y'] $dry_run = 'y',
    String $interval = 'hourly',
    Stdlib::Unixpath $data_dir = '/srv/exports',
){

    # YES to a dry-run means NOT running it
    # NO to a dry-run means to ACTUALLY do it
    # -n means --no-change
    $dry_run_param = $dry_run ? {
        'y' => '-n',
        'n' => '',
    }

    systemd::timer::job { "sync-list-members-${list_name}":
      ensure       => $ensure,
      user         => 'root',
      description  => "sync members of list '${list_name}' with imported subscriber data",
      command      => @("CMD"/L),
          /usr/bin/mailman-wrapper syncmembers ${dry_run_param}\
          ${data_dir}/mailman_list/${list_domain}/${list_name} \
          ${list_name}@${list_domain}\
          | CMD
      interval     => {
          'start'    => 'OnCalendar',
          'interval' => $interval,
      },
      logfile_name => "sync-list-members-${list_name}.log",
    }
}
