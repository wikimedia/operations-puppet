# == Class: role::insetup_noferm
#
# Role to be applied for a server during initial setup, before it's passed
# to the server owner for the actual application of the production role
# This is a variant for the setup of a service which will not use base::firewall
# when moved to full production
class role::insetup_noferm {

    system::role { 'insetup_noferm':
        ensure      => 'present',
        description => 'Host being setup for later application of a role (no ferm)',
    }

    include ::profile::base::production
}
