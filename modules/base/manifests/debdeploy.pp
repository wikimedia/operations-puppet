# == Class: base::debdeploy
#
# debdeploy, used to rollout software updates. Updates are initiated via
# the debdeploy tool on the Cumin master(s)
#
# == Parameters:
#[*exclude_mounts*]
#  debdeploy and wmf-auto-restarts use lsof to detect programs running
#  outdated libraries (i.e. missing a restart after an upgrade of the
#  library). This option can specify mount points which should be excluded
#  from the scanning process. Typical reasons to exclude a directory would
#  be e.g. a mount point which only contains data and does not contain any
#  executables or mount points on a network share which may not be reliably
#  mounted.
#[*exclude_filesystems*]
#  This option is similar to exclude_mounts however it will exclude any mount
#  points which have been mounted using one of the provided filesystems
#[*filter_services*]
# After a library is upgraded, the "query_restart" option of debdeploy prints a
# list of all processes which need to be restarted to fully effect the security
# update. There are however some services which cannot be restarted without a
# reboot (e.g. dbus or systemd/pid1) and which are ignored for other purposes
# (e.g. a service may link to a feature (and thus loads a library), but we don't
# actually use the functionality.
#
# This variable allows one to configure a hash describing when a daemon should
# not be listed as needing a restart
#
# The syntax is a hash of the form $daemon => [$libaries], whereby $daemon is the
# name of the service as shown in the process list and $libraries a list of
# library sonames. You can either list a group of libraries to ignore or use '*'
# to skip it for all libraries, e.g.
#  $filter_services = {
#    'never_restart' => ['*'] 
#    'never_restart_libssl' => ['libssl']
#    'never_restart_multiple' => ['libssl', 'someotherlib']
#  }
#
class base::debdeploy (
  Optional[Array[Stdlib::Unixpath]]     $exclude_mounts      = [],
  Optional[Array[String]]               $exclude_filesystems = [],
  Optional[Hash[String, Array[String]]] $filter_services     = {},
) {
    $config = {
      'exclude_mounts'      => $exclude_mounts,
      'exclude_filesystems' => $exclude_filesystems,
      'filter_services'     => $filter_services,
    }
    file { '/usr/local/bin/apt-upgrade-activity':
        ensure => present,
        source => 'puppet:///modules/base/apt-upgrade-activity.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/local/sbin/reboot-host':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/base/reboot-host',
    }

    file {'/etc/debdeploy-client':
      ensure  => directory,
    }
    file {'/etc/debdeploy-client/config.json':
      ensure  => file,
      content => $config.to_json_pretty(),
    }
    require_package('debdeploy-client', 'python-dateutil')
}
