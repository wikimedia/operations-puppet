# SPDX-License-Identifier: Apache-2.0
# Class: dispatch::web
#
# Actions:
#   Setup a Dispatch web frontend
#
# Parameters:
#   $db_hostname      DB to connect to
#   $db_password      DB password to use
#   $port             port to listen on
#   $encryption_key   the session encryption key to use
#   $version          the dispatch container version to deploy
#   $env_extra        extra environment variables to set
#   $scheduler_ensure whether or not to run the scheduler
#   $vhost            the Apache virtual host to answer on
#   $log_level        the dispatch log level

class dispatch::web (
    String[1]                     $db_hostname,
    String[1]                     $db_password,
    Stdlib::Port::User            $port,
    String[1]                     $encryption_key,
    String[1]                     $version          = 'latest',
    Hash[String, String]          $env_extra        = {},
    Wmflib::Ensure                $scheduler_ensure = absent,
    String                        $vhost            = 'dispatch',
    Wmflib::Syslog::Level::Python $log_level        = 'INFO',
) {
    $registry = 'docker-registry.wikimedia.org'
    $image = 'dispatch'

    $env_base = {
        'DISPATCH_ENCRYPTION_KEY'                      => $encryption_key,
        'DATABASE_HOSTNAME'                            => $db_hostname,
        'DATABASE_CREDENTIALS'                         => "dispatch:${db_password}",
        'DISPATCH_UI_URL'                              => "https://${vhost}",
        'LOG_LEVEL'                                    => $log_level,
    }

    $env = deep_merge($env_base, $env_extra)

    $wrapper = @("WRAPPER")
    #!/bin/sh
    docker run --interactive --tty --env-file /etc/dispatch/env --network host ${registry}/${image}:${version} $@
    | WRAPPER

    file { '/usr/local/bin/dispatch':
        content => $wrapper,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    service::docker { 'dispatch':
        image_name   => $image,
        version      => $version,
        port         => $port, # ignored when in host_network mode
        environment  => $env,
        host_network => true,
        override_cmd => "server start dispatch.main:app --port ${port}",
    }

    service::docker { 'dispatch-scheduler':
        ensure       => $scheduler_ensure,
        image_name   => $image,
        version      => $version,
        port         => $port, # ignored when in host_network mode
        environment  => $env,
        host_network => true,
        override_cmd => 'scheduler start',
    }

    class { 'dispatch::ldap_sync':
        ensure => $scheduler_ensure,
    }
}
