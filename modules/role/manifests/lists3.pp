class role::lists3 {

    system::role { 'lists3': description => 'Mailing list server (mailman3)', }

    include profile::standard
    include profile::base::firewall
    include profile::mailman3
}

