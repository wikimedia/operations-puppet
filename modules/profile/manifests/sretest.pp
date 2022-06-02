# @summary profile for sretest hosts
class profile::sretest {
    if debian::codename::eq('buster') {
        include profile::docker::firewall
        include profile::base::cuminunpriv
    }

    profile::contact { $title:
        contacts => ['jbond', 'jmm'],
    }

    $cache_nodes = lookup('cache::nodes')  # lint:ignore:wmf_styleguide
    file {'/var/tmp/testing':
        ensure  => directory,
        recurse => true,
        purge   => true,
    }
    @@file { '/var/tmp/testing/wmflib_resource_reduce.txt':
        ensure  => 'file',
        content => 'testing',
        tag     => 'foo::bar',
    }
    wmflib::resource::reduce('file', undef, {'tag' => 'foo::bar'})
}
