# https://wikiworkshop.org (T242374)
class profile::microsites::wikiworkshop {

    httpd::site { 'wikiworkshop.org':
        content => template('profile/wikiworkshop/apache-wikiworkshop.org.erb'),
    }

    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia/wikiworkshop', {'ensure' => 'directory' })

    git::clone { 'research/wikiworkshop':
        ensure    => 'latest',
        source    => 'gerrit',
        directory => '/srv/org/wikimedia/wikiworkshop',
        branch    => 'master',
    }
}
