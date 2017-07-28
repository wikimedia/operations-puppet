# All horizon/striker/wikitech profiles should fold into
# role::wmcs::openstack::main::web when labweb* is finished
class role::wmcs::openstack::main::horizon {
    include profile::openstack::main::cloudrepo
}
