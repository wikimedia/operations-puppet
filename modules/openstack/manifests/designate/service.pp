# Designate provides DNSaaS services for OpenStack
# https://wiki.openstack.org/wiki/Designate

class openstack::designate::service(
    $active,
    $version,
    $designate_host,
    $db_user,
    $db_pass,
    $db_host,
    $db_name,
    $domain_id_internal_forward,
    $domain_id_internal_reverse,
    $pool_manager_db_name,
    $puppetmaster_hostname,
    $nova_controller,
    $ldap_user_pass,
    $pdns_db_user,
    $pdns_db_pass,
    $pdns_db_name,
    $db_admin_user,
    $db_admin_pass,
    $primary_pdns_ip,
    $secondary_pdns_ip,
    $rabbit_user,
    $rabbit_pass,
    $rabbit_host,
    $keystone_public_port,
    $keystone_auth_port,
    ) {

    $keystone_host_ip   = ipresolve($nova_controller,4)
    $nova_controller_ip = ipresolve($nova_controller)
    $keystone_public_uri = "http://${nova_controller}:${keystone_public_port}"
    $keystone_admin_uri = "http://${nova_controller}:${keystone_auth_port}"
    $designate_host_ip = ipresolve($designate_host,4)
    $puppetmaster_hostname_ip = ipresolve($puppetmaster_hostname,4)

    require_package(
        'designate-sink',
        'designate-common',
        'designate',
        'designate-api',
        'designate-doc',
        'designate-central',
    )

    file { '/usr/lib/python2.7/dist-packages/wmf_sink':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => "puppet:///modules/openstack/${version}/designate/wmf_sink",
        recurse => true,
    }

    file { '/usr/lib/python2.7/dist-packages/wmf_sink.egg-info':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => "puppet:///modules/openstack/${version}/designate/wmf_sink.egg-info",
        recurse => true,
    }

    file { '/usr/lib/python2.7/dist-packages/nova_fixed_multi':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => "puppet:///modules/openstack/${version}/designate/nova_fixed_multi",
        recurse => true,
    }

    file { '/usr/lib/python2.7/dist-packages/nova_fixed_multi.egg-info':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => "puppet:///modules/openstack/${version}/designate/nova_fixed_multi.egg-info",
        recurse => true,
    }

    file {
        '/etc/designate/designate.conf':
            owner   => 'designate',
            group   => 'designate',
            mode    => '0440',
            content => template("openstack/${version}/designate/designate.conf.erb"),
            notify  => Service['designate-api','designate-sink','designate-central','designate-mdns','designate-pool-manager'],
            require => Package['designate-common'];
        '/etc/designate/api-paste.ini':
            content => template("openstack/${version}/designate/api-paste.ini.erb"),
            owner   => 'designate',
            group   => 'designate',
            notify  => Service['designate-api','designate-sink','designate-central'],
            require => Package['designate-api'],
            mode    => '0440';
        '/etc/designate/policy.json':
            source  => "puppet:///modules/openstack/${version}/designate/policy.json",
            owner   => 'designate',
            group   => 'designate',
            notify  => Service['designate-api','designate-sink','designate-central'],
            require => Package['designate-common'],
            mode    => '0440';
        '/etc/designate/rootwrap.conf':
            source  => "puppet:///modules/openstack/${version}/designate/rootwrap.conf",
            owner   => 'root',
            group   => 'root',
            notify  => Service['designate-api','designate-sink','designate-central'],
            require => Package['designate-common'],
            mode    => '0440';
    }

    # These would be automatically included in a correct designate package...
    # probably this can be ripped out in Liberty.
    logrotate::conf { 'designate-mdns':
        ensure => 'present',
        source => 'puppet:///modules/openstack/designate/designate-mdns.logrotate',
    }

    logrotate::conf { 'designate-pool-manager':
        ensure => 'present',
        source => 'puppet:///modules/openstack/designate/designate-pool-manager.logrotate',
    }

    file { '/var/lib/designate/.ssh/':
        ensure => 'directory',
        owner  => 'designate',
        group  => 'designate',
    }

    file { '/var/lib/designate/.ssh/id_rsa':
        owner     => 'designate',
        group     => 'designate',
        mode      => '0400',
        content   => secret('ssh/puppet_cert_manager/cert_manager'),
        show_diff => false,
    }

    file {'/etc/init/designate-pool-manager.conf':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        content => template('openstack/initscripts/designate-pool-manager.upstart.erb'),
        notify  => Service['designate-pool-manager'],
    }

    file {'/etc/init/designate-mdns.conf':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        content => template('openstack/initscripts/designate-mdns.upstart.erb'),
        notify  => Service['designate-mdns'],
    }

    # include rootwrap.d entries

    service {'designate-api':
        ensure  => $active,
        require => Package['designate-api'];
    }

    service {'designate-sink':
        ensure  => $active,
        require => Package['designate-sink'];
    }

    service {'designate-central':
        ensure  => $active,
        require => Package['designate-central'];
    }

    service {'designate-mdns':
        ensure  => $active,
        require =>  [
            Package['designate'],
            File['/etc/init/designate-mdns.conf'],
        ],
    }

    service {'designate-pool-manager':
        ensure  => $active,
        require =>  [
            Package['designate'],
            File['/etc/init/designate-pool-manager.conf'],
        ],
    }
}
