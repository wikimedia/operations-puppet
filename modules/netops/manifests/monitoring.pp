# == Class: netops::monitoring
#
# Sets up monitoring checks for networking equipment.
#
# === Parameters
#
# === Examples
#
#  include netops::monitoring

class netops::monitoring {

    include passwords::network
    $snmp_ro_community = $passwords::network::snmp_ro_community

    ### esams ###

    # cr1-esams
    @monitoring::host { 'cr1-esams':
        ip_address => '91.198.174.245',
        group      => 'routers',
    }
    @monitoring::service { 'cr1-esams interfaces':
        host          => 'cr1-esams',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::service { 'cr1-esams bgp status':
        host          => 'cr1-esams',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgp!${snmp_ro_community}",
    }

    # cr2-esams
    @monitoring::host { 'cr2-esams':
        ip_address => '91.198.174.244',
        group      => 'routers',
    }
    @monitoring::service { 'cr2-esams interfaces':
        host          => 'cr2-esams',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::service { 'cr2-esams bgp status':
        host          => 'cr2-esams',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgp!${snmp_ro_community}",
    }

    # cr2-knams
    @monitoring::host { 'cr2-knams':
        ip_address => '91.198.174.246',
        group      => 'routers',
    }
    @monitoring::service { 'cr2-knams interfaces':
        host          => 'cr2-knams',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::service { 'cr2-knams bgp status':
        host          => 'cr2-knams',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgp!${snmp_ro_community}",
    }

    # mr1-esams
    @monitoring::host { 'mr1-esams':
        ip_address => '91.198.174.247',
        group      => 'routers'
    }
    @monitoring::service { 'mr1-esams interfaces':
        host          => 'mr1-esams',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::host { 'mr1-esams.oob':
        host_fqdn => 'mr1-esams.oob.wikimedia.org',
        group     => 'routers'
    }

    ### eqiad ###

    # cr1-eqiad
    @monitoring::host { 'cr1-eqiad':
        ip_address => '208.80.154.196',
        group      => 'routers',
    }
    @monitoring::service { 'cr1-eqiad interfaces':
        host          => 'cr1-eqiad',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::service { 'cr1-eqiad bgp status':
        host          => 'cr1-eqiad',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgp!${snmp_ro_community}",
    }

    # cr2-eqiad
    @monitoring::host { 'cr2-eqiad':
        ip_address => '208.80.154.197',
        group      => 'routers',
    }
    @monitoring::service { 'cr2-eqiad interfaces':
        host          => 'cr2-eqiad',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::service { 'cr2-eqiad bgp status':
        host          => 'cr2-eqiad',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgp!${snmp_ro_community}",
    }

    # mr1-eqiad
    @monitoring::host { 'mr1-eqiad':
        ip_address => '208.80.154.199',
        group      => 'routers',
    }
    @monitoring::service { 'mr1-eqiad interfaces':
        host          => 'mr1-eqiad',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::host { 'mr1-eqiad.oob':
        host_fqdn => 'mr1-eqiad.oob.wikimedia.org',
        group     => 'routers'
    }

    ### eqord ###

    # cr1-eqord
    @monitoring::host { 'cr1-eqord':
        ip_address => '208.80.154.198',
        group      => 'routers',
    }
    @monitoring::service { 'cr1-eqord interfaces':
        host          => 'cr1-eqord',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::service { 'cr1-eqord bgp status':
        host          => 'cr1-eqord',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgp!${snmp_ro_community}",
    }

    ### ulsfo ###

    # cr1-ulsfo
    @monitoring::host { 'cr1-ulsfo':
        ip_address => '198.35.26.192',
        group      => 'routers',
    }
    @monitoring::service { 'cr1-ulsfo interfaces':
        host          => 'cr1-ulsfo',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::service { 'cr1-ulsfo bgp status':
        host          => 'cr1-ulsfo',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgp!${snmp_ro_community}",
    }

    # cr2-ulsfo
    @monitoring::host { 'cr2-ulsfo':
        ip_address => '198.35.26.193',
        group      => 'routers',
    }
    @monitoring::service { 'cr2-ulsfo interfaces':
        host          => 'cr2-ulsfo',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::service { 'cr2-ulsfo bgp status':
        host          => 'cr2-ulsfo',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgp!${snmp_ro_community}",
    }

    # mr1-ulsfo
    @monitoring::host { 'mr1-ulsfo':
        ip_address => '198.35.26.194',
        group      => 'routers',
    }
    @monitoring::service { 'mr1-ulsfo interfaces':
        host          => 'mr1-ulsfo',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::host { 'mr1-ulsfo.oob':
        host_fqdn => 'mr1-ulsfo.oob.wikimedia.org',
        group     => 'routers'
    }

    ### codfw ###

    # cr1-codfw
    @monitoring::host { 'cr1-codfw':
        ip_address => '208.80.153.192',
        group      => 'routers',
    }
    @monitoring::service { 'cr1-codfw interfaces':
        host          => 'cr1-codfw',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::service { 'cr1-codfw bgp status':
        host          => 'cr1-codfw',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgp!${snmp_ro_community}",
    }

    # cr2-codfw
    @monitoring::host { 'cr2-codfw':
        ip_address => '208.80.153.193',
        group      => 'routers',
    }
    @monitoring::service { 'cr2-codfw interfaces':
        host          => 'cr2-codfw',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::service { 'cr2-codfw bgp status':
        host          => 'cr2-codfw',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgp!${snmp_ro_community}",
    }

    # mr1-codfw
    @monitoring::host { 'mr1-codfw':
        ip_address => '208.80.153.196',
        group      => 'routers',
    }
    @monitoring::service { 'mr1-codfw interfaces':
        host          => 'mr1-codfw',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::host { 'mr1-codfw.oob':
        host_fqdn => 'mr1-codfw.oob.wikimedia.org',
        group     => 'routers'
    }

    ### eqdfw ###

    # cr1-eqdfw
    @monitoring::host { 'cr1-eqdfw':
        ip_address => '208.80.153.198',
        group      => 'routers',
    }
    @monitoring::service { 'cr1-eqdfw interfaces':
        host          => 'cr1-eqdfw',
        group         => 'routers',
        description   => 'Router interfaces',
        check_command => "check_ifstatus_nomon!${snmp_ro_community}",
    }
    @monitoring::service { 'cr1-eqdfw bgp status':
        host          => 'cr1-eqdfw',
        group         => 'routers',
        description   => 'BGP status',
        check_command => "check_bgp!${snmp_ro_community}",
    }
}
