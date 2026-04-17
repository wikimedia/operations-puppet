# SPDX-License-Identifier: Apache-2.0

class openstack::nova::conductor::service::flamingo
{
    package { 'nova-conductor':
        ensure => 'present',
    }
}
