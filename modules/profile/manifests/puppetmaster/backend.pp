# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class profile::puppetmaster::backend(
    Hash $config = lookup('profile::puppetmaster::backend::config', {'default_value' => {}}),
    # should $secure_priviate really get its config from the same
    # place as $config?
    $secure_private = lookup('profile::puppetmaster::backend::config', {'default_value' => true}),
    Boolean $prevent_cherrypicks = lookup('profile::puppetmaster::backend::prevent_cherrypicks', {'default_value' =>  true }),
    Stdlib::Host $ca_server = lookup('puppet_ca_server'),
    Hash[String, Puppetmaster::Backends] $servers = lookup(puppetmaster::servers),
    Array[String] $allow_from = [
      '*.wikimedia.org',
      '*.eqiad.wmnet',
      '*.ulsfo.wmnet',
      '*.esams.wmnet',
      '*.codfw.wmnet',
      '*.eqsin.wmnet',
      '*.drmrs.wmnet'],
    String $extra_auth_rules = '',

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
        config              => $::profile::puppetmaster::common::config,
        secure_private      => $secure_private,
        prevent_cherrypicks => $prevent_cherrypicks,
        allow_from          => $allow_from,
        extra_auth_rules    => $extra_auth_rules,
        ca_server           => $ca_server,
        servers             => $servers,
    }

    $puppetmaster_frontend_ferm = join(keys($servers), ' ')
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
    require profile::conftool::client
}
