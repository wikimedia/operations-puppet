# Class: role::mirrors
#
# A role class used to setup our mirrors server.
class role::mirrors {
    system::role { 'mirrors':
        description => 'Mirrors server',
    }

    include profile::base::production
    include profile::base::firewall
    include profile::mirrors
}
