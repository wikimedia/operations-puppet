# SPDX-License-Identifier: Apache-2.0
# == Class: gnmic
#
# Install and manage gnmic
#
# === Parameters
#
# @param TODO

class gnmic(
    Hash[String, Hash] $outputs,
    String             $password,
    Hash[String, Hash] $processors,
    Hash[String, Hash] $targets,
    String             $username,
    Hash[String, Hash] $subscriptions,
    Stdlib::Unixpath   $tls_ca = $facts['puppet_config']['localcacert']
  ){
    ensure_packages(['gnmic'])

    systemd::sysuser { 'gnmic':
        id          => '926:926',  # https://wikitech.wikimedia.org/wiki/UID
        description => 'gNMIc user'
    }

    $config = wmflib::resource::filter_params('tls_ca') + {
        'tls-ca' => $tls_ca,
    }

    # No need for notify as gnmic watches the config file
    file { '/etc/gnmic.yaml':
        ensure  => file,
        mode    => '0400',  # contains password
        owner   => 'gnmic',
        group   => 'gnmic',
        content => $config.to_yaml,
    }

    systemd::service { 'gnmic':
        content => template('gnmic/gnmic.service.erb'),
        require => Package['gnmic'],
        restart => true
    }

    profile::auto_restarts::service { 'gnmic': }
}
