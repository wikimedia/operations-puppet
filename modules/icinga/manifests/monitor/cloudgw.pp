class icinga::monitor::cloudgw {

    $wan_fqdn = 'wan.cloudgw.eqiad1.wikimediacloud.org'
    prometheus::blackbox::check::icmp { $wan_fqdn:
        site           => 'eqiad',
        instance_label => $wan_fqdn,
        team           => 'wmcs',
        # TODO: change once https://phabricator.wikimedia.org/T312840 is done
        ip4            => ipresolve($wan_fqdn, 4),
        ip_families    => ['ip4'],
    }

    $virt_fqdn = 'virt.cloudgw.eqiad1.wikimediacloud.org'
    prometheus::blackbox::check::icmp { $virt_fqdn:
        site           => 'eqiad',
        instance_label => $virt_fqdn,
        team           => 'wmcs',
        # TODO: change once https://phabricator.wikimedia.org/T312840 is done
        ip4            => ipresolve($virt_fqdn, 4),
        ip_families    => ['ip4'],
    }
}
