# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::paws::common (
) {
    motd::script { 'paws-banner':
        ensure => present,
        source => 'puppet:///modules/profile/wmcs/paws/paws-banner.sh',
    }
}
