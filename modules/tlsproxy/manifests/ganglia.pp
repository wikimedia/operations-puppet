# vim:sw=4:ts=4:et:

# Ganglia monitoring
class tlsproxy::ganglia {
    # Dummy site to provide a status to Ganglia
    nginx::site { 'localhost':
        content => template('tlsproxy/localhost.erb'),
    }

}
