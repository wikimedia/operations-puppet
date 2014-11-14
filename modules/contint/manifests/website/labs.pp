class contint::website::labs {

    # Need to send Vary: X-Forwarded-Proto since most sites are forced to HTTPS
    # and behind a varnish cache. See also bug 60822
    include ::apache::mod::headers

    # The contint dev instance also has Gerrit/Jenkins
    include contint::proxy_gerrit
    include contint::proxy_jenkins

    apache::site { 'integrationlabs':
        content => template('contint/apache/integration.wmflabs.org.erb'),
    }

}
