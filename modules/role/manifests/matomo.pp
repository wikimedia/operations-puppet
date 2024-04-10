# SPDX-License-Identifier: Apache-2.0
# == Class: role::matomo
#
class role::matomo {

    system::role { 'matomo':
        description => 'Matomo analytics server',
    }

    include profile::base::production
    include profile::firewall

    include profile::matomo::webserver
    include profile::tlsproxy::envoy
    include profile::matomo::instance
    # override profile::backup::enable to disable regular backups
    include profile::analytics::backup::database
    include profile::matomo::database
}
