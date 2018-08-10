# https://sitemaps.wikimedia.org/
class profile::microsites::sitemaps(
  $server_name = hiera('profile::microsites::sitemaps::server_name'),
  $server_admin = hiera('profile::microsites::sitemaps::server_admin'),
) {

    httpd::site { $server_name:
        content => template('profile/sitemaps/apache-sitemaps.wikimedia.org.erb'),
    }

    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia/sitemaps', {'ensure' => 'directory' })
}
