class contint::hhvm {

    class { '::hhvm':
        packages_ensure  => 'latest',

        common_settings => {
            hhvm => {
                log => { use_sylog => false },
            },
        },

        cli_settings => {
            hhvm => {
                repo => {
                    local   => { mode => 'rw', },
                    eval    => { mode => 'local' },
                    journal => 'memory',
                },
            },
        },

        # We will want to bypass the Repo since code keep changing?
        fcgi_settings => { },
    }

    alternatives::select { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
    }

}
