class openstack::designate ($openstack_version=$::openstack::version, $designateconfig) {
    package { [ ]:
        ensure => present;
    }

    file {
        "/etc/designate/designate.conf":
            content => template("openstack/${openstack_version}/designate/designate.conf.erb"),
            owner   => designate,
            group   => designate,
            notify  => Service["designate"],
            require => Package["designate"],
            mode    => '0440';
        "/etc/designate/api-paste.ini":
            content => template("openstack/${$openstack_version}/designate/api-paste.ini.erb"),
            owner   => 'designate',
            group   => 'designate',
            notify  => Service["designate-api"],
            require => Package["designate"],
            mode    => '0440';
        "/etc/designate/policy.json":
            content => file("${$openstack_version}/designate/policy.json"),
            owner   => 'designate',
            group   => 'designate',
            require => Package["designate"],
            mode    => '0440';
        "/etc/designate/rootwrap.conf":
            content => file("${$openstack_version}/designate/rootwrap.conf"),
            owner   => 'root',
            group   => 'root',
            require => Package["designate"],
            mode    => '0440';
    }

    # include rootwrap.d entries
}


