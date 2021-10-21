# @summary Role to install a PKI RootCA
class role::pki::root {
    system::role { 'pki::root': description => 'PKI RootCA' }
    include profile::base::production
    include profile::base::firewall
    include profile::pki::root_ca
    include profile::pki::client
}
