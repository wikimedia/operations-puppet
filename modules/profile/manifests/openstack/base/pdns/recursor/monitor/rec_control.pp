class profile::openstack::base::pdns::recursor::monitor::rec_control {

    sudo::user { 'diamond_sudo_for_pdns_recursor':
        user       => 'diamond',
        privileges => ['ALL=(root) NOPASSWD: /usr/bin/rec_control get-all'],
    }

    sudo::user { 'prometheus_sudo_for_pdns_recursor':
        user       => 'prometheus',
        privileges => ['ALL=(root) NOPASSWD: /usr/bin/rec_control get-all'],
    }

    # For the recursor
    diamond::collector { 'PowerDNSRecursor':
        source   => 'puppet:///modules/diamond/collector/powerdns_recursor.py',
        settings => {
            # lint:ignore:quoted_booleans
            # This is jammed straight into a config file, needs quoting.
            use_sudo => 'true',
            # lint:endignore
        },
        require  => Sudo::User['diamond_sudo_for_pdns_recursor'],
    }
}
