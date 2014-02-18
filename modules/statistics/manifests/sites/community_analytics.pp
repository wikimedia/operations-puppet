# community-analytics.wikimedia.org
class statistics::sites::community_analytics {
    $site_name = 'community-analytics.wikimedia.org'
    $docroot   = '/srv/org.wikimedia.community-analytics/community-analytics/web_interface'

    # org.wikimedia.community-analytics is kinda big,
    # it really lives on /a.
    # Symlink /srv/a/org.wikimedia.community-analytics to it.
    file { '/srv/org.wikimedia.community-analytics':
        ensure => 'link'
        target => '/a/srv/org.wikimedia.community-analytics',
    }

    webserver::apache::site { $site_name:
        require      => [Class['webserver::apache'],
                        Class['statistics::packages']],
        docroot      => $docroot,
        server_admin => 'noc@wikimedia.org',
        custom       => [
            "SetEnv MPLCONFIGDIR
/srv/org.wikimedia.community-analytics/mplconfigdir",

    "<Location \"/\">
        SetHandler python-program
        PythonHandler django.core.handlers.modpython
        SetEnv DJANGO_SETTINGS_MODULE web_interface.settings
        PythonOption django.root /community-analytics/web_interface
        PythonDebug On
        PythonPath
\"['/srv/org.wikimedia.community-analytics/community-analytics'] + sys.path\"
    </Location>",

    "<Location \"/media\">
        SetHandler None
    </Location>",

    "<Location \"/static\">
        SetHandler None
    </Location>",

    "<LocationMatch \"\\.(jpg|gif|png)$\">
        SetHandler None
    </LocationMatch>",
    ],
    }
}
