# = Class: icinga::monitor::ripeatlas
#
class icinga::monitor::ripeatlas {

    @monitoring::host { 'ripe-atlas-eqiad':
        ip_address => '208.80.155.69',
    }

    monitoring::service { 'eqiad-icmp-ipv4-reachability':
        description           => 'test icmp reachability to eqiad',
        check_command         => 'check_ripe_atlas!1790945!50!19',
        host                  => 'ripe-atlas-eqiad',
        normal_check_interval => 10,
        retry_check_interval  => 5,
        contact_group         => 'admins',
    }

    @monitoring::host { 'ripe-atlas-codfw':
        ip_address => '208.80.152.244',
    }

    monitoring::service { 'codfw-icmp-ipv4-reachability':
        description           => 'test icmp reachability to codfw',
        check_command         => 'check_ripe_atlas!1791210!50!19',
        host                  => 'ripe-atlas-codfw',
        normal_check_interval => 10,
        retry_check_interval  => 5,
        contact_group         => 'admins',
    }

    @monitoring::host { 'ripe-atlas-ulsfo':
        ip_address => '198.35.26.244',
    }

    monitoring::service { 'ulsfo-icmp-ipv4-reachability':
        description           => 'test icmp reachability to ulsfo',
        check_command         => 'check_ripe_atlas!1791307!50!19',
        host                  => 'ripe-atlas-ulsfo',
        normal_check_interval => 10,
        retry_check_interval  => 5,
        contact_group         => 'admins',
    }
}
