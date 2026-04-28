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
        description => 'gNMIc user'
    }

    $config = wmflib::resource::filter_params('tls_ca') + {
        'tls-ca' => $tls_ca,
        'api-server' => {'address' => ':7890', 'enable-metrics' => true},
        'retry' => '5m',
    }

    # Need to notify as gnmic doesn't watches the config file well enough
    file { '/etc/gnmic.yaml':
        ensure  => file,
        mode    => '0400',  # contains password
        owner   => 'gnmic',
        group   => 'gnmic',
        content => $config.to_yaml,
        notify  => Service['gnmic']
    }

    systemd::service { 'gnmic':
        content => template('gnmic/gnmic.service.erb'),
        require => Package['gnmic'],
        restart => true
    }

    profile::auto_restarts::service { 'gnmic': }
}
