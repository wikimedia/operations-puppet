# SPDX-License-Identifier: Apache-2.0
#
# Sets up a staging repo which will distribute packages built and
# uploaded by the CI pipeline
class role::apt_staging {
    include profile::base::production
    include profile::firewall
    include profile::backup::host

    include profile::nginx
    include profile::tlsproxy::envoy
    include profile::aptrepo::staging
}
