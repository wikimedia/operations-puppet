# packages for monitoring via IPMI
class ipmi::monitor {

    require_package(
        'ipmitool',
        'freeipmi-common',
        'freeipmi-tools',
        'freeipmi-ipmidetect',
        'freeipmi-bmc-watchdog',
        'libipc-run-perl',
    )
}
