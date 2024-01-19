# @summary Role to install a PKI RootCA
class role::pki::root {
    include profile::base::production
    include profile::firewall
    include profile::pki::root_ca
    include profile::pki::client
}
