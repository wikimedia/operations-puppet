class helm(
    Stdlib::Unixpath $helm_home='/etc/helm',
    Hash[String[1], Stdlib::Httpurl] $repositories={'stable' => 'https://helm-charts.wikimedia.org/stable/'},
) {
    package { [
        'helm',
        'kubernetes-client',
        ]:
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
            exec { 'helm-repo-add':
                command     => "/usr/bin/helm repo add ${name} ${url}",
                environment => "HELM_HOME=${helm_home}",
                unless      => "/usr/bin/helm repo list | /bin/grep -E -q '^${name}\\s+${url}'",
                user        => 'helm',
                require     => [User['helm'], File[$helm_home],]
            }
        }
    }

    # Replaced by systemd timer below
    cron { 'helm-repo-update':
        ensure      => 'absent',
        command     => '/usr/bin/helm repo update >/dev/null 2>&1',
        environment => "HELM_HOME=${helm_home}",
        user        => 'helm',
        minute      => '*/1',
    }

    systemd::timer::job { 'helm-repo-update':
        ensure             => present,
        description        => 'Update helm repositories indices',
        command            => '/usr/bin/helm repo update',
        environment        => {'HELM_HOME' => $helm_home},
        user               => 'helm',
        logging_enabled    => false,
        monitoring_enabled => true,
        interval           => {
            # We don't care about when this runs, as long as it runs every minute.
            'start'    => 'OnUnitInactiveSec',
            'interval' => '60s',
        },
    }
}
