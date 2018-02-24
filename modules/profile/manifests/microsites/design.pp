# https://design.wikimedia.org (T185282)
class profile::microsites::design(
  $server_name = hiera('profile::microsites::design::server_name'),
  $server_admin = hiera('profile::microsites::design::server_admin'),
) {

    httpd::site { 'design.wikimedia.org':
        content => template('profile/design/apache-design.wikimedia.org.erb'),
    }

    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia/design', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia/design-style-guide', {'ensure' => 'directory' })

    # git::clone { 'FIXME':
    #   ensure    => 'latest',
    #   source    => 'gerrit',
    #   directory => '/srv/org/wikimedia/design',
    #   branch    => 'master',
    # }

    # git::clone { 'FIXME':
    #   ensure    => 'latest',
    #   source    => 'gerrit',
    #   directory => '/srv/org/wikimedia/design-style-guide',
    #   branch    => 'master',
    # }
}

