# SPDX-License-Identifier: Apache-2.0
#
# CI profiles need adjustements to be made based on whether the host is the
# primary one. They can thus use:
#
#    include profile::ci
#    $profile::ci::manager
#
# Which gives them a Boolean to use in conditional statements.
#
# @summary profile to set some global parameters
# @param manager_host the fqdn of the manager host
class profile::ci (
    Stdlib::Fqdn $manager_host = lookup('profile::ci::manager_host')
) {
    $manager = $manager_host == $facts['networking']['fqdn']
}
