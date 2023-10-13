# SPDX-License-Identifier: Apache-2.0
# Provision an apache virtualhost to reverse-proxy AM API access

class profile::alertmanager::api (
    # lint:ignore:wmf_styleguide - T260574
    String $vhost  = lookup('profile::alertmanager::api::vhost', {'default_value' => "alertmanager.${facts['domain']}"}),
    Optional[String] $vhost_alias  = lookup('profile::alertmanager::api::vhost_alias', {'default_value' => undef}),
    # lint:endignore
    Array[Httpd::RequireHostIP] $ro = lookup('profile::alertmanager::api::ro'),
    Array[Httpd::RequireHostIP] $rw = lookup('profile::alertmanager::api::rw'),
) {

    $ro_hosts = $ro.filter |$el| { $el =~ Stdlib::Fqdn }
    $ro_ips = $ro.filter |$el|   { $el =~ Stdlib::IP::Address }
    $rw_hosts = $rw.filter |$el| { $el =~ Stdlib::Fqdn }
    $rw_ips = $rw.filter |$el|   { $el =~ Stdlib::IP::Address }

    httpd::site { $vhost:
        content => template('profile/alertmanager/api.apache.erb'),
    }

    package { 'libapache2-mod-security2':
        ensure => present
    }

    httpd::mod_conf { 'security2':
    }
}
