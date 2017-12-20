class profile::openstack::base::pdns::auth::monitor::pdns_control {

    sudo::user { 'diamond_sudo_for_pdns':
        user       => 'diamond',
        privileges => ['ALL=(root) NOPASSWD: /usr/bin/pdns_control list'],
    }

    sudo::user { 'prometheus_sudo_for_pdns':
        user       => 'prometheus',
        privileges => ['ALL=(root) NOPASSWD: /usr/bin/pdns_control list'],
    }

    # For the authoritative servers
    diamond::collector { 'PowerDNS':
        ensure   => present,
        settings => {
            # lint:ignore:quoted_booleans
            # This is jammed straight into a config file, needs quoting.
            use_sudo => 'true',
            # lint:endignore
        },
        require  => Sudo::User['diamond_sudo_for_pdns'],
    }
}
