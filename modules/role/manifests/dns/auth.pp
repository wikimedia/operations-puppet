class role::dns::auth {
    system::role { 'dns::auth': description => 'Authoritative DNS server' }

    include ::profile::standard
    include ::profile::dns::auth
}
