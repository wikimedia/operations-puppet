# manifest to setup a gitblit instance

# Setup apache for the git viewer and replicated git repos
# Also needs gerrit::replicationdest installed
class gitblit(
    $host           = '',
    $git_repo_owner = 'gerritslave',
    $ssl_cert       = '',
    $ssl_cert_key   = '',
) {

    include webserver::apache
    include gitblit::monitor

    group { 'gitblit':
        ensure => present,
    }

    user { 'gitblit':
        ensure     => present,
        gid        => 'gitblit',
        shell      => '/bin/false',
        home       => '/var/lib/gitblit',
        system     => true,
        managehome => false,
    }

    file { "/etc/apache2/sites-available/${host}":
        ensure  => present,
        content => template("gitblit/${host}.erb"),
    }

    file { '/var/lib/git':
        ensure  => directory,
        mode    => '0644',
        owner   => $git_repo_owner,
        group   => $git_repo_owner,
    }

    file { '/var/lib/gitblit/data/gitblit.properties':
        owner   => 'gitblit',
        group   => 'gitblit',
        mode    => '0444',
        source  => 'puppet:///modules/gitblit/gitblit.properties',
    }

    file { '/var/lib/gitblit/data/header.md':
        owner   => 'gitblit',
        group   => 'gitblit',
        mode    => '0444',
        source  => 'puppet:///modules/gitblit/header.md',
    }

    file { '/etc/init.d/gitblit':
        mode    => '0554',
        owner   => 'gitblit',
        group   => 'gitblit',
        source  => 'puppet:///modules/gitblit/gitblit-ubuntu',
    }

    file { '/var/www/robots.txt':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "User-agent: *\nDisallow: /\n",
    }

    service { 'gitblit':
        ensure    => running,
        subscribe => File['/var/lib/gitblit/data/gitblit.properties'],
        enable    => true,
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
