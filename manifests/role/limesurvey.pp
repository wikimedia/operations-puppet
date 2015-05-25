# = Class: role::limesurvey
#
# This class sets up a LimeSurvey instance
#
class role::limesurvey {

    class { '::limesurvey':
        hostname   => 'limesurvey.wikimedia.org',
        deploy_dir => '/srv/deployment/limesurvey/limesurvey',
        cache_dir  => '/var/cache/limesurvey',
        mysql_host => 'localhost',
        mysql_db   => 'limesurvey',
    }

    ferm::service { 'limesurvey_http':
        proto => 'tcp',
        port  => '80',
    }

}
# vim:sw=4 ts=4 sts=4 et:
