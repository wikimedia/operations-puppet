# SPDX-License-Identifier: Apache-2.0
class profile::codesearch (
    Stdlib::Unixpath $base_dir = lookup('profile::codesearch::base_dir'),
    String[1] $gunicorn_package = lookup('profile::codesearch::gunicorn_package', {'default_value' => 'gunicorn3'}),
    Hash[String, Integer] $ports = lookup('profile::codesearch::ports'),
    Integer $lock_file_min_age = lookup('profile::codesearch::lock_file_min_age'),
    Boolean $tls_proxy = lookup('profile::codesearch::tls_proxy', {'default_value' => false}),
    String[1] $frontend_image = lookup('profile::codesearch::frontend_image', {'default_value' => 'codesearch-frontend'}),
    Stdlib::Port $frontend_port = lookup('profile::codesearch::frontend_port', {'default_value' => 80}),
    Optional[Stdlib::HTTPSUrl] $hound_base_public = lookup('profile::codesearch::hound_base_public', {'default_value' => undef}),
) {

    # envoy terminates TLS for the CDN in production
    if $tls_proxy {
        include profile::tlsproxy::envoy
    }

    ferm::conf { 'docker-preserve':
        ensure => present,
        prio   => 20,
        source => 'puppet:///modules/codesearch/ferm/docker-preserve.conf',
    }

    ferm::service { 'codesearch':
        proto  => 'tcp',
        port   => '3002',
        # Disallow direct access from other WMCS projects. They must use the
        # stable (and rate-limited) codesearch-backend.wmcloud.org URL instead.
        #
        # Allow access from local Docker containers (e.g. codesearch-frontend)
        # https://phabricator.wikimedia.org/T361899
        srange => '($CACHES 172.17.0.0/16)',
    }

    class { '::codesearch':
        base_dir          => $base_dir,
        gunicorn_package  => $gunicorn_package,
        ports             => $ports,
        lock_file_min_age => $lock_file_min_age,
        frontend_image    => $frontend_image,
        frontend_port     => $frontend_port,
        hound_base_public => $hound_base_public,
    }
}
