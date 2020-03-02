# == Class systemd::slice::all_users
#
# Sets up a Systemd user-.slice configuration meant
# to set up basic user limits for hosts shared by multiple
# users (like analytics crunching machines, toolforge hosts, etc..)
#
# == Parameters:
#
# [*all_users_slice_config*]
#   Content of config file of the user-.slice unit.
#   The limits will be enforced to every user slice
#   separately (so not a global limit).
#   Default: undef
#
# [*all_users_global_slice_config*]
#   Content of config file of the user.slice unit.
#   The limits will be enforced to all the processes
#   under the user.slice, so a global limit.
#   Default: undef
#
class systemd::slice::all_users (
    Optional[String] $all_users_slice_config = undef,
    Optional[String] $all_users_global_slice_config = undef,
    Enum['present','latest'] $pkg_ensure = 'present',
) {

    $systemd_packages = [
        'systemd',
        'systemd-sysv',
        'udev',
        'libsystemd0',
        'libpam-systemd',
    ]

    if os_version('debian == stretch') {
        # we need systemd >= 239 for resource control using the user-.slice trick
        # this version or higher is provided in stretch-backports

        apt::pin { 'systemd_239_slice_all_users':
            package  => join($systemd_packages, ' '),
            pin      => 'release a=stretch-backports',
            priority => '1001',
        }
        package { $systemd_packages:
            ensure          => $pkg_ensure,
            install_options => ['-t', 'stretch-backports'],
            require         => Apt::Pin['systemd_239_slice_all_users'],
        }
    } elsif os_version('debian >= buster') {
        package { $systemd_packages:
            ensure => present,
        }
    } else {
        fail('systemd::slice::all_users requires Debian >= Stretch')
    }

    if $all_users_slice_config {
        systemd::unit { 'user-.slice':
            ensure   => present,
            content  => $all_users_slice_config,
            override => true,
            require  => Package[$systemd_packages],
        }
    }

    if $all_users_global_slice_config {
        systemd::unit { 'user.slice':
            ensure   => present,
            content  => $all_users_global_slice_config,
            override => true,
            require  => Package[$systemd_packages],
        }
    }

    # By default the root user does not have any limitation.
    # Caveat: this does not apply to sudo sessions, that
    # will be limited by the above user-.slice.
    # Caveat 2: limits for user.slice are also applied to
    # user-0.slice.
    systemd::unit { 'user-0.slice':
        ensure   => present,
        content  => file('systemd/root-slice-resource-control.conf'),
        override => true,
    }
}
