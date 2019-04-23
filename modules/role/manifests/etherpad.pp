# sets up an Etherpad lite server
class role::etherpad {

    system::role { 'etherpad': description => 'Etherpad-lite server' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::etherpad
}
