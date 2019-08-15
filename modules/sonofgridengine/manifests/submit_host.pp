# sonofgridengine/submit_host.pp

class sonofgridengine::submit_host {

    include ::sonofgridengine

    package { [ 'jobutils' ]:
        ensure => present,
    }

    package { 'gridengine-client':
        ensure  => present,
        require => Package['gridengine-common'],
    }

    sonofgridengine::resource { "submit-${::fqdn}":
        rname  => $::fqdn,
        dir    => 'submithosts',
        config => 'sonofgridengine/nothing.erb', # the content here doesn't actually matter
    }
}
