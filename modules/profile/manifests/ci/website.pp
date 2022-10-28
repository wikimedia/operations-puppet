# SPDX-License-Identifier: Apache-2.0
# Website for Continuous integration
#
# http://integration.wikimedia.org/
class profile::ci::website {

    scap::target { 'integration/docroot':
        deploy_user => 'deploy-ci-docroot',
    }

    # Apache configuration for integration.wikimedia.org
    httpd::site { 'integration.wikimedia.org':
        source => 'puppet:///modules/contint/apache/integration.wikimedia.org.conf'
    }

}
