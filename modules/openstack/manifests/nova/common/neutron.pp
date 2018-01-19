class openstack::nova::common::neutron(
    $version,
    ) {

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }

    # For some reason the Mitaka nova-common package installs
    #  a logrotate rule for nova/*.log and also a nova/nova-manage.log.
    #  This is redundant and makes log-rotate unhappy.
    # Not to mention, nova-manage.log is very low traffic and doesn't
    #  really need to be rotated anyway.
    file { '/etc/logrotate.d/nova-manage':
        ensure  => 'absent',
        require => Package['nova-common'],
    }

    # Allow unprivileged users to look at nova logs
    file { '/var/log/nova':
        ensure  => 'directory',
        owner   => 'nova',
        group   => hiera('openstack::log_group', 'adm'),
        mode    => '0750',
        require => Package['nova-common'],
    }

    file {
        '/etc/nova/nova.conf':
            content => template("openstack/${version}/nova/common/neutron/nova.conf.erb"),
            owner   => 'nova',
            group   => 'nogroup',
            mode    => '0440',
            require => Package['nova-common'];
        '/etc/nova/api-paste.ini':
            content => template("openstack/${version}/nova/common/neutron/api-paste.ini.erb"),
            owner   => 'nova',
            group   => 'nogroup',
            mode    => '0440',
            require => Package['nova-common'];
    }

    file { '/etc/nova/policy.json':
        source => "puppet:///modules/openstack/${version}/nova/common/policy.json",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }
}
