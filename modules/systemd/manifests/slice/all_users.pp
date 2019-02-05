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
#
class systemd::slice::all_users (
    String $all_users_slice_config,
) {

    # we need systemd >= 239 for resource control using the user-.slice trick
    # this version is provied in stretch-backports
    apt::pin { 'systemd udev':
        package  => 'systemd udev',
        pin      => 'version 239*',
        priority => '1001',
    }

    $packages = [
        'systemd',
        'udev',
    ]

    package { $packages:
        ensure          => present,
        install_options => ['-t', 'stretch-backports'],
    }

    systemd::unit { 'user-.slice':
        ensure   => present,
        content  => $all_users_slice_config,
        override => true,
    }

    # By default the root user does not have any limitation.
    # Caveat: this does not apply to sudo sessions, that
    # will be limited by the above user-.slice.
    systemd::unit { 'user-0.slice':
        ensure   => present,
        content  => file('systemd/root-slice-resource-control.conf'),
        override => true,
    }
}
