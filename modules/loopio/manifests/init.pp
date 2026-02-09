# SPDX-License-Identifier: Apache-2.0
# @summary Provide block devices backed by files.

# Useful in testing situations where real block devices need to be simulated,
# for example storage hardware with multiple disks attached.

# Usage:
# Instantiate a device with:
#     loopio::dev { 'name'
#        size => '3G',
#     }
#
# A block device will be present at /dev/loopio/<name> of the specified size.
# Please note that filesystem space will not be actually used until allocated
# (i.e. backing files are sparse)
class loopio::init {
  systemd::unit { 'loopio@':
        ensure  => 'present',
        content => systemd_template('loopio@'),
  }

  file { '/usr/local/sbin/loopio':
      source => 'puppet:///modules/loopio/loopio.sh',
      mode   => '0555',
  }

  file { '/var/lib/loopio':
      ensure => directory,
      mode   => '0644',
  }

  udev::rule { 'loopio':
      source => 'puppet:///modules/loopio/udev.rules',
  }
}
