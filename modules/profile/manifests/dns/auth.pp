class profile::dns::auth {
    include ::profile::dns::ferm
    include ::profile::dns::auth::acmechief_target
    include ::profile::dns::auth::monitoring
    include ::profile::dns::auth::discovery
    include ::profile::dns::auth::config
    include ::profile::dns::auth::update
    include ::profile::dns::auth::perf

    class { 'gdnsd': }
}
