# == Class rsync::quickdatacopy
#
# This class sets up a very quick and dirty rsync server. It's designed to be
# used for copying data between two (or more) machines, mostly for migrations.
#
# Since it's meant to be used for data migrations, it assumes the source and
# destination locations are the same
#
# === Parameters
#
# [*source_host*] What machine are we copying data from
#
# [*dest_host*] What machine are we copying data to
#
# [*module_path*] What path are we giving to rsync as the docroot for syncing from
#
# [*file_path*] What file within that document root do we need? (currently not used)
#
# [*auto_sync*] Whether to also have a cronjob that automatically syncs data or not (default: true)
#
# [*ensure*] The usual meaning, set to absent to clean up when done
#
define rsync::quickdatacopy(
  $source_host,
  $dest_host,
  $module_path,
  $file_path = '*',
  $auto_sync = true,
  $ensure = present,
  ) {

      if $source_host == $::fqdn {

          include rsync::server

          ferm::service { $title:
              ensure => $ensure,
              proto  => 'tcp',
              port   => 873,
              srange => "@resolve(${dest_host})",
          }

          rsync::server::module { $title:
              ensure    => $ensure,
              read_only => 'yes',
              path      => $module_path,
          }
      }

      if $dest_host == $::fqdn {

          file { "/usr/local/sbin/${title}":
              ensure  => $ensure,
              owner   => 'root',
              group   => 'root',
              mode    => '0755',
              content => template('rsync/quickdatacopy.erb'),
          }

          if $auto_sync {
              $cron_ensure = $ensure
          } else {
              $cron_ensure = 'absent'
          } 
          cron { 'sync-rsync-data':
              ensure  => $cron_ensure,
              minute  => '*/10',
              command => "/usr/local/sbin/${title} >/dev/null 2>&1",
          }
      }
}
