# SPDX-License-Identifier: Apache-2.0
class profile::ncmonitor(
    Array[Stdlib::Host]       $nameservers = lookup('profile::ncmonitor::nameservers'),
    Optional[Stdlib::HTTPUrl] $http_proxy  = lookup('http_proxy'),
) {
    include passwords::ncmonitor::markmonitor

    class { 'ncmonitor':
        nameservers      => $nameservers,
        markmon_api_user => $passwords::ncmonitor::markmonitor::api_user,
        markmon_api_pass => $passwords::ncmonitor::markmonitor::api_password,
        http_proxy       => $http_proxy,
        ensure           => present,
    }

}
