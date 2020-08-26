# @summary Role to install a PKI server
class role::pki {
    system::role { 'pki': description => 'PKI Server' }
    include profile::standard
    include profile::base::firewall
    include profile::pki
}
