class profile::openstack::base::pdns::auth::monitor::pdns_control {

    sudo::user { 'prometheus_sudo_for_pdns':
        user       => 'prometheus',
        privileges => ['ALL=(root) NOPASSWD: /usr/bin/pdns_control list'],
    }
}
