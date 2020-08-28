# https://research.wikimedia.org (T183916)
class profile::microsites::research(
  Stdlib::Fqdn $server_name = lookup('profile::microsites::research::server_name'),
  String $server_admin = lookup('profile::microsites::research::server_admin'),
) {

    httpd::site { 'research.wikimedia.org':
        content => template('profile/research/apache-research.wikimedia.org.erb'),
    }

    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia/research', {'ensure' => 'directory' })

    git::clone { 'research/landing-page':
        ensure    => 'latest',
        source    => 'gerrit',
        directory => '/srv/org/wikimedia/research',
        branch    => 'master',
    }

}

