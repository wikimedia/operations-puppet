# == Class: base::kernel
#
# Settings related to the Linux kernel (currently only blacklisting
# risky kernel modules and adding /etc/modules-load.d/ on Trusty)
#
class base::kernel
{
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

    # This section is for blacklisting modules per server model.
    # It was originally started for acpi_pad issues on R320 (T162850)
    # but is meant to be extended as needed.
    case $::productname {
      'PowerEdge R320': {
        file { '/etc/modprobe.d/blacklist-r320.conf':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/base/kernel/blacklist-r320.conf',
        }
      }
      default: {}
    }

    # By default trusty allows the creation of user namespaces by unprivileged users
    # (Debian defaulted to disallowing these since the feature was introduced for security reasons)
    # Unprivileged user namespaces are not something we need in general (and especially
    # not in trusty where support for namespaces is incomplete) and was the source for
    # several local privilege escalation vulnerabilities. Fortunately the 3.13.0-91 release
    # introduced a backport of the Debian patch allowing to disable the creation of user
    # namespaces via a sysctl. There's a few servers we haven't been able to migrate to
    # that kernel for technical reasons, so make the creation of the sysctl dependant on
    # the kernel release.
    if os_version('ubuntu == trusty') and (versioncmp($::kernelrelease, '3.13.0-91') >= 0) {
        sysctl::parameters { 'disable-unprivileged-user-namespaces':
            values => {
                'kernel.unprivileged_userns_clone' => 0,
            },
        }
    }
}

define base::kernel::module($ensure=present) {
    case $ensure {
        'present': {
            file { "/etc/modules-load.d/${name}.conf":
                ensure  => present,
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => "${name}\n",
                require => File['/etc/modules-load.d/'],
                notify  => Exec["modprobe ${name}"],
            }

            exec { "modprobe ${name}":
                unless => "/bin/lsmod | /bin/grep -q '^${name}'",
            }
        }
        'absent': {
            file { "/etc/modules-load.d/${name}.conf":
                ensure => absent,
                notify => Exec["modprobe -r ${name}"],
            }

            exec { "modprobe -r ${name}":
                onlyif => "/bin/lsmod | /bin/grep -q '^${name}'",
            }
        }
    }
}
