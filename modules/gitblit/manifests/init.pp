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

    file { "/etc/apache2/sites-enabled/${host}":
        ensure => link,
        target => "/etc/apache2/sites-available/${host}"
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

    file { '/etc/init/gitblit.conf':
        source  => 'puppet:///modules/gitblit/gitblit.conf',
    }

    file { '/var/www/robots.txt':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "User-agent: *\nDisallow: /\n",
    }

    service { 'gitblit':
        ensure    => running,
        provider  => 'upstart',
        subscribe => File['/var/lib/gitblit/data/gitblit.properties'],
        require   => File['/etc/init/gitblit.conf'],
    }


    include ::apache::mod::headers

    include ::apache::mod::rewrite

    include ::apache::mod::proxy

    include ::apache::mod::proxy_http

    include ::apache::mod::ssl
}
