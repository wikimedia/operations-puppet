# vim: set ts=4 et sw=4:
# sets up an instance of the 'Open-source Ticket Request System'
# https://en.wikipedia.org/wiki/OTRS
#
# filtertags: labs-project-otrs
class role::otrs {
    system::role { 'otrs':
        description => 'OTRS Web Application Server',
    }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::otrs
}
