class openstack::nova::common::base(
    $version,
    ) {

    class { "openstack::nova::common::base::${version}::${::lsbdistcodename}": }

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
        source  => "puppet:///modules/openstack/${version}/nova/common/policy.json",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        require => Package['nova-common'],
    }
}
