# manifest to setup a gitblit instance

# Setup apache for the git viewer and replicated git repos
# Also needs gerrit::replicationdest installed
class gitblit(
    $host = '',
    $git_repo_owner='gerritslave',
    $ssl_cert='',
    $ssl_cert_key=''
) {

    include webserver::apache
    include gitblit::monitor

    generic::systemuser { 'gitblit': name => 'gitblit' }

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
        owner   => 'gitblit',
        group   => 'gitblit',
        source  => 'puppet:///modules/gitblit/gitblit.properties',
        require => Generic::Systemuser['gitblit'],
    }

    file { "/var/lib/${user}/data/header.md":
        mode    => '0444',
        owner   => 'gitblit',
        group   => 'gitblit',
        source  => 'puppet:///modules/gitblit/header.md',
        require => Generic::Systemuser['gitblit'],
    }

    file { '/etc/init.d/gitblit':
        mode    => '0554',
        owner   => 'gitblit',
        group   => 'gitblit',
        source  => 'puppet:///modules/gitblit/gitblit-ubuntu',
        require => Generic::Systemuser['gitblit'],
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
        require   => Generic::Systemuser['gitblit'],
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
