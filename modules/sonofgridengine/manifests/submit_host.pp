# SPDX-License-Identifier: Apache-2.0
# sonofgridengine/submit_host.pp

class sonofgridengine::submit_host {

    include ::sonofgridengine

    package { [ 'jobutils' ]:
        ensure => latest,
    }

    package { 'gridengine-client':
        ensure  => present,
        require => Package['gridengine-common'],
    }

    sonofgridengine::resource { "submit-${facts['hostname']}.${::wmcs_project}.eqiad1.wikimedia.cloud":
        rname  => "${facts['hostname']}.${::wmcs_project}.eqiad1.wikimedia.cloud",
        dir    => 'submithosts',
        config => 'sonofgridengine/nothing.erb', # the content here doesn't actually matter
    }
}
