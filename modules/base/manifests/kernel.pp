# == Class: base::kernel
#
# Settings related to the Linux kernel (currently only blacklisting
# risky kernel modules)
#
class base::kernel
{
    file { '/etc/modprobe.d/blacklist-wmf.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/kernel/blacklist-wmf.conf',
    }

    if (versioncmp($::kernelversion, '4.4') >= 0) {
        file { '/etc/modprobe.d/blacklist-linux44.conf':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/base/kernel/blacklist-linux44.conf',
        }
    }
}
