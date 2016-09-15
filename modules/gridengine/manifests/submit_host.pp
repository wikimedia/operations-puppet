# gridengine/submit_host.pp

class gridengine::submit_host {

    include ::gridengine

    require_package('jobutils')

    package { 'gridengine-client':
        ensure  => present,
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
