# == Class: role::insetup
#
# Role to be applied for a server during initial setup, before it's passed
# to the server owner for the actual application of the production role
class role::insetup {

    system::role { 'insetup':
        ensure      => 'present',
        description => 'Host being setup for later application of a role',
    }

    include ::profile::base::production
    include ::profile::base::firewall
}
