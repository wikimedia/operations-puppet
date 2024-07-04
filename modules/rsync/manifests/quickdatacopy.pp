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
# [*dest_host*] What machine(s) are we copying data to. Can be a single fqdn or an array of fqdns
#
# [*module_path*] What path are we giving to rsync as the docroot for syncing from
#
# [*file_path*] What file within that document root do we need? (currently not used)
#
# [*auto_sync*] Whether to also have a periodic job to automatically sync data or not (default: true)
#
# [*ensure*] The usual meaning, set to absent to clean up when done
#
# [*bwlimit*] Optionally limit the maxmium bandwith used
#
# [*exclude*] Optionally ignore certain files at the source. Skip them during transfer.
#             A single string passed to rsync's --exclude parameter.
#             Can match a single file, multiple files/directories or use wildcards.
#
# [*delete*] Optionally let rsync delete files on the _destination_ side if they
#            do not exist on the source.
#            To create exact mirrors instead of having old files that are deleted
#            on the source pile up on the destination(s).
#
# [*chown*] Optionally set the USER:GROUP mapping.
#
# [*progress*] If $progress is true, show progress during transfer
#
# [*server_uses_stunnel*] For TLS-wrapping rsync.
#
# [*auto_interval*] If $auto_sync is true, the interval to sync at. Defaults to every 10 minutes. See
#                   systemd::timer::job's $interval parameter and Systemd::Timer::Schedule for more details.
# [*ignore_missing_file_errors*] If provided, it will specify a SuccessExitStatus of 24 to the systemd unit file.
#                                This allows a non-zero exit code that occurs following a "some files vanished
#                                before they could be transferred (code 24)" error to be considered a success.
# [*foo*] If provided,  it will specify a SuccessExitStatus of 24 to the systemd unit file.
#                                This allows a non-zero exit code that occurs following a "some files vanished
#                                before they could be transferred (code 24)" error to be considered a success.
define rsync::quickdatacopy(
  Stdlib::Fqdn $source_host,
  Variant[
      Stdlib::Host,
      Array[Stdlib::Host, 1]] $dest_host,
  Stdlib::Unixpath $module_path,
  Optional[Stdlib::Unixpath] $file_path = undef,
  Boolean $auto_sync = true,
  Wmflib::Ensure $ensure = present,
  Optional[Integer] $bwlimit = undef,
  Optional[String] $exclude = undef,
  Optional[Boolean] $delete = false,
  Boolean $server_uses_stunnel = false,
  Optional[String] $chown = undef,
  Optional[Boolean] $progress = false,
  Variant[
      Systemd::Timer::Schedule,
      Array[Systemd::Timer::Schedule, 1]] $auto_interval = {'start' => 'OnCalendar', 'interval' => '*-*-* *:00/10:00'}, # every 10 min
  Boolean $ignore_missing_file_errors = false,
  Optional[Hash] $ssl_paths = undef,
  ) {
      if ($title =~ /\s/) {
          fail('the title of rsync::quickdatacopy must not include whitespace')
      }

      ensure_packages(['rsync'])

      $dest_hosts = $dest_host ? {
          Stdlib::Fqdn => [$dest_host],
          default      => $dest_host,
      }

      if $source_host == $::fqdn {

          include rsync::server

          if $server_uses_stunnel {
              if ! defined(Class['rsync::server::stunnel']) {
                  class { 'rsync::server::stunnel':
                      ssl_paths => $ssl_paths,
                  }
              }
          }

          rsync::server::module { $title:
              ensure        => $ensure,
              read_only     => 'yes',
              path          => $module_path,
              hosts_allow   => $dest_hosts,
              auto_firewall => true,
          }
      }
      $_bwlimit = $bwlimit ? {
          undef   => '',
          default => "--bwlimit=${bwlimit}",
      }
      $_exclude = $exclude ? {
          undef   => '',
          default => "--exclude '${exclude}' ",
      }
      $ssl_wrapper_path = "/usr/local/sbin/sync-${title}-ssl-wrapper"
      $_rsh = $server_uses_stunnel ? {
          false   => '',
          default => "--rsh ${ssl_wrapper_path}"
      }
      $_delete = $delete ? {
          true    => ' --delete ',
          default => ' '
      }
      $_chown = $chown ? {
          undef   => '',
          default => "--chown=${chown}",
      }
      $_progress = $progress ? {
          true    => '--progress',
          default => ''
      }

      $is_dest_host = $facts['networking']['fqdn'] in $dest_hosts

      if $is_dest_host {

          if $server_uses_stunnel {
              ensure_packages(['stunnel4'])

              file { $ssl_wrapper_path:
                  ensure  => $ensure,
                  owner   => 'root',
                  group   => 'root',
                  mode    => '0755',
                  content => template('rsync/quickdatacopy-ssl-wrapper.erb'),
              }
          }
          $quickdatacopy = @("SCRIPT")
          #!/bin/sh
          /usr/bin/rsync ${_rsh}${_delete}-a ${_bwlimit} ${_chown} ${_progress} ${_exclude}rsync://${source_host}/${title} ${module_path}/
          | SCRIPT

          file { "/usr/local/sbin/sync-${title}":
              ensure  => $ensure,
              owner   => 'root',
              group   => 'root',
              mode    => '0755',
              content => $quickdatacopy,
          }
      }

      # Manage the timer entry on both source and dest host.
      # Default to 'absent' to handle proper cleanup when 'flipping' replication
      # (i.e. swap source and dest hosts)

      if $auto_sync and $is_dest_host {
          $timer_ensure = $ensure
      } else {
          $timer_ensure = 'absent'
      }

      $success_exit_statuses = $ignore_missing_file_errors ? {
            true => [24],
            false => [],
      }

      systemd::timer::job { "rsync-${title}":
          ensure              => $timer_ensure,
          description         => 'Transfer data periodically between hosts',
          user                => 'root',
          command             => "/usr/local/sbin/sync-${title}",
          interval            => $auto_interval,
          success_exit_status => $success_exit_statuses
      }
}
