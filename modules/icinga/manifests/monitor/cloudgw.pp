class icinga::monitor::cloudgw {

    $wan_fqdn = 'wan.cloudgw.eqiad1.wikimediacloud.org'
    @monitoring::host { $wan_fqdn:
        host_fqdn     => $wan_fqdn,
        contact_group => 'wmcs-team-email',
    }

    $virt_fqdn = 'virt.cloudgw.eqiad1.wikimediacloud.org'
    @monitoring::host { $virt_fqdn:
        host_fqdn     => $virt_fqdn,
        contact_group => 'wmcs-team-email',
    }
}
