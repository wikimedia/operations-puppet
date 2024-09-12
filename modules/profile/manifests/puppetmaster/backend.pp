# SPDX-License-Identifier: Apache-2.0
# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab
# @summray  config puppetmaster backends
# @param config addtional config to use
# @param secure_private If false, /etc/puppet/private will be labs/private.git.
#   Otherwise, some magic is done to have local repositories and sync between puppetmasters.
# @param ca_server the CA server
# @param prevent_cherrypicks disable cherry picks
# @param extra_auth_rules Addtional auth rules
# @param servers list of puppetmaster backend servers with wieghts
class profile::puppetmaster::backend(
    Stdlib::Host                         $ca_server           = lookup('puppet_ca_server'),
    Hash[String, Puppetmaster::Backends] $servers             = lookup('puppetmaster::servers'),
    Hash                                 $config              = lookup('profile::puppetmaster::backend::config'),
    Boolean                              $secure_private      = lookup('profile::puppetmaster::backend::secure_private'),
    Boolean                              $prevent_cherrypicks = lookup('profile::puppetmaster::backend::prevent_cherrypicks'),
    Optional[String]                     $extra_auth_rules    = lookup('profile::puppetmaster::backend::extra_auth_rules'),
    Array[String] $puppetservers                         = lookup('profile::puppetmaster::backend::puppetservers'),
    Optional[Stdlib::Host]               $puppet_merge_server = lookup('puppet_merge_server'),
) {

    ensure_packages(['libapache2-mod-passenger'])

    $common_config = {
        'ca'              => false,
        'ca_server'       => $ca_server,
        'stringify_facts' => false,
    }
    $base_config = merge($config, $common_config)

    class { 'profile::puppetmaster::common':
        base_config => $base_config,
    }

    class { 'httpd':
        remove_default_ports => true,
        modules              => ['passenger'],
    }

    class { 'puppetmaster':
        server_type         => 'backend',
        hiera_config        => $profile::puppetmaster::common::hiera_config,
        config              => $profile::puppetmaster::common::config,
        secure_private      => $secure_private,
        prevent_cherrypicks => $prevent_cherrypicks,
        extra_auth_rules    => $extra_auth_rules,
        netbox_hiera_enable => $profile::puppetmaster::common::netbox_hiera_enable,
        enable_merge_cli    => $profile::puppetmaster::common::enable_merge_cli,
        ca_server           => $ca_server,
        servers             => $servers,
        puppet_merge_server => $puppet_merge_server,
    }

    $puppetservers_puppetmasters_ferm = join($puppetservers + keys($servers), ' ')
    ferm::service { 'ssh_puppet_merge':
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${puppetservers_puppetmasters_ferm})))",
    }
    ferm::service { 'puppetmaster-backend':
        proto  => 'tcp',
        port   => 8141,
        srange => $servers.keys,
    }
    include profile::conftool::client
}
