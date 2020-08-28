# https://sitemaps.wikimedia.org/
class profile::microsites::sitemaps(
  Stdlib::Fqdn $server_name = lookup('profile::microsites::sitemaps::server_name'),
  String $server_admin = lookup('profile::microsites::sitemaps::server_admin'),
) {

    httpd::site { $server_name:
        content => template('profile/sitemaps/apache-sitemaps.wikimedia.org.erb'),
    }

    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia', {'ensure' => 'directory' })

    # ensure sitemaps-admins own files in the document root
    file { '/srv/org/wikimedia/sitemaps':
        ensure  => 'directory',
        group   => 'sitemaps-admins',
        mode    => '2774',
        recurse => true,
    }
}

