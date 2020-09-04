# == Class: profile::webperf::arclamp
#
# Provision Arc Lamp, which processes PHP stack traces and generates
# SVG flame graphs. This profile also provisions an HTTP server
# exposing the trace logs and SVG flame graphs.
#
# See also profile::webperf::site, which provisions a reverse proxy
# to expose the data at <https://performance.wikimedia.org/arclamp/>.
#
# === Parameters
#
# [*redis_host*]
#   Address of Redis server that is publishing stack traces.
#
# [*redis_port*]
#   Port of Redis server that is publishing stack traces (usually port 6379).
#
# [*errors_mailto*]
#   Email address for cron errors (usually performance-team@wikimedia.org)
#
class profile::webperf::arclamp (
    Stdlib::Fqdn $redis_host    = lookup('profile::webperf::arclamp::redis_host'),
    Stdlib::Port $redis_port    = lookup('profile::webperf::arclamp::redis_port'),
    String       $errors_mailto = lookup('profile::webperf::arclamp::errors_mailto'),
){

    class { 'arclamp':
        redis_host    => $redis_host,
        redis_port    => $redis_port,
        errors_mailto => $errors_mailto,
    }

    httpd::site { 'arclamp':
        content => template('profile/webperf/arclamp/httpd.conf.erb'),
    }

    ferm::service { 'arclamp_http':
        proto => 'tcp',
        port  => '80',
    }

    backup::set { 'arclamp-application-data': }
}
