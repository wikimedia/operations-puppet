# == Class: role::sretest
#
# These servers are used by the Wikimedia SRE team for any tests which
# require baremetal servers (installer tests, kernel, microcode etc.)
# It's not puppetised except the base classes and Ferm
class role::sretest {

    system::role { 'sretest':
        ensure      => 'present',
        description => 'Host used for experiments by SREs',
    }

    include profile::base::production
    include profile::firewall
    include profile::sretest
}
