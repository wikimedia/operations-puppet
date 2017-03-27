# (thorium)
class role::statistics::web inherits role::statistics::base {
    system::role { 'role::statistics::web':
        description => 'Statistics private data host and general compute node'
    }

    # include stuff common to statistics webserver nodes.
    include ::statistics::web

    # # include statistics web sites
    include ::statistics::sites::datasets
    include ::statistics::sites::metrics
    include ::statistics::sites::stats
    # analytics.wikimedia.org will eventually supercede
    # datasets and stats.
    include ::statistics::sites::analytics
    # Proxy to securely access Yarn (authentication via LDAP)
    include ::statistics::sites::yarn
    # Proxy to securely access Pivot (authentication via LDAP)
    include ::statistics::sites::pivot
    # Proxy to Hue (not authenticated via LDAP, delegated to app)
    include ::statistics::sites::hue

    ferm::service {'statistics-web':
        proto => 'tcp',
        port  => '80',
    }

}
