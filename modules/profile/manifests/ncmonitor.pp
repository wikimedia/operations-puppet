# SPDX-License-Identifier: Apache-2.0
class profile::ncmonitor(
    Array[Stdlib::Host]       $nameservers = lookup('profile::ncmonitor::nameservers'),
    Optional[Stdlib::HTTPUrl] $http_proxy  = lookup('http_proxy'),
) {

    class { 'ncmonitor':
        nameservers      => $nameservers,
        markmon_api_user => 'temporary_for_passwords_removal',
        markmon_api_pass => 'temporary_for_passwords_removal',
        http_proxy       => $http_proxy,
        ensure           => present,
    }

}
