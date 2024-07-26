# SPDX-License-Identifier: Apache-2.0
# == Define prometheus::web
#
# Provision a reverse proxy with apache towards a prometheus instance.
#
# = Parameters
#
# [*proxy_pass*]
#   The address to proxy to, usually in the form of
#   'http://localhost:<prometheus_port>/<prometheus_name>'
#
# [*maxconn*]
#   The maximum number of connections per Apache worker to the instance.
#   Keep under ThreadsPerChild setting (25 default) to ensure a single slow
#   Prometheus instance does not starve other instances on the same host.
#
# [*homepage*]
#   Redirect to this instance from the homepage (i.e. /)
#
# [*redirect_url*]
#   The URL relative to '/' that will be redirected from, usually just $title.

define prometheus::web (
    String $proxy_pass,
    Wmflib::Ensure $ensure = present,
    Integer $maxconn = 10,
    Boolean $homepage = false,
    String $redirect_url = $title,
) {
    include ::prometheus

    # Apache configuration snippet with proxy pass.
    $title_safe  = regsubst($title, '[\W_]', '-', 'G')
    file { "/etc/apache2/prometheus.d/${title_safe}.conf":
        ensure  => $ensure,
        content => template('prometheus/prometheus-apache.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    # Single prometheus apache site, will include /etc/prometheus-apache/*.conf
    if !defined(Httpd::Site['prometheus']) {
        httpd::site{ 'prometheus':
            content => template('prometheus/prometheus-apache-vhost.erb'),
        }
    }
}
