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

    sonofgridengine::resource { "submit-${facts['hostname']}.${::labsproject}.eqiad1.wikimedia.cloud":
        rname  => "${facts['hostname']}.${::labsproject}.eqiad1.wikimedia.cloud",
        dir    => 'submithosts',
        config => 'sonofgridengine/nothing.erb', # the content here doesn't actually matter
    }
}
