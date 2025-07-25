# SPDX-License-Identifier: Apache-2.0
class profile::openstack::codfw1dev::neutron::metadata_agent(
    $version = lookup('profile::openstack::codfw1dev::version'),
    Stdlib::Fqdn $keystone_api_fqdn = lookup('profile::openstack::codfw1dev::keystone_api_fqdn'),
    $metadata_proxy_shared_secret = lookup('profile::openstack::codfw1dev::neutron::metadata_proxy_shared_secret'),
    $report_interval = lookup('profile::openstack::codfw1dev::neutron::report_interval'),
    ) {

    require ::profile::openstack::codfw1dev::clientpackages
    require ::profile::openstack::codfw1dev::neutron::common
    class {'::profile::openstack::base::neutron::metadata_agent':
        version                      => $version,
        keystone_api_fqdn            => $keystone_api_fqdn,
        metadata_proxy_shared_secret => $metadata_proxy_shared_secret,
        report_interval              => $report_interval,
    }
    contain '::profile::openstack::base::neutron::metadata_agent'

    # In Epoxy this agent is getting stuck intermittently and requiring a manual
    #  restart. I'm pretty sure that the failure is a leak of some sort rather than
    #  randomly timed.
    # While we hope for a proper fix in Flamingo, we're going to just restart
    #  the service once per day.
    $minute = fqdn_rand(59)
    systemd::timer::job { 'restart_metadata_agent':
        ensure      => 'present',
        user        => 'root',
        description => 'Restart neutron metadata service to avoid periodic lockups',
        command     => '/bin/systemctl restart neutron-metadata-agent.service',
        interval    => {'start' => 'OnCalendar', 'interval' => "*-*-* 15:${minute}:00"},
    }
}
