# Designate provides DNSaaS services for OpenStack
# https://wiki.openstack.org/wiki/Designate

class openstack::designate::service (
    $openstack_version=$::openstack::version,
    $active_server,
    $nova_controller,
    $keystone_host,
    $keystoneconfig,
    $designateconfig,
)
    {

    require openstack::repo

    $keystone_host_ip   = ipresolve($keystone_host,4)
    $nova_controller_ip = ipresolve($nova_controller)

    require_package(
        'python-designateclient',
        'designate-sink',
        'designate-common',
        'designate',
        'designate-api',
        'designate-doc',
        'designate-central',
        'python-nova-ldap',
        'python-novaclient',
        'python-nova-fixed-multi'
    )

    file {
        '/etc/designate/designate.conf':
            content => template("openstack/${openstack_version}/designate/designate.conf.erb"),
            owner   => designate,
            group   => designate,
            notify  => Service['designate-api','designate-sink','designate-central','designate-mdns','designate-pool-manager'],
            require => Package['designate-common'],
            mode    => '0440';
        '/etc/designate/api-paste.ini':
            content => template("openstack/${$openstack_version}/designate/api-paste.ini.erb"),
            owner   => 'designate',
            group   => 'designate',
            notify  => Service['designate-api','designate-sink','designate-central'],
            require => Package['designate-api'],
            mode    => '0440';
        '/etc/designate/policy.json':
            source  => "puppet:///modules/openstack/${$openstack_version}/designate/policy.json",
            owner   => 'designate',
            group   => 'designate',
            notify  => Service['designate-api','designate-sink','designate-central'],
            require => Package['designate-common'],
            mode    => '0440';
        '/etc/designate/rootwrap.conf':
            source => "puppet:///modules/openstack/${$openstack_version}/designate/rootwrap.conf",
            owner   => 'root',
            group   => 'root',
            notify  => Service['designate-api','designate-sink','designate-central'],
            require => Package['designate-common'],
            mode    => '0440';
    }

    # These would be automatically included in a correct designate package...
    # probably this can be ripped out in Liberty.
    file { '/etc/logrotate.d/designate-mdns':
        ensure => present,
        source => 'puppet:///modules/openstack/designate-mdns.logrotate',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    file { '/etc/logrotate.d/designate-pool-manager':
        ensure => present,
        source => 'puppet:///modules/openstack/designate-pool-manager.logrotate',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    file { '/var/lib/designate/.ssh/':
        ensure => directory,
        owner  => 'designate',
        group  => 'designate',
    }

    file { '/var/lib/designate/.ssh/id_rsa':
        owner   => 'designate',
        group   => 'designate',
        mode    => '0400',
        content => secret('ssh/puppet_cert_manager/cert_manager')
    }

    # include rootwrap.d entries

    if $::fqdn == $active_server {
        service {'designate-api':
            ensure  => running,
            require => Package['designate-api'];
        }

        service {'designate-sink':
            ensure  => running,
            require => Package['designate-sink'];
        }

        service {'designate-central':
            ensure  => running,
            require => Package['designate-central'];
        }

        # In the perfect future when the designate packages set up
        #  an init script for this, some of this can be removed.
        base::service_unit { ['designate-pool-manager', 'designate-mdns']:
            ensure  =>  present,
            upstart =>  true,
            require =>  Package['designate'],
        }

        nrpe::monitor_service { 'check_designate_sink_process':
            description  => 'designate-sink process',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-sink'",
        }
        nrpe::monitor_service { 'check_designate_api_process':
            description  => 'designate-api process',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-api'",
        }
        nrpe::monitor_service { 'check_designate_central_process':
            description  => 'designate-central process',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-central'",
        }
        nrpe::monitor_service { 'check_designate_mdns':
            description  => 'designate-mdns process',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-mdns'",
        }
        nrpe::monitor_service { 'check_designate_pool-manager':
            description  => 'designate-pool-manager process',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-pool-manager'",
        }

    } else {
        service {'designate-api':
            ensure  => stopped,
            require => Package['designate-api'];
        }

        service {'designate-sink':
            ensure  => stopped,
            require => Package['designate-sink'];
        }

        service {'designate-central':
            ensure  => stopped,
            require => Package['designate-central'];
        }

        base::service_unit { ['designate-pool-manager', 'designate-mdns']:
            upstart        =>  true,
            require        =>  Package['designate'],
            service_params => {
            # lint:ignore:ensure_first_param
                ensure => stopped
            # lint:endignore
            },
        }
    }
}
