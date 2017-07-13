# == Class: kmod
#
# Linux Kernel module handling
#
class kmod {
    if os_version('ubuntu == trusty') {
        # This directory is shipped by systemd, but trusty's upstart job for
        # kmod also parses /etc/modules-load.d/ (but doesn't create the
        # directory).
        file { '/etc/modules-load.d/':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }
}
