# vim: set ts=4 et sw=4:
# sets up an instance of the 'VRT System' (formerly: 'Open-source Ticket Request System')
# https://wikitech.wikimedia.org/wiki/VRT_System
#
class role::vrts {
    include profile::base::production
    include profile::firewall
    include profile::vrts
    include profile::tlsproxy::envoy # TLS termination
}
