# SPDX-License-Identifier: Apache-2.0
#
# @summary This class sets up nginx to proxy and provide access control
# in front of a docker-registry.
#
# There are 3 groups of users:
# * restricted-push - can push any image
# * restricted-read - can read restricted images
# * regular-push - can push non-restricted images
#
# @param ci_restricted_user_password password used by restricted ci
# @param kubernetes_user_password password used by kubernetes
# @param ci_build_user_password password for ci build
# @param prod_build_user_password password for production build user
# @param password_salt passowrd salt
# @param allow_push_from a list of hosts allowed to push
# @param ssl_settings an array of ssl settings
# @param ssl_paths the ssl file paths to use
# @param jwt_allowed_ips A list of ips allowd to use jwt
# @param jwt_keys_url The jwt keys url
# @param jwt_issuers The jwt keys issuer
# @param read_only_mode enable readonly mode
# @param homepage the homepage doc root
# @param nginx_cache enable nginx cache
# @param deployment_hosts list of deployment hosts
# @param kubernetes_hosts list of kubernetes hosts
# TODO: Refactor this to be a flexible ACL system, similar to etcd::tlsproxy
#
class docker_registry_ha::web (
    String                               $ci_restricted_user_password,
    String                               $kubernetes_user_password,
    String                               $ci_build_user_password,
    String                               $prod_build_user_password,
    String                               $password_salt,
    Array[Stdlib::Host]                  $allow_push_from,
    Array[String]                        $ssl_settings,
    Hash                                 $ssl_paths            = undef,
    Array[Stdlib::IP::Address::Nosubnet] $jwt_allowed_ips      = [],
    Stdlib::HTTPUrl                      $jwt_keys_url         = 'https://gitlab.wikimedia.org/oauth/discovery/keys',
    Array[String]                        $jwt_issuers          = ['https://gitlab.wikimedia.org'],
    Boolean                              $read_only_mode       = false,
    String                               $homepage             = '/srv/homepage',
    Boolean                              $nginx_cache          = true,
    Array[Stdlib::Host]                  $deployment_hosts     = [],
    Array[Stdlib::Host]                  $kubernetes_hosts     = [],
) {

    # Legacy credentials
    file { '/etc/nginx/htpasswd.registry':
        ensure => absent,
    }

    # Push access to /restricted/
    $restricted_push_file = '/etc/nginx/restricted-push.htpasswd';
    $ci_restricted_user_hash = htpasswd($ci_restricted_user_password, $password_salt);
    file { $restricted_push_file:
        content => "ci-restricted:${ci_restricted_user_hash}",
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0440',
        before  => Service['nginx'],
        require => Package['nginx'],
    }

    # Read access to /restricted/
    $restricted_read_file = '/etc/nginx/restricted-read.htpasswd';
    $kubernetes_user_hash = htpasswd($kubernetes_user_password, $password_salt);
    file { $restricted_read_file:
        content => "kubernetes:${kubernetes_user_hash}\nci-restricted:${ci_restricted_user_hash}",
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0440',
        before  => Service['nginx'],
        require => Package['nginx'],
    }

    # Push access to /
    $regular_push_file = '/etc/nginx/regular-push.htpasswd';
    $ci_build_user_hash = htpasswd($ci_build_user_password, $password_salt);
    $prod_build_user_hash = htpasswd($prod_build_user_password, $password_salt);
    file { $regular_push_file:
        content => "ci-build:${ci_build_user_hash}\nprod-build:${prod_build_user_hash}\nci-restricted:${ci_restricted_user_hash}",
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0440',
        before  => Service['nginx'],
        require => Package['nginx'],
    }

    # Find k8s nodes that have auth credentials (for restricted/)
    $k8s_authenticated_nodes = Hash($kubernetes_hosts.map |$host| { [$host, ipresolve($host, 4)]}.sort)

    # Create a directory for nginx cache if enabled
    if $nginx_cache {
        $cache_dir_ensure = directory
        $cache_config_ensure = file
    } else {
        $cache_dir_ensure = absent
        $cache_config_ensure = absent
    }
    $nginx_cache_dir = '/var/cache/nginx-docker-registry'
    file { $nginx_cache_dir:
        ensure => $cache_dir_ensure,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0775',
    }

    file {'/etc/nginx/registry-nginx-cache.conf':
        ensure  => $cache_config_ensure,
        mode    => '0744',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/docker_registry_ha/registry-nginx-cache.conf',
        require => Package['nginx'],
    }

    file { '/etc/nginx/nginx.conf':
        ensure  => present,
        source  => 'puppet:///modules/docker_registry_ha/nginx.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        before  => Service['nginx'],
        require => Package['nginx-common'],
    }

    # Create a separate cache and socket location for internal auth_request
    # subrequests (see templates/registry.nginx.conf.erb)
    $nginx_auth_cache_dir = '/var/cache/nginx-auth'
    file { $nginx_auth_cache_dir:
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0700',
    }

    $nginx_auth_socket_dir = '/var/run/nginx-auth'
    $nginx_auth_socket = "${nginx_auth_socket_dir}/basic.sock"
    file { $nginx_auth_socket_dir:
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0700',
    }

    # Add a systemctl override that will allow us to clean up the nginx auth socket
    # when we stop nginx.
    # See https://trac.nginx.org/nginx/ticket/753
    systemd::unit { 'nginx':
        ensure   => present,
        content  => "[Service]\nExecStopPost=/usr/bin/rm -f ${nginx_auth_socket}",
        restart  => true,
        override => true,
    }

    # If we're allowing any hosts to use JSON Web Token auth, provision the
    # JWT authenticator service.
    $jwt_authorizer_socket = "${nginx_auth_socket_dir}/jwt.sock"
    if (!empty($jwt_allowed_ips)) {
        $jwt_authorizer_ensure = 'present'
    } else {
        $jwt_authorizer_ensure = 'absent'
    }

    jwt_authorizer::service { 'docker-registry-ha-jwt':
        ensure              => $jwt_authorizer_ensure,
        listen              => "unix://${jwt_authorizer_socket}",
        owner               => 'www-data',
        group               => 'www-data',
        keys_url            => $jwt_keys_url,
        issuers             => $jwt_issuers,
        validation_template => 'puppet:///modules/docker_registry_ha/jwt-validations.tmpl',
    }

    profile::auto_restarts::service { 'docker-registry-ha-jwt':
        ensure => $jwt_authorizer_ensure,
    }

    nginx::site { 'registry':
        content => template('docker_registry_ha/registry-nginx.conf.erb'),
    }

    ensure_packages(['python3-docker-report'])

    file { '/usr/local/bin/registry-homepage-builder':
        mode    => '0744',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/docker_registry_ha/registry-homepage-builder.py',
        require => Package['python3-docker-report'],
    }

    file { '/usr/local/lib/registry-homepage-builder.css':
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/docker_registry_ha/registry-homepage-builder.css',
    }

    file { $homepage:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # Spread out jobs so they don't all run at the same time, leading to 504s from the registry
    $minute = Integer(seeded_rand(60, "${::fqdn}-build-homepage"))
    systemd::timer::job {'build-homepage':
        ensure      => 'present',
        description => 'Build docker-registry homepage',
        command     => "/usr/local/bin/registry-homepage-builder localhost:5000 ${homepage}",
        user        => 'root',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => "*-*-* *:${minute}:00", # every hour
        },
        require     => File['/usr/local/bin/registry-homepage-builder'],
    }
}
