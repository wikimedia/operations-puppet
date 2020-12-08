# == Class: role::idp
# An identity provider using Apereo CAS
class role::idp_test {

    system::role { 'idp': description => 'CAS Identity provider (staging setup)' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::idp
    include ::profile::java
}
