# https://security.wikimedia.org (T257834)
class profile::microsites::security(
  $server_name = lookup('profile::microsites::security::server_name'),
  $server_admin = lookup('profile::microsites::security::server_admin'),
) {

    httpd::site { 'security.wikimedia.org':
        content => template('profile/security/security.wikimedia.org.erb'),
    }

    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia/security', {'ensure' => 'directory' })

    git::clone { 'wikimedia/security/landing-page':
        ensure    => 'latest',
        source    => 'gerrit',
        directory => '/srv/org/wikimedia/security',
        branch    => 'master',
    }

}

