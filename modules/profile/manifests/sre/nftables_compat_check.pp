# SPDX-License-Identifier: Apache-2.0
# @summary Provides a script to assess whether a host is compatible with nftables
class profile::sre::nftables_compat_check () {

    file { '/usr/local/bin/nftables-compat-check.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/sre/nftables-compat-check.py',
    }
}
