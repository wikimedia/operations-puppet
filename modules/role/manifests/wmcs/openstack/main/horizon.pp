# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::main::web when labweb* is finished
class role::wmcs::openstack::main::horizon {
    system::role { $name: }
    include ::standard
    include ::profile::base::firewall
    include ::profile::openstack::main::cloudrepo
    include ::profile::openstack::main::observerenv
    include ::profile::openstack::main::horizon::dashboard
}
