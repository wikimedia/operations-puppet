# gridengine/submit_host.pp

class gridengine::submit_host {

    include ::gridengine

    package { [ 'jobutils' ]:
        ensure => latest,
    }

    package { 'gridengine-client':
        ensure  => latest,
        require => Package['gridengine-common'],
    }

    file { '/var/lib/gridengine/default/common/accounting':
        ensure => link,
        target => '/data/project/.system/accounting',
    }

    gridengine::resource { "submit-${::fqdn}":
        rname  => $::fqdn,
        dir    => 'submithosts',
        config => 'gridengine/nothing.erb', # the content here doesn't actually matter
    }

}
