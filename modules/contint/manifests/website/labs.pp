class contint::website::labs {

    apache::site { 'integrationlabs':
        content => template('contint/apache/integration.wmflabs.org.erb'),
    }

}
