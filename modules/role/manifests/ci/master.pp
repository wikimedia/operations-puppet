# vim: set et ts=4 sw=4:

# role::ci::master
#
# Setup a Jenkins installation attended to be used as a master. This setup some
# CI specific requirements such as having workspace on a SSD device and Jenkins
# monitoring.
#
# CI test server as per T79623
#
# filtertags: labs-project-ci-staging
class role::ci::master {

    system::role { 'ci::master': description => 'CI Jenkins master' }

    include ::standard
    include ::profile::ci::backup
    include ::profile::ci::firewall
    include ::profile::ci::jenkins
    include ::profile::ci::slave
    include ::profile::ci::website
    include ::profile::ci::docker
    include ::profile::ci::pipeline
    include ::profile::ci::shipyard
    include ::profile::zuul::merger
    include ::profile::zuul::server

    group { 'thisisadummygroup':
        ensure => present,
        system => true,
        gid    => 667,
    }

    user { 'thisisadummysystemuser':
        system  => true,
        group   => 'thisisadummygroup',
        groups  => ['docker'],
        require => Class['::standard'],
    }
}
