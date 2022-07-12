# SPDX-License-Identifier: Apache-2.0
# == Class: role::idp
# An identity provider using Apereo CAS
class role::idp {

    system::role { 'idp': description => 'CAS Identity provider' }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::idp
    include ::profile::java
}
