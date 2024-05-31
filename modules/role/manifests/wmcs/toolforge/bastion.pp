# SPDX-License-Identifier: Apache-2.0
class role::wmcs::toolforge::bastion {
    include profile::toolforge::base
    include profile::block_local_crontabs

    include profile::toolforge::bastion
    include profile::toolforge::bastion::resourcecontrol
    include profile::toolforge::bastion::toolforge_cli
    include profile::toolforge::dologmsg
}
