# IPMItool mgmt hosts
class ipmi {

    require_package(
        'ipmitool',
        'freeipmi-common',
        'freeipmi-tools',
        'freeipmi-ipmidetect',
        'freeipmi-bmc-watchdog',
        'libipc-run-perl',
    )

    file { '/usr/local/sbin/ipmi_mgmt':
        path   => '/usr/local/sbin/ipmi_mgmt',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/ipmi/ipmi_mgmt',
    }

}
