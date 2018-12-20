class openstack::nova::common::base(
    $version,
    ) {

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    if (os_version('debian jessie') or os_version('debian stretch')) and ($version == 'mitaka') {
        $install_options = ['-t', 'jessie-backports']
    } else {
        $install_options = ''
    }

    package { $packages:
        ensure          => 'present',
        install_options => $install_options,
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

    file { '/etc/nova/policy.json':
        source => "puppet:///modules/openstack/${version}/nova/common/policy.json",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
    }

    if os_version('debian == jessie') {

        file {'/etc/nova/original':
            ensure  => 'directory',
            owner   => 'nova',
            group   => 'nova',
            mode    => '0755',
            recurse => true,
            source  => "puppet:///modules/openstack/${version}/nova/original",
            require => Package['nova-common'],
        }
    }
}
