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
#
class base::debdeploy (
  Optional[Array[Stdlib::Unixpath]] $exclude_mounts = [],
) {
    $config = {
      'exclude_mounts' => $exclude_mounts,
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
