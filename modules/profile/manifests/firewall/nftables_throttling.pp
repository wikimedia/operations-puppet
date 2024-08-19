# SPDX-License-Identifier: Apache-2.0
# @summary manage backup timers
# @throttle_packets number of packets clients are allowed to do in a 1 minute time frame
# @throttle_duration duration how long clients are banned in seconds
# @nft_policy whether to actually drop packets or to accept them (for logging-only / testing)
# @nft_logging whether to log firewall actions to /var/log/messages or not
# @port tcp port which is throttled (default 443)
# @allowed_burst_packets optional number of packets that can exceed the ratelimit:
class profile::firewall::nftables_throttling (
    Wmflib::Ensure $ensure = lookup('profile::firewall::nftables_throttling::ensure',
    {default_value => present}),
    Integer $throttle_packets = lookup('profile::firewall::nftables_throttling::throttle_packets',
    {default_value => 300}), # allow 300 requests per minute
    Integer $throttle_duration = lookup('profile::firewall::nftables_throttling::throttle_duration',
    {default_value => 300}), # ban clients above for 300 seconds
    Enum['accept', 'drop'] $nft_policy = lookup('profile::firewall::nftables_throttling::nft_policy',
    {default_value => 'accept'}),
    Boolean $nft_logging = lookup('profile::firewall::nftables_throttling::nft_logging',
    {default_value => false}),
    Integer $port = lookup('profile::firewall::nftables_throttling::port',
    {default_value => 443}),
    Optional[Integer] $allowed_burst_packets = lookup('profile::firewall::nftables_throttling::allowed_burst_packets',
    {default_value => undef }),
) {

    $nft_do_log = $nft_logging ? {
        true    => 'log ',
        default => '',
    }

    # add throttling nftables chain T366882
    nftables::file { 'throttling-chain':
        ensure  => $ensure,
        order   => 99,
        content => template('profile/firewall/throttling.nft.erb'),
    }
}
