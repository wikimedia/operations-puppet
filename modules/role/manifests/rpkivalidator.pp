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
    include profile::base::production
    include profile::firewall
    include profile::rpkivalidator
    include profile::bgpalerter
}
