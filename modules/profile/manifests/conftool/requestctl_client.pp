# SPDX-License-Identifier: Apache-2.0
# @summary profile to install conftool requestctl plugin
# @param conftool_prefix the conftool prefix
class profile::conftool::requestctl_client(
        String $conftool_prefix = lookup('conftool_prefix'),
) {
    require profile::conftool::client
    ensure_packages(['python3-conftool-requestctl'])
    # Create the test directory
    file { ['/var/lib/requestctl', '/var/lib/requestctl/tests']:
        ensure => directory,
    }
    file { '/usr/local/bin/requestctl-checkip':
        ensure => file,
        owner  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/conftool/requestctl_checkip.py',
    }
    # TODO: add an alert if there are uncommitted changes
}
