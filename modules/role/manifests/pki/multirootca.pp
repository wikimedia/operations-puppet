# @summary Role to install a PKI server
class role::pki::multirootca {
    system::role { 'pki::multirotoca': description => 'PKI Server' }
    include profile::standard
    include profile::base::firewall
    include profile::pki::multirootca
    include profile::pki::client
}
