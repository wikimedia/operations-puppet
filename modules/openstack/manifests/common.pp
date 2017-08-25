# common packages and config for openstack
class openstack::common(
            $novaconfig,
            $wikitechstatusconfig,
            $openstack_version=$::openstack::version,
    ) {

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

    # For some reason the Mitaka nova-common package installs
    #  a logrotate rule for nova/*.log and also a nova/nova-manage.log.
    #  This is redundant and makes log-rotate unhappy.
    # Not to mention, nova-manage.log is very low traffic and doesn't
    #  really need to be rotated anyway.
    file { '/etc/logrotate.d/nova-manage':
        ensure  => absent,
        require => Package['nova-common'],
    }

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

