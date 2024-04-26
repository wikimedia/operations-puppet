# == Class: role::insetup_noferm
#
# Role to be applied for a server during initial setup, before it's passed
# to the server owner for the actual application of the production role
# This is a variant for the setup of a service which will not use profile::firewall
# when moved to full production
class role::insetup_noferm {
    include profile::base::production
}
