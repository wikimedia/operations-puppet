# vim: set et ts=4 sw=4:

# role::ci::master
#
# Setup the CI server with a Jenkins controller and Zuul server/merger.
class role::ci::master {

    system::role { 'ci::master': description => 'CI server' }

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
    include ::profile::kubernetes::client

    include ::profile::statsite
}
