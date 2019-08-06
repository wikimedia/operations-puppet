# == Class: role::idp
# An identity provider using Apereo CAS
class role::idp {

    system::role { 'idp': description => 'CAS Identity provider' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::idp
}
