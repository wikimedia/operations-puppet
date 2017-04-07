# sets up an Etherpad lite server
class role::etherpad {

    system::role { 'etherpad': description => 'Etherpad-lite server' }

    include ::standard
    include ::profile::etherpad
}
