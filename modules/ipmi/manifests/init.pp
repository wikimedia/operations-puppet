# IPMItool mgmt hosts
class ipmi {

    package { 'ipmitool':
        ensure => 'latest',
    }

    file { '/usr/local/sbin/ipmi_mgmt':
        path   => '/usr/local/sbin/ipmi_mgmt',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///ipmi/ipmi_mgmt',
    }
}
