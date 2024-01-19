# @summary Role to install a PKI server
class role::pki::multirootca {
    include profile::base::production
    include profile::firewall
    include profile::pki::multirootca
    include profile::pki::client
}
