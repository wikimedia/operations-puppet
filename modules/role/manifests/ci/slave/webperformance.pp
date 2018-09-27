# == Class role:ci::slave::webperformance
#
# Configure an instance to run WebPageTest performance tests. The runner uses
# NodeJS and the jobs typically have a long run time (30+ minutes).
#
# filtertags: labs-project-git labs-project-integration
class role::ci::slave::webperformance {

    system::role { 'ci::slave::webperformance':
        description => 'CI Jenkins slave for WebPageTest jobs',
    }

    include ::role::ci::slave::labs::common
    include ::contint::packages::javascript
}
