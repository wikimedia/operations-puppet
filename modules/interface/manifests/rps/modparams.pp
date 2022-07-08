# SPDX-License-Identifier: Apache-2.0
class interface::rps::modparams {
    include initramfs

    # clean up unused modprobe file
    file { '/etc/modprobe.d/rps.conf':
      ensure => absent,
      notify => Exec['update-initramfs']
    }
}
