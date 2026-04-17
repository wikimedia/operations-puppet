# SPDX-License-Identifier: Apache-2.0

class openstack::nova::scheduler::service::flamingo
{
    package { 'nova-scheduler':
        ensure => 'present',
    }
}
