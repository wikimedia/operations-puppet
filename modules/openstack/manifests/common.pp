# common packages and config for openstack
class openstack::common(
            $novaconfig,
            $wikitechstatusconfig,
            $openstack_version=$::openstack::version,
    ) {

    include ::openstack::repo

    $packages = [
        'unzip',
        'nova-common',
        'vblade-persist',
        'bridge-utils',
        'ebtables',
        'mysql-common',
        'mysql-client-5.5',
        'python-mysqldb',
        'python-netaddr',
        'python-keystone',
        'python-novaclient',
        'python-openstackclient',
        'python-designateclient',
        'radvd',
    ]

    require_package($packages)

    # Allow unprivileged users to look at nova logs
    file { '/var/log/nova':
        ensure => directory,
        owner  => 'nova',
        group  => hiera('openstack::log_group', 'adm'),
        mode   => '0750',
    }

    file {
        '/etc/nova/nova.conf':
            content => template("openstack/${openstack_version}/nova/nova.conf.erb"),
            owner   => 'nova',
            group   => 'nogroup',
            mode    => '0440',
            require => Package['nova-common'];
        '/etc/nova/api-paste.ini':
            content => template("openstack/${openstack_version}/nova/api-paste.ini.erb"),
            owner   => 'nova',
            group   => 'nogroup',
            mode    => '0440',
            require => Package['nova-common'];
    }
}
