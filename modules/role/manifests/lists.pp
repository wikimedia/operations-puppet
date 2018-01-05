# sets up a mailing list server
class role::lists {

    system::role { 'lists': description => 'Mailing list server', }

    include ::standard
    include ::profile::backup::host
    include ::profile::base::firewall
    include ::profile::lists
    include ::profile::locales::extended
}
