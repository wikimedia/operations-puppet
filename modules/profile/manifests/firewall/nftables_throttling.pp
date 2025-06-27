# SPDX-License-Identifier: Apache-2.0
# @summary manages nftables based throttling
# @max_connections number of simultaneous connections clients are allowed
# @throttle_duration duration how long clients are banned in seconds
# @nft_policy whether to actually drop packets or to accept them (for logging-only / testing)
# @nft_logging whether to log firewall actions to /var/log/messages or not
# @port tcp port which is throttled (default 443)
# @abusers list of IPs or IP ranges to drop. This IPs will be dropped even if nft_policy is set to accept.
class profile::firewall::nftables_throttling (
    Wmflib::Ensure $ensure = lookup('profile::firewall::nftables_throttling::ensure',
    {default_value => present}),
    Integer $max_connections = lookup('profile::firewall::nftables_throttling::max_connections',
    {default_value => 32}), # allow 32 parallel connections
    Integer $throttle_duration = lookup('profile::firewall::nftables_throttling::throttle_duration',
    {default_value => 300}), # ban clients above for 300 seconds
    Enum['accept', 'drop'] $nft_policy = lookup('profile::firewall::nftables_throttling::nft_policy',
    {default_value => 'accept'}),
    Boolean $nft_logging = lookup('profile::firewall::nftables_throttling::nft_logging',
    {default_value => false}),
    Integer $port = lookup('profile::firewall::nftables_throttling::port',
    {default_value => 443}),
    # TODO: Import them from confd/requestctl later T348734
    Array[Stdlib::IP::Address] $abusers = lookup('profile::firewall::nftables_throttling::abusers',
    {default_value => []}),
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

    $ensure_abusers = empty($abusers) ? {
        true    => 'absent',
        default => 'present',
    }

    # nftables has a problem with dropping of empty sets, so make sure we just create the drop rule if needed
    # Otherwise the sets have to be created with the dynamic flag
    $ipv4_abusers = $abusers.filter |$ip| { $ip =~ Stdlib::IP::Address::V4 }
    $ipv6_abusers = $abusers.filter |$ip| { $ip =~ Stdlib::IP::Address::V6 }
    $ensure_abusers_v4 = empty($ipv4_abusers) ? {
        true    => 'absent',
        default => 'present',
    }
    $ensure_abusers_v6 = empty($ipv6_abusers) ? {
        true    => 'absent',
        default => 'present',
    }

    # Create a nftables set ABUSERS and drop all traffic
    nftables::set { 'ABUSERS':
        ensure => $ensure_abusers,
        hosts  => $abusers,
    }
    nftables::file::input { 'drop-abuser-nets-v4':
        ensure  => $ensure_abusers_v4,
        order   => 9,
        content => @(EOF/L)
            ip saddr @ABUSERS_ipv4 drop
            | EOF
    }
    nftables::file::input { 'drop-abuser-nets-v6':
        ensure  => $ensure_abusers_v6,
        order   => 9,
        content => @(EOF/L)
            ip6 saddr @ABUSERS_ipv6 drop
            | EOF
    }

}
