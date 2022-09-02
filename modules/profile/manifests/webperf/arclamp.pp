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
#   Email address to send errors to
#
# [*compress_logs_days*]
#   How many days to wait before compressing logs.
#
# [*retain_hourly_logs_hours*]
#   How many hourly captures to retain on local disk.
#
# [*retain_daily_logs_days*]
#   How many daily captures to retain on local disk.
#
class profile::webperf::arclamp (
    Stdlib::Fqdn $redis_host                 = lookup('profile::webperf::arclamp::redis_host'),
    Stdlib::Port $redis_port                 = lookup('profile::webperf::arclamp::redis_port'),
    String $errors_mailto                    = lookup('profile::webperf::arclamp::errors_mailto'),
    Integer $compress_logs_days              = lookup('profile::webperf::arclamp::compress_logs_days'),
    Integer $retain_hourly_logs_hours        = lookup('profile::webperf::arclamp::retain_hourly_logs_hours'),
    Integer $retain_daily_logs_days          = lookup('profile::webperf::arclamp::retain_daily_logs_days'),
    Hash[String, Hash] $swift_accounts       = lookup('profile::swift::accounts'),
    Hash[String, String] $swift_account_keys = lookup('profile::swift::accounts_keys'),
) {
    class { 'arclamp':
        redis_host               => $redis_host,
        redis_port               => $redis_port,
        errors_mailto            => $errors_mailto,
        compress_logs_days       => $compress_logs_days,
        retain_hourly_logs_hours => $retain_hourly_logs_hours,
        retain_daily_logs_days   => $retain_daily_logs_days,
        swift_account_name       => $swift_accounts['performance_arclamp']['account_name'],
        swift_auth_url           => $swift_accounts['performance_arclamp']['auth'],
        swift_user               => $swift_accounts['performance_arclamp']['user'],
        swift_key                => $swift_account_keys['performance_arclamp'],
    }

    httpd::site { 'arclamp':
        content => template('profile/webperf/arclamp/httpd.conf.erb'),
    }

    ferm::service { 'arclamp_http':
        proto => 'tcp',
        port  => '80',
    }

    backup::set { 'arclamp-application-data': }

    profile::auto_restarts::service { 'apache2': }
}
