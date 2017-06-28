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
# [*module_path*] What path are we giving to rsync as the docroot for syncing from
#
# [*file_path*] What file within that document root do we need?
#
# [*ensure*] The usual meaning, set to absent to clean up when done
#
define rsync::quickdatacopy(
  $source_host,
  $module_path,
  $file_path = '*',
  $ensure = present,
  ) {

      include rsync::server

      ferm::service { $title:
          ensure => $ensure,
          proto  => 'tcp',
          port   => 873,
          srange => "@resolve(${source_host})",
      }

      rsync::server::module { $title:
          ensure    => $ensure,
          read_only => 'yes',
          path      => $module_path,
      }

      file { "/usr/local/sbin/${title}":
          ensure  => $ensure,
          owner   => 'root',
          group   => 'root',
          mode    => '0755',
          content => template("rsync/${title}.erb"),
      }

      if $source_host != $::fqdn {
          cron { 'sync-rsync-data':
              ensure  => $ensure,
              minute  => '*/10',
              command => "/usr/local/sbin/${title} >/dev/null 2>&1",
          }
      }
}
