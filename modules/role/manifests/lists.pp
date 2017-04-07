# sets up a mailing list server
class role::lists {

    system::role { 'role::lists': description => 'Mailing list server', }

    include ::standard
    include ::profile::backup::host
    include ::profile::lists_server
}
