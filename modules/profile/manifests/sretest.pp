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
    file { '/var/tmp/testing':
        ensure  => directory,
        recurse => true,
        purge   => true,
    }
    wmflib::resource::export('file', '/var/tmp/testing/wmflib_export_test.txt', {
        'ensure' => 'file',
        content  => 'foo',
        tag      => 'foo::bar',
    })
    wmflib::resource::import('file', undef, { tag => 'foo::bar' })
    wmflib::resource::export('file', '/var/tmp/testing/wmflib_export_merge_cotent_test.txt', {
        'ensure'  => 'file',
        'content' => "${facts['networking']['fqdn']}\n",
        'tag'     => 'foo::bar::merge',
    })
    wmflib::resource::import('file', undef, { tag => 'foo::bar::merge' }, true)
}
