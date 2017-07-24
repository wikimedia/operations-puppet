# == Class role:ci::slave::webperf
#
# Configure an instance to run WebPageTest performance tests. The runner uses
# NodeJS and the jobs typically have a long run time (30+ minutes).
#
# filtertags: labs-project-git labs-project-integration labs-project-ci-staging
class role::ci::slave::webperf {

    system::role { 'ci::slave::webperf':
        description => 'CI Jenkins slave for WebPageTest jobs',
    }

    include ::role::ci::slave::labs::common
    include ::contint::packages::javascript
}
