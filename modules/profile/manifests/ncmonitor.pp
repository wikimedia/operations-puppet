# SPDX-License-Identifier: Apache-2.0
class profile::ncmonitor(
    Array[Stdlib::Host]       $nameservers       = lookup('profile::ncmonitor::nameservers'),
    Optional[Stdlib::HTTPUrl] $http_proxy        = lookup('http_proxy'),
    String                    $mm_api_user       = lookup('profile::ncmonitor::markmonitor_api_user'),
    String                    $mm_api_pass       = lookup('profile::ncmonitor::markmonitor_api_password'),
    String                    $gerrit_ssh_key    = lookup('profile::ncmonitor::gerrit_ssh_key'),
    String                    $gerrit_ssh_pubkey = lookup('profile::ncmonitor::gerrit_ssh_pubkey'),
) {
    class { 'ncmonitor':
        nameservers       => $nameservers,
        markmon_api_user  => $mm_api_user,
        markmon_api_pass  => $mm_api_pass,
        gerrit_ssh_key    => $gerrit_ssh_key,
        gerrit_ssh_pubkey => $gerrit_ssh_pubkey,
        http_proxy        => $http_proxy,
        ensure            => present,
    }

}
