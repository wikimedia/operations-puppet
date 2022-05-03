# == Class: role::idp
# An identity provider using Apereo CAS
class role::idp_test {

    system::role { 'idp': description => 'CAS Identity provider (staging setup)' }

    include profile::base::production
    include profile::base::firewall
    include profile::idp
    include profile::idp::build
    include profile::java
}
