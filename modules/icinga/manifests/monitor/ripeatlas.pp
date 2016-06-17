# = Class: icinga::monitor::ripeatlas
#
class icinga::monitor::ripeatlas {

    # eqiad
    @monitoring::host { 'ripe-atlas-eqiad':
        ip_address => '208.80.155.69',
    }

    monitoring::service { 'atlas-ping-eqiad-ipv4':
        description           => 'IPv4 ping to eqiad',
        check_command         => 'check_ripe_atlas!1790945!50!19',
        host                  => 'ripe-atlas-eqiad',
        normal_check_interval => 5,
        retry_check_interval  => 1,
        contact_group         => 'admins',
    }
    monitoring::service { 'atlas-ping-eqiad-ipv6':
        description           => 'IPv6 ping to eqiad',
        check_command         => 'check_ripe_atlas!1790947!50!19',
        host                  => 'ripe-atlas-eqiad',
        normal_check_interval => 5,
        retry_check_interval  => 1,
        contact_group         => 'admins',
    }

    # codfw
    @monitoring::host { 'ripe-atlas-codfw':
        ip_address => '208.80.152.244',
    }

    monitoring::service { 'atlas-ping-codfw-ipv4'
        description           => 'IPv4 ping to codfw',
        check_command         => 'check_ripe_atlas!1791210!50!19',
        host                  => 'ripe-atlas-codfw',
        normal_check_interval => 5,
        retry_check_interval  => 1,
        contact_group         => 'admins',
    }

    monitoring::service { 'atlas-ping-codfw-ipv6'
        description           => 'IPv6 ping to codfw',
        check_command         => 'check_ripe_atlas!1791212!50!19',
        host                  => 'ripe-atlas-codfw',
        normal_check_interval => 5,
        retry_check_interval  => 1,
        contact_group         => 'admins',
    }

    # ulsfo
    @monitoring::host { 'ripe-atlas-ulsfo':
        ip_address => '198.35.26.244',
    }

    monitoring::service { 'atlas-ping-ulsfo-ipv4'
        description           => 'IPv4 ping to ulsfo',
        check_command         => 'check_ripe_atlas!1791307!50!19',
        host                  => 'ripe-atlas-ulsfo',
        normal_check_interval => 5,
        retry_check_interval  => 1,
        contact_group         => 'admins',
    }

    monitoring::service { 'atlas-ping-ulsfo-ipv6'
        description           => 'IPv6 ping to ulsfo',
        check_command         => 'check_ripe_atlas!1791309!50!19',
        host                  => 'ripe-atlas-ulsfo',
        normal_check_interval => 5,
        retry_check_interval  => 1,
        contact_group         => 'admins',
    }
}
