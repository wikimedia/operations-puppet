# SPDX-License-Identifier: Apache-2.0
#
# role::ci
#
class role::ci {
    include profile::base::production
    include profile::ci::backup
    include profile::ci::firewall

    include profile::ci::jenkins
    include profile::ci::proxy_jenkins

    include profile::ci::agent

    include profile::ci::httpd
    include profile::tlsproxy::envoy
    include profile::ci::website

    include profile::prometheus::apache_exporter

    include profile::ci::docker
    include profile::ci::pipeline::publisher
    include profile::ci::shipyard
    include profile::ci::data_rsync
    include profile::local_dev::docker_publish

    include profile::zuul::merger

    include profile::zuul::server
    include profile::ci::proxy_zuul

    include profile::kubernetes::deployment_server
    include profile::kubernetes::client

    include profile::statsite
}
