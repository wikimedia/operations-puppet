class openstack::nova::common::neutron(
    $version,
    $db_user,
    $db_pass,
    $db_host,
    $db_name,
    $nova_controller,
    $scheduler_pool,
    $ldap_user_pass,
    $rabbit_user,
    $rabbit_host,
    $rabbit_pass,
    $glance_host,
    $metadata_proxy_shared_secret,
    ) {

    class {'openstack::nova::common::base':
        version => $version,
    }
    contain 'openstack::nova::common::base'

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
