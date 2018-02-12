# A static http server, serving static files from NFS
# Also serves an up-to-date mirror of cdnjs

class toollabs::static(
    $web_domain = 'tools.wmflabs.org',
    $ssl_certificate_name = 'star.wmflabs.org',
    $ssl_settings = ssl_ciphersuite('nginx', 'compat'),
) {

    include ::toollabs::infrastructure

    if $ssl_certificate_name != false {
        sslcert::certificate { $ssl_certificate_name: }
    }

    $resolver = join($::nameservers, ' ')
    nginx::site { 'static-server':
        content => template('toollabs/static-server.conf.erb'),
    }
}
