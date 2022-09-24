# SPDX-License-Identifier: Apache-2.0
class role::wmcs::toolforge::grid::bastion {
    system::role { $name:
        description => 'Toolforge bastion (with Grid Engine access)'
    }

    include profile::toolforge::base
    include profile::toolforge::apt_pinning

    include profile::toolforge::bastion
    include profile::toolforge::bastion::resourcecontrol

    include profile::toolforge::grid::base
    include profile::toolforge::grid::bastion
    include profile::toolforge::grid::submit_host
    include profile::toolforge::grid::sysctl

    include profile::block_local_crontabs
    include profile::toolforge::automated_tests
    include profile::wmcs::dologmsg
}
