# Class: role::rpkivalidator
#
# This role installs and configure a RPKI validator - T220669
#
# Actions:
#       install and configure a RPKI validator
#
# Sample Usage:
#       role(rpkivalidator)
#


class role::rpkivalidator {
    system::role { 'rpkivalidator': description => 'RPKI Validator' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::rpkivalidator
}
