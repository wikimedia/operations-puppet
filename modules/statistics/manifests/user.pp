class statistics::user {
    include ::passwords::statistics::user

    $username = 'stats'
    $homedir  = "/var/lib/${username}"

    group { $username:
        ensure => present,
        name   => $username,
        system => true,
    }

    user { $username:
        home       => $homedir,
        groups     => [],
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    $git_settings = {
        'user' => {
            'name'  => 'Statistics User',
            # TODO: use a better email than this :(
            'email' => 'analytics-alerts@wikimedia.org',
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
    # Not needed in labs. VLAN's firewall rules ()
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

    # lint:ignore:arrow_alignment
    git::userconfig { 'stats':
        homedir  => $homedir,
        settings => merge($git_settings, $git_http_proxy_settings),
        require  => User[$username],
    }
    # lint:endignore

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
