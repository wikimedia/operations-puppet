# packages for monitoring via IPMI
class ipmi::monitor {

    package { [
        'freeipmi-tools',
        'freeipmi-ipmidetect',
        'freeipmi-bmc-watchdog',
        ]:
        ensure => 'present',
    }
}
