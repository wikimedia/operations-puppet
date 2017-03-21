# == Class: role::failoid
# A simple service that reject any connections to a list of ports.
class role::failoid {

    system::role { 'role::failoid': description => 'Failoid service' }

    include ::standard
    include ::base::firewall
    include ::profile::failoid
}
