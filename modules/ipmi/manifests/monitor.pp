# packages for monitoring via IPMI
class ipmi::monitor {

    require_package(
        'freeipmi-tools',
        'freeipmi-ipmidetect',
        'freeipmi-bmc-watchdog',
    )
}
