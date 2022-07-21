# SPDX-License-Identifier: Apache-2.0
# = Class: docker_registry_ha::web
#
# This class sets up nginx to proxy and provide access control
# in front of a docker-registry.
#
# There are 3 groups of users:
# * restricted-push - can push any image
# * restricted-read - can read restricted images
# * regular-push - can push non-restricted images
#
# TODO: Refactor this to be a flexible ACL system, similar to etcd::tlsproxy
#
class docker_registry_ha::web (
    String $ci_restricted_user_password,
    String $kubernetes_user_password,
    String $ci_build_user_password,
    String $prod_build_user_password,
    String $password_salt,
    Array[Stdlib::Host] $allow_push_from,
    Array[String] $ssl_settings,
    Boolean $use_puppet_certs=false,
    Optional[String] $ssl_certificate_name=undef,
    Array[Stdlib::Host] $http_allowed_hosts=[],
    Array[Stdlib::IP::Address::Nosubnet] $jwt_allowed_ips=[],
    Stdlib::HTTPUrl $jwt_keys_url='https://gitlab.wikimedia.org/-/jwks',
    Stdlib::Host $jwt_issuer='gitlab.wikimedia.org',
    Boolean $read_only_mode=false,
    String $homepage='/srv/homepage',
    Boolean $nginx_cache=true,
    Array[Stdlib::Host] $deployment_hosts=[],
) {
    if (!$use_puppet_certs and ($ssl_certificate_name == undef)) {
        fail('Either puppet certs should be used, or an ssl cert name should be provided')
    }

    if $use_puppet_certs {
        # TODO: consider using profile::pki::get_cert
        puppet::expose_agent_certs { '/etc/nginx':
            ensure          => present,
            provide_private => true,
            require         => Class['nginx'],
        }
    }

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
        require => Package['nginx-common'],
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
        require => Package['nginx-common'],
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
        require => Package['nginx-common'],
    }

    # Find k8s nodes that have auth credentials (for restricted/)
    # TODO: Use inventory[certname, facts.networking.ip] when we have puppetdb >= 6.7
    $pql = @(PQL)
    facts[certname, value] {
        name = 'ipaddress' and
        resources { type = 'File' and title = '/var/lib/kubelet/config.json' } and
        resources { type = 'Class' and title = 'K8s::Kubelet' }
    }
    | PQL
    $k8s_authenticated_nodes = Hash(wmflib::puppetdb_query($pql).map |$res| { [$res['certname'], $res['value']] }.sort)

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
        issuer              => $jwt_issuer,
        validation_template => 'puppet:///modules/docker_registry_ha/jwt-validations.tmpl',
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
