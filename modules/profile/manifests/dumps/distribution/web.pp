# SPDX-License-Identifier: Apache-2.0
class profile::dumps::distribution::web (
    Stdlib::Unixpath           $datadir                  = lookup('profile::dumps::distribution::basedatadir'),
    Stdlib::Unixpath           $xmldumpsdir              = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    Stdlib::Unixpath           $miscdatasetsdir          = lookup('profile::dumps::distribution::miscdumpsdir'),
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
        blocked_user_agent_regex => $blocked_user_agent_regex,
        blocked_cidrs            => $blocked_cidrs,
    }

    # copy web server logs to stat host
    class { 'dumps::web::rsync::nginxlogs':
        dest => "stat1011.eqiad.wmnet::dumps-webrequest/${facts['networking']['fqdn']}/",
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
