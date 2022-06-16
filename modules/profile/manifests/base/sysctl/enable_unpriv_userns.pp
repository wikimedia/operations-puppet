# SPDX-License-Identifier: Apache-2.0
# == Class profile::base::sysctl::enable_unpriv_userns
#
# Allow unprivileged user namespaces on a server.
#
# This is a Debian specific kernel hardening setting. It doesn't exist in vanilla Linux.
#
class profile::base::sysctl::enable_unpriv_userns(
){

    sysctl::parameters { 'unprivileged_userns_clone':
        values   => {
            'kernel.unprivileged_userns_clone' => 1,
        },
        priority => 70,
    }
}
