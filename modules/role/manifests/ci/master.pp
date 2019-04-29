# vim: set et ts=4 sw=4:

# role::ci::master
#
# Setup a Jenkins installation attended to be used as a master. This setup some
# CI specific requirements such as having workspace on a SSD device and Jenkins
# monitoring.
#
# CI test server as per T79623
class role::ci::master {

    system::role { 'ci::master': description => 'CI Jenkins master' }

    include ::profile::standard
    include ::profile::ci::backup
    include ::profile::ci::firewall

    include ::profile::ci::jenkins
    include ::profile::ci::proxy_jenkins

    include ::profile::ci::slave

    include ::profile::ci::httpd
    include ::profile::ci::website

    include ::profile::ci::docker
    include ::profile::ci::pipeline::publisher
    include ::profile::ci::shipyard

    include ::profile::zuul::merger

    include ::profile::zuul::server
    include ::profile::ci::proxy_zuul

    include ::profile::kubernetes::deployment_server
    include ::profile::ci::kubernetes_config

    include ::profile::rsyslog::kafka_shipper

    # TODO: T186790. Force the order of docker group ensuring to be before
    # adding jenkins-slave to it. This is a flawed approach and should be better
    # addressed. See T174465 for the long discussion
    Class['Admin'] -> Class['::profile::ci::docker']

    include ::profile::statsite
}
