class openstack::nova::common::neutron(
    $version,
    ) {

    require openstack::nova::common::base

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
}
