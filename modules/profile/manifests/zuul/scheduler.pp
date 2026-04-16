# SPDX-License-Identifier: Apache-2.0
# new zuul (T405118) - scheduler
class profile::zuul::scheduler(
    String $image_version = lookup('profile::zuul::scheduler::image_version'),
    Wmflib::Ensure $service_ensure = lookup('profile::zuul::scheduler::service_ensure'),
    String $tenant_config_source = lookup('profile::zuul::scheduler::tenant_config_source'),
    Optional[Stdlib::HTTPUrl] $http_proxy = lookup('profile::zuul::scheduler::http_proxy'),
    Array[Stdlib::Host] $no_proxy = lookup('profile::zuul::scheduler::no_proxy'),
){

    $host_ip = $facts['networking']['ip']

    file { '/etc/zuul/tenants.yaml':
        ensure => file,
        owner  => 'zuul',
        group  => 'zuul',
        mode   => '0440',
        source => $tenant_config_source,
    }

    systemd::service { 'zuul-scheduler':
        ensure    => $service_ensure,
        content   => systemd_template('zuul-scheduler'),
        require   => [
            File['/etc/zuul/zuul.conf'],
            File['/etc/zuul/tenants.yaml'],
        ],
        subscribe => File['/etc/zuul/zuul.conf'],
    }

    exec { 'zuul_scheduler_reconfigure':
        command     => '/usr/bin/docker exec zuul-scheduler zuul-scheduler smart-reconfigure',
        refreshonly => true,
        subscribe   => File['/etc/zuul/tenants.yaml'],
        require     => [
            File['/etc/zuul/tenants.yaml'],
            Systemd::Service['zuul-scheduler'],
        ],
    }
}
