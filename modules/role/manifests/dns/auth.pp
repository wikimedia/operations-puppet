class role::dns::auth {
    system::role { 'dns::auth': description => 'Authoritative DNS server' }

    include ::profile::base::production
    include ::profile::dns::auth
}
