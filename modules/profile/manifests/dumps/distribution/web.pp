# SPDX-License-Identifier: Apache-2.0
class profile::dumps::distribution::web (
    Boolean $is_primary_server = lookup('profile::dumps::distribution::web::is_primary_server'),
    Stdlib::Host $dumps_active_web_server = lookup('dumps_dist_active_web'),
    Stdlib::Unixpath $datadir = lookup('profile::dumps::distribution::basedatadir'),
    Stdlib::Unixpath $xmldumpsdir = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    Stdlib::Unixpath $miscdatasetsdir = lookup('profile::dumps::distribution::miscdumpsdir'),
    String $blocked_user_agent_regex = lookup('profile::dumps::distribution::blocked_user_agent_regex'),
){
    class { '::sslcert::dhparam': }
    class {'::dumps::web::xmldumps':
        web_hostname             => 'dumps.wikimedia.org',
        datadir                  => $datadir,
        xmldumpsdir              => $xmldumpsdir,
        miscdatasetsdir          => $miscdatasetsdir,
        htmldumps_server         => 'htmldumper1001.eqiad.wmnet',
        webuser                  => 'dumpsgen',
        webgroup                 => 'dumpsgen',
        blocked_user_agent_regex => $blocked_user_agent_regex,
    }

    # copy web server logs to stat host
    if $is_primary_server {
        class {'::dumps::web::rsync::nginxlogs':
          dest => 'stat1011.eqiad.wmnet::dumps-webrequest/',
        }
    }

    ferm::service { 'xmldumps_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'xmldumps_https':
        proto => 'tcp',
        port  => '443',
    }

    class { '::dumps::web::enterprise':
        is_primary_server => $is_primary_server,
        dumps_web_server  => $dumps_active_web_server,
        user              => 'dumpsgen',
        group             => 'dumpsgen',
        miscdumpsdir      => $miscdatasetsdir,
    }
}
