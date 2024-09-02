# SPDX-License-Identifier: Apache-2.0
# == Class: role::idp
# An identity provider using Apereo CAS
class role::idp_test {
    include profile::base::production
    include profile::firewall
    include profile::idp
    include profile::idp::build
    include profile::java
}
