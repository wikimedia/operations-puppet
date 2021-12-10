# @summary profiletp configure the compiler nodes
class profile::puppet_compiler {
    requires_realm('labs')

    include profile::openstack::base::puppetmaster::enc_client
    class {'puppet_compiler': }
}
