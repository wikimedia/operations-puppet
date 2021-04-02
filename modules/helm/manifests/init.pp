class helm(
    Stdlib::Unixpath $helm_home='/etc/helm',
    Stdlib::Unixpath $helm_data='/usr/share/helm',
    Stdlib::Unixpath $helm_cache='/var/cache/helm',
    Hash[String[1], Stdlib::Httpurl] $repositories={'stable' => 'https://helm-charts.wikimedia.org/stable/', 'wmf-stable' => 'https://helm-charts.wikimedia.org/stable'},
) {
    package { [ 'helm', 'helm3', ]:
        ensure => installed,
    }

    # Note that this user is not going to be really used anywhere, it will just own the helm home files
    group { 'helm':
        ensure => present,
        name   => 'helm',
        system => true,
    }

    user { 'helm':
        shell      => '/bin/false',
        home       => '/nonexistent',
        managehome => false,
        gid        => 'helm',
        system     => true,
    }

    # Make sure things are group wikidev and nice permissions
    file { $helm_home:
        ensure  => directory,
        owner   => 'helm',
        group   => 'wikidev',
        mode    => '0775',
        recurse => true,
    }
    # HELM_DATA_HOME for helm 3
    file { $helm_data:
        ensure  => directory,
        owner   => 'helm',
        group   => 'wikidev',
        mode    => '0775',
        recurse => true,
    }
    # HELM_CACHE_HOME for helm 3
    file { $helm_cache:
        ensure  => directory,
        owner   => 'helm',
        group   => 'wikidev',
        mode    => '0775',
        recurse => true,
    }

    # helm init is needed for helm 2 only
    exec { 'helm-init':
        command     => "/usr/bin/helm init --client-only --stable-repo-url ${repositories['stable']}",
        environment => "HELM_HOME=${helm_home}",
        creates     => "${helm_home}/repository",
        user        => 'helm',
        require     => [User['helm'], File[$helm_home],]
    }

    $repositories.each |$name, $url| {
        # Ensure we don't overwrite local.
        # "helm repo add" will change the URL if a repository with ${name} already exists.
        if ($name != 'local') {
            exec { "helm-repo-add-${name}":
                command     => "/usr/bin/helm repo add ${name} ${url}",
                environment => "HELM_HOME=${helm_home}",
                unless      => "/usr/bin/helm repo list | /bin/grep -E -q '^${name}\\s+${url}'",
                user        => 'helm',
                require     => [User['helm'], File[$helm_home],]
            }
            # With helm 3, there is no such thing as local repository anymore
            exec { "helm3-repo-add-${name}":
                command     => "/usr/bin/helm3 repo add ${name} ${url}",
                environment => [
                    "HELM_CONFIG_HOME=${helm_home}",
                    "HELM_DATA_HOME=${helm_data}",
                    "HELM_CACHE_HOME=${helm_cache}",
                ],
                unless      => "/usr/bin/helm3 repo list | /bin/grep -E -q '^${name}\\s+${url}'",
                user        => 'helm',
                require     => [User['helm'], File[$helm_home], File[$helm_cache]]
            }
        }
    }

    # This runs both, helm 2 and helm 3 repo updates
    ['helm', 'helm3'].each |String $helm_version| {
        systemd::timer::job { "${helm_version}-repo-update":
            ensure          => present,
            description     => 'Update helm repositories indices',
            command         => "/usr/bin/${helm_version} repo update",
            environment     => {
                'HELM_HOME'        => $helm_home,
                'HELM_CONFIG_HOME' => $helm_home,
                'HELM_DATA_HOME'   => $helm_data,
                'HELM_CACHE_HOME'  => $helm_cache,
            },
            user            => 'helm',
            logging_enabled => false,
            interval        => {
                # We don't care about when this runs, as long as it runs every minute.
                'start'    => 'OnUnitInactiveSec',
                'interval' => '60s',
            },
        }
    }
}
