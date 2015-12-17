class contint::hhvm {

    class { '::hhvm':
        # Never use a local repo. The central repo path is set to '' to have
        # hhvm fall back to the env variable HHVM_REPO_CENTRAL_PATH. It is
        # defined in the global Jenkins configuration and vary per build thanks
        # to $WORKSPACE.
        # lint:ignore:arrow_alignment
        cli_settings => {
            hhvm => {
                repo  => {
                    central => { path => '' },
                    eval    => { mode => 'central' },
                    local   => { mode => '--' },
                    journal => 'memory',
                },
                log   => { use_syslog => false },
                debug => { core_dump_report => false },
            },
        },

        # We will want to bypass the Repo since code keep changing?
        fcgi_settings => {
            hhvm => {
                log   => { use_syslog => false },
                debug => { core_dump_report => false },
            },
        },
        # lint:endignore
    }

    alternatives::select { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
    }

}
