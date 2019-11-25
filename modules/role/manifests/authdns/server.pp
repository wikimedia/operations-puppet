# This is for an authdns server to use
class role::authdns::server {
    system::role { 'authdns': description => 'Authoritative DNS server' }

    include ::profile::standard
    include ::profile::dns::auth
}
