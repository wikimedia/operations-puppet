# IPMItool mgmt hosts
class ipmi {

    package { 'ipmitool':
        ensure => present,
    }

    file { '/usr/local/sbin/ipmi_mgmt':
        path   => '/usr/local/sbin/ipmi_mgmt',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/ipmi/ipmi_mgmt',
    }
}
