# manifest to setup a gitblit instance

# Setup apache for the git viewer and replicated git repos
# Also needs gerrit::replicationdest installed
class gitblit($host,
    $user = 'gitblit',
    $git_repo_owner='gerritslave',
    $ssl_cert='',
    $ssl_cert_key=''
) {

    include webserver::apache,
        gitblit::monitor

    generic::systemuser { $user: name => $user }

    file { "/etc/apache2/sites-available/${$host}":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template("gitblit/${host}.erb"),
    }

    file { '/var/lib/git':
        ensure  => directory,
        mode    => '0644',
        owner   => $git_repo_owner,
        group   => $git_repo_owner,
        require => User[$git_repo_owner],
    }

    file { "/var/lib/${user}/data/gitblit.properties":
        mode    => '0444',
        owner   => $user,
        group   => $user,
        source  => 'puppet:///modules/gitblit/gitblit.properties',
        require => Generic::Systemuser[$user],
    }

    file { "/var/lib/${user}/data/header.md":
        mode    => '0444',
        owner   => $user,
        group   => $user,
        source  => 'puppet:///modules/gitblit/header.md',
        require => Generic::Systemuser[$user],
    }

    file { '/etc/init.d/gitblit':
        mode    => '0554',
        owner   => $user,
        group   => $user,
        source  => 'puppet:///modules/gitblit/gitblit-ubuntu',
        require => Generic::Systemuser[$user],
    }

    file { '/var/www/robots.txt':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "User-agent: *\nDisallow: /\n",
    }

    service { 'gitblit':
        ensure    => running,
        subscribe => File["/var/lib/${user}/data/gitblit.properties"],
        enable    => true,
        require   => Generic::Systemuser[$user],
    }

    apache_site { 'git':
        name => $host,
    }
    apache_module { 'headers':
        name => 'headers',
    }
    apache_module { 'rewrite':
        name => 'rewrite',
    }
    apache_module { 'proxy':
        name => 'proxy',
    }
    apache_module { 'proxy_http':
        name => 'proxy_http',
    }
    apache_module { 'ssl':
        name => 'ssl',
    }
}
