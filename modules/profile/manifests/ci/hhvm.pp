class profile::ci::hhvm {

    # Dev dependencies To build PHP extensions
    exec { '/usr/bin/apt-get -y build-dep hhvm':
        onlyif => '/usr/bin/apt-get -s build-dep hhvm | /bin/grep -Pq "will be (installed|upgraded)"',
    }
    package { ['hhvm-dev']:
        ensure => present,
    }

    class { '::hhvm':
        # No need for a hhvm service on CI slaves T126594
        # lint:ignore:ensure_first_param
        service_params => {
            ensure => 'stopped',
            enable => false,
        },
        # lint:endignore

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
}
