# SPDX-License-Identifier: Apache-2.0


# Recursively remove old files from a directory, where 'old' and 'directory'
#  are defined in hiera. This was initially created to clean up
#  old files on the PAWS nfs share with the following args:
#
# profile::wmcs::daily_file_cleanup::trash_path: /srv/paws/files-to-remove
# profile::wmcs::daily_file_cleanup::user_home_dir: /srv/paws/project/paws/userhomes
# profile::wmcs::daily_file_cleanup::age_in_days: 21
#
#
class profile::wmcs::nfs::daily_file_cleanup(
    Stdlib::Unixpath $trash_path = lookup('profile::wmcs::daily_file_cleanup::trash_path'),
    Stdlib::Unixpath $user_home_dir = lookup('profile::wmcs::daily_file_cleanup::user_home_dir'),
    Integer          $age_in_days  = lookup('profile::wmcs::daily_file_cleanup::age_in_days'),
) {

    file { '/usr/local/sbin/scan-and-shrink':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
        source => 'puppet:///modules/profile/wmcs/nfs/scan-and-shrink.py';
    }

    systemd::timer::job { 'scan_and_move_large_files':
        ensure          => present,
        description     => 'Moves large files via scan-and-shrink',
        command         => "/usr/local/sbin/scan-and-shrink --dry-run --scanpath ${user_home_dir} --trashpath ${trash_path}",
        interval        => {
          'start'    => 'OnCalendar',
          'interval' => '*-*-* 13:00:00',
        },
        logging_enabled => true,
        user            => 'root',
    }
    systemd::timer::job { 'daily_file_cleanup':
        ensure          => present,
        description     => "Delete files older than ${age_in_days} from ${trash_path}",
        command         => "/usr/bin/find ${trash_path} -mindepth 1 -mtime +${age_in_days} -delete",
        interval        => {
          'start'    => 'OnCalendar',
          'interval' => '*-*-* 1:00:00',
        },
        logging_enabled => true,
        user            => 'root',
    }
}
