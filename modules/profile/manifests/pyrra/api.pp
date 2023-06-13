# SPDX-License-Identifier: Apache-2.0
# == Class: profile::pyrra::api
#
# = Parameters
# [*http_servername*] ServerName for apache virtual host reverse proxying the web ui

class profile::pyrra::api (
    String $http_servername = lookup('profile::pyrra::api::http_servername', { 'default_value' => 'slo.wikimedia.org' }),
) {

    class { 'pyrra::api': }

    # reverse proxy pyrra-api for public access to web interface
    httpd::site { $http_servername:
        content => template('profile/apache/sites/pyrra.erb'),
    }

}
