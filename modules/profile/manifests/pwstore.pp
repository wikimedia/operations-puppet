# SPDX-License-Identifier: Apache-2.0
# == Class profile::pwstore
#
# Profile which designates that a pwstore repository is hosted.
#
class profile::pwstore(
) {
    # Base directory for the pwstore repository
    file { '/srv/pwstore':
        ensure => directory,
        owner  => 'root',
        group  => 'ops',
        mode   => '0770',
    }
}
