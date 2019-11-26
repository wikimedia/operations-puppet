class role::dns::recursor {
    system::role { 'dns::recursor': description => 'Recursive DNS server' }

    include ::profile::standard
    include ::profile::dns::recursor
}
