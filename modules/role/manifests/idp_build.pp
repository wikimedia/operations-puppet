# SPDX-License-Identifier: Apache-2.0
# == Class: role::idp_build
# A stub role to build Apereo CAS
class role::idp_build {
    include profile::base::production
    include profile::firewall
    include profile::idp::build
}
