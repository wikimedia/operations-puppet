# == Class: role::failoid
# A simple service that reject any connections to a list of ports.
class role::failoid {

    system::role { 'failoid': description => 'Failoid service' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::failoid
}
