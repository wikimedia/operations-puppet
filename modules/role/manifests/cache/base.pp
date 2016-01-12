class role::cache::base(
    $zero_site = 'https://zero.wikimedia.org',
    $purge_host_only_upload_re = '^upload\.wikimedia\.org$',
    $purge_host_not_upload_re = '^(?!upload\.wikimedia\.org)',
    $static_host = 'www.wikimedia.org',
    $upload_domain = 'upload.wikimedia.org',
    $bits_domain = 'bits.wikimedia.org',
    $top_domain = 'org'
) {
    include standard
    include nrpe
    include lvs::configuration
    include role::cache::configuration
    include role::cache::statsd
    include network::constants
    include conftool::scripts

    # Only production needs these system perf tweaks
    if $::realm == 'production' {
        include role::cache::perf
    }

    # Not ideal factorization to put this here, but works for now
    class { 'varnish::zero_update':
        site         => $zero_site,
        auth_content => secret('misc/zerofetcher.auth'),
    }
}
