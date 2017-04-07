# sets up an Etherpad lite server
class role::etherpad_server{

    system::role { 'etherpad::server': description => 'Etherpad-lite server' }

    include ::standard
    include ::profile::etherpad::server
    include ::passwords::etherpad_lite
}
