# SPDX-License-Identifier: Apache-2.0
# == Class: chartmuseum
#
# This class installs and configures ChartMuseum, a Helm chart repository server.
#
# === Parameters:
# [*listen_host*] Listen on this interface only.
#
# [*listen_port*] TCP port to listen on.
#
# [*repository_depth*] Level of nested repositories for multitenancy. A value
#                      of 0 allows only one repository, whereas a level of 2
#                      supports a structure like:
#   charts
#   ├── org1
#   │   ├── repoa
#   │   │   └── nginx-ingress-0.9.3.tgz
#   ├── org2
#   │   ├── repob
#   │   │   └── chartmuseum-0.4.0.tgz
#
# [*disable_delete*] Do not allow charts to be deleted via API.
#
# [*disable_force_overwrite*] Do not allow charts to be overwritten, even with
#                             "?force" querystring.
#
# [*allow_anonymous_get*] Allow anonymous HTTP GET operations even when basic
#                         auth is enabled.
#
# [*cache_interval*] Intervall in which to check the storage backend for
#                    changes/re-read index-cache.yaml from the backend. For
#                    valid values for this setting, please see:
#                    https://godoc.org/time#ParseDuration
#
# [*swift_backend*] Optional configuration of a Swift storage backend (URL,
#                   container name, username and password). If this parameter is
#                   not set, local storage in "/var/lib/chartmuseum" is used.
#
# [*basic_auth*] Optional username and password to enable HTTP basic auth.
#
# [*debug*] Show debug messages in log.
#
class chartmuseum (
    Stdlib::Host                        $listen_host             = '0.0.0.0',
    Stdlib::Port::Unprivileged          $listen_port             = 8080,
    Integer[0]                          $repository_depth        = 1,
    Boolean                             $disable_delete          = true,
    Boolean                             $disable_force_overwrite = true,
    Boolean                             $allow_anonymous_get     = true,
    String                              $cache_interval          = '60s',
    Optional[ChartMuseum::SwiftBackend] $swift_backend           = undef,
    Optional[ChartMuseum::BasicAuth]    $basic_auth              = undef,
    Optional[Boolean]                   $debug                   = false,
) {
    package { 'chartmuseum':
        ensure => present,
    }

    file { '/etc/chartmuseum/chartmuseum.yaml':
        ensure  => file,
        mode    => '0440',
        owner   => 'root',
        group   => 'chartmuseum',
        content => template('chartmuseum/chartmuseum.yaml.erb'),
        notify  => Service[chartmuseum],
    }

    file { '/etc/default/chartmuseum':
        ensure  => file,
        mode    => '0440',
        owner   => 'root',
        group   => 'root',
        content => template('chartmuseum/chartmuseum.defaults.erb'),
        notify  => Service[chartmuseum],
    }

    service { 'chartmuseum':
        ensure  => running,
        require => Package['chartmuseum'],
    }
}
