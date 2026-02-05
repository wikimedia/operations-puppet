# SPDX-License-Identifier: Apache-2.0
class profile::dumps::distribution::web (
    Boolean                    $is_primary_server        = lookup('profile::dumps::distribution::web::is_primary_server'),
    Stdlib::Unixpath           $datadir                  = lookup('profile::dumps::distribution::basedatadir'),
    Stdlib::Unixpath           $xmldumpsdir              = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    Stdlib::Unixpath           $miscdatasetsdir          = lookup('profile::dumps::distribution::miscdumpsdir'),
    Array[Stdlib::IP::Address] $cache_hosts              = lookup('cache_hosts'),
    String[1]                  $blocked_user_agent_regex = lookup('profile::dumps::distribution::blocked_user_agent_regex'),
    Array[Stdlib::IP::Address] $blocked_cidrs            = lookup('profile::dumps::distribution::blocked_cidrs', { default_value => [] }),
) {
    class { 'sslcert::dhparam': }
    class { 'dumps::web::xmldumps':
        web_hostname             => 'dumps.wikimedia.org',
        datadir                  => $datadir,
        xmldumpsdir              => $xmldumpsdir,
        miscdatasetsdir          => $miscdatasetsdir,
        webuser                  => 'dumpsgen',
        webgroup                 => 'dumpsgen',
        cache_hosts              => $cache_hosts,
        blocked_user_agent_regex => $blocked_user_agent_regex,
        blocked_cidrs            => $blocked_cidrs,
    }

    # copy web server logs to stat host
    class { 'dumps::web::rsync::nginxlogs':
        ensure => $is_primary_server.bool2str('present', 'absent'),
        dest   => 'stat1011.eqiad.wmnet::dumps-webrequest/',
    }

    ferm::service { 'xmldumps_http':
        proto => 'tcp',
        port  => '80',
        qos   => 'low',
    }

    ferm::service { 'xmldumps_https':
        proto => 'tcp',
        port  => '443',
        qos   => 'low',
    }
}
