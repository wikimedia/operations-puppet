# sets up a mailing list server
class role::lists {

    system::role { 'role::lists': description => 'Mailing list server', }

    include ::network::constants
    include ::standard
    include ::mailman
    include ::privateexim::listserve
    include ::exim4::ganglia
    include ::profile::backup::host
    include ::profile::lists_server
}
