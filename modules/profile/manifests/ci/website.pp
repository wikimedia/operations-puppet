# Website for Continuous integration
#
# http://integration.wikimedia.org/
class profile::ci::website {

    scap::target { 'integration/docroot':
        deploy_user => 'deploy-ci-docroot',
    }

    # Apache configuration for integration.wikimedia.org
    httpd::site { 'integration.wikimedia.org':
        content => template('contint/apache/integration.wikimedia.org.erb'),
    }

}
