# vim:sw=4:ts=4:et:

# Ganglia monitoring
class protoproxy::ganglia {
    include ::apache::monitoring

    # Dummy site to provide a status to Ganglia
    nginx::site { 'localhost':
        content => template('protoproxy/localhost.erb'),
    }

}
