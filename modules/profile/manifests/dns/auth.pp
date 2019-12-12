class profile::dns::auth(
    Boolean $test_dot = lookup('profile::dns::auth::test_dot', {'default_value' => false}),
) {
    include ::profile::dns::auth::acmechief_target
    include ::profile::dns::auth::monitoring
    include ::profile::dns::auth::discovery
    include ::profile::dns::auth::config
    include ::profile::dns::auth::update
    if $test_dot {
        include ::profile::dns::auth::dotls
    }
    include ::profile::dns::auth::perf

    class { 'gdnsd': }
}
