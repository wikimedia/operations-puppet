class contint::hhvm {

    class { '::hhvm':
        packages_ensure  => 'latest',

        cli_settings => {
            hhvm => { repo => {
                local    => { mode => 'rw', },
                eval    => { 'mode' => 'local' },
                journal => 'memory',
            } }
        },
        fcgi_settings => {
            # We will want to bypass the Repo since code keep changing?
        },
    }

    alternatives::select { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
    }

}
