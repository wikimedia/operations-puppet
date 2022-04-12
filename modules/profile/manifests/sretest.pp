# @summary profile for sretest hosts
# @param http_proxy the http proxy to use
class profile::sretest (
    Optional[Stdlib::HTTPUrl] $http_proxy = lookup('http_proxy'),
) {
    if debian::codename::eq('buster') {
        include profile::docker::firewall
        include profile::base::cuminunpriv
    }

    profile::contact { $title:
        contacts => ['jbond', 'jmm'],
    }
    class { 'external_clouds_vendors':
        ensure     => absent,
        http_proxy => $http_proxy,
    }

    $cache_nodes = lookup('cache::nodes')  # lint:ignore:wmf_styleguide
    file {'/var/tmp/testing':
        ensure => directory,
    }
    file {'/var/tmp/testing/cache.nodes.eqsin.pdb':
        ensure  => file,
        content => wmflib::role_hosts('cache::upload', 'eqsin').to_yaml,
    }
    file {'/var/tmp/testing/cache.nodes.eqsin.hiera':
        ensure  => file,
        content => $cache_nodes['upload']['eqsin'].to_yaml,
    }
    file {'/var/tmp/testing/cache.nodes.eq.pdb':
        ensure  => file,
        content => wmflib::role_hosts('cache::upload', ['eqsin', 'eqiad']).to_yaml,
    }
    file {'/var/tmp/testing/cache.nodes.eq.hiera':
        ensure  => file,
        content => ($cache_nodes['upload']['eqsin'] + $cache_nodes['upload']['eqiad']).to_yaml,
    }
    file {'/var/tmp/testing/cache.nodes.pdb':
        ensure  => file,
        content => wmflib::role_hosts('cache::upload').to_yaml,
    }
    file {'/var/tmp/testing/cache.nodes.hiera':
        ensure  => file,
        content => $cache_nodes['upload'].to_yaml,
    }
}
