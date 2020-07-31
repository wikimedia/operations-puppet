class helm(
    Stdlib::Unixpath $helm_home='/etc/helm',
    Hash[String[1], Stdlib::Httpurl] $repositories={'stable' => 'https://releases.wikimedia.org/charts/', 'chartmuseum' => 'https://helm-charts.wikimedia.org/stable/'},
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
        # Ensure we don't overwrite local
        if ($name != 'stable' and $name != 'local') {
            exec { 'helm-repo-add':
                command     => "/usr/bin/helm repo add ${name} ${url}",
                environment => "HELM_HOME=${helm_home}",
                creates     => "${helm_home}/repository/cache/${name}-index.yaml",
                user        => 'helm',
                require     => [User['helm'], File[$helm_home],]
            }
        }
    }

    cron { 'helm-repo-update':
        ensure      => 'present',
        command     => '/usr/bin/helm repo update >/dev/null 2>&1',
        environment => "HELM_HOME=${helm_home}",
        user        => 'helm',
        minute      => '*/1',
    }
}
