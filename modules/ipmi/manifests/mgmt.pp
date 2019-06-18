# tools for IPMI mgmt hosts
class ipmi::mgmt {

    require_package('ipmitool')
    file { '/usr/local/sbin/ipmi_mgmt':
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/ipmi/ipmi_mgmt.sh',
    }

    $key_pair = 'Chassis_Boot_Flags:Boot_Device=NO-OVERRIDE'
    if $facts.has_key('ipmi_chassis') and
        $facts['ipmi_chassis']['boot_flags']['device'] != 'NO-OVERRIDE' {
        exec {"/usr/sbin/ipmi-chassis-config --commit --key-pair='${key_pair}'":}
    }
}
