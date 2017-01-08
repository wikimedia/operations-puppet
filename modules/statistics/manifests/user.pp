class statistics::user {
    include passwords::statistics::user

    $username = 'stats'
    $homedir  = "/var/lib/${username}"

    group { $username:
        ensure => present,
        name   => $username,
        system => true,
    }

    user { $username:
        home       => $homedir,
        groups     => ['wikidev'],
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    # lint:ignore:arrow_alignment
    git::userconfig { 'stats':
        homedir  => $homedir,
        settings => {
            'user' => {
                'name'  => 'Statistics User',
                # TODO: use a better email than this :(
                'email' => 'analytics-alerts@wikimedia.org',
            },
            # Enable automated git/gerrit authentication via http
            # by using .git-credential file store.
            'credential' => {
                'helper' => 'store',
            },
        },
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
