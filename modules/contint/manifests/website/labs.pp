class contint::website::labs {

    # The contint dev instance also has Gerrit
    include ::contint::proxy_gerrit

    httpd::site { 'integrationlabs':
        content => template('contint/apache/integration.wmflabs.org.erb'),
    }

}
