class statistics::user {
    include ::passwords::statistics::user

    $username = 'stats'
    $homedir  = "/var/lib/${username}"

    # From Buster onward, we want to have fixed uid/gids for daemons.
    # We manage service system users in puppet classes, but declare
    # commented placeholders for them in the admin module's data.yaml file
    # to ensure that people don't accidentally add uid/gid conflicts.
    $stats_uid = 918
    $stats_gid = 918

    systemd::sysuser { $username:
        id       => "${stats_uid}:${stats_gid}",
        shell    => '/bin/bash',
        home_dir => $homedir,
    }

    $git_settings = {
        'user' => {
            'name'  => 'Statistics User',
            'email' => 'data-engineering-alerts@lists.wikimedia.org',
        },
        # Enable automated git/gerrit authentication via http
        # by using .git-credential file store.
        'credential' => {
            'helper' => 'store',
        }
    }

    # Specific global git config for all the Analytics VLAN
    # to force every user to use the Production Webproxy.
    # This is useful to avoid HTTP/HTTPS calls ending up
    # being blocked by the VLAN's firewall rules, avoiding
    # all the users to set up their own settings.
    # Not needed in labs.
    if $::realm == 'production' {
        $git_http_proxy_settings = {
            # https://wikitech.wikimedia.org/wiki/HTTP_proxy
            'http' => {
                'proxy' => 'http://webproxy.eqiad.wmnet:8080'
            },
            'https' => {
                'proxy' => 'http://webproxy.eqiad.wmnet:8080'
            },
        }
    } else {
        $git_http_proxy_settings = {}
    }

    git::userconfig { $username:
        homedir  => $homedir,
        settings => merge($git_settings, $git_http_proxy_settings),
        require  => User[$username],
    }

    # Render the .git-credentials file with the stats user's http password.
    # This password is set from https://gerrit.wikimedia.org/r/#/settings/http-password.
    # To log into gerrit as the stats user, check the /srv/password/stats-user file
    # for LDAP login creds.
    file { "${homedir}/.git-credentials":
        mode    => '0600',
        owner   => $username,
        group   => $username,
        content => "https://${username}:${passwords::statistics::user::gerrit_http_password}@gerrit.wikimedia.org",
        require => User[$username],
    }
}
