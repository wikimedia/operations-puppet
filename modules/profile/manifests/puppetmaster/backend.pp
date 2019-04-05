# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class profile::puppetmaster::backend(
    $config = hiera('profile::puppetmaster::backend::config', {}),
    # should $secure_priviate really get its config from the same
    # place as $config?
    $secure_private = hiera('profile::puppetmaster::backend::config', true),
    $prevent_cherrypicks = hiera('profile::puppetmaster::backend::prevent_cherrypicks', true),
    Stdlib::Host $ca_server = lookup('puppet_ca_server'),
    $puppetmasters = hiera('puppetmaster::servers'),
    $puppetdb_major_version = hiera('puppetdb_major_version', undef),
    $allow_from = [
      '*.wikimedia.org',
      '*.eqiad.wmnet',
      '*.ulsfo.wmnet',
      '*.esams.wmnet',
      '*.codfw.wmnet',
      '*.eqsin.wmnet'],
    $extra_auth_rules = '',
) {

    $common_config = {
        'ca'              => false,
        'ca_server'       => $ca_server,
        'stringify_facts' => false,
    }
    $base_config = merge($config, $common_config)

    class { '::profile::puppetmaster::common':
        base_config => $base_config,
    }

    class { '::puppetmaster':
        server_type            => 'backend',
        config                 => $::profile::puppetmaster::common::config,
        secure_private         => $secure_private,
        prevent_cherrypicks    => $prevent_cherrypicks,
        allow_from             => $allow_from,
        extra_auth_rules       => $extra_auth_rules,
        puppetdb_major_version => $puppetdb_major_version,
    }

    $puppetmaster_frontend_ferm = join(keys($puppetmasters), ' ')
    ferm::service { 'ssh_puppet_merge':
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${puppetmaster_frontend_ferm})) @resolve((${puppetmaster_frontend_ferm}), AAAA))"
    }
    ferm::service { 'puppetmaster-backend':
        proto  => 'tcp',
        port   => 8141,
        srange => "(@resolve((${puppetmaster_frontend_ferm})) @resolve((${puppetmaster_frontend_ferm}), AAAA))"
    }
    require ::profile::conftool::client
}
