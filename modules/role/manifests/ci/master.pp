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

    include ::profile::base::production
    include ::profile::ci::backup
    include ::profile::ci::firewall

    include ::profile::ci::jenkins
    include ::profile::ci::proxy_jenkins

    include ::profile::ci::slave

    include ::profile::ci::httpd
    include ::profile::tlsproxy::envoy
    include ::profile::ci::website

    include ::profile::prometheus::apache_exporter

    include ::profile::ci::docker
    include ::profile::ci::pipeline::publisher
    include ::profile::ci::shipyard
    include ::profile::ci::data_rsync
    include ::profile::local_dev::docker_publish

    include ::profile::zuul::merger

    include ::profile::zuul::server
    include ::profile::ci::proxy_zuul

    include ::profile::kubernetes::deployment_server

    include ::profile::statsite
}
