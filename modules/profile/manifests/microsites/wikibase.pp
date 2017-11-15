# https://wikiba.se (T99531)
class profile::microsites::wikibase(
  $server_name = hiera('profile::microsites::wikibase::server_name'),
  $server_admin = hiera('profile::microsites::wikibase::server_admin'),
) {

    include ::apache
    include ::apache::mod::headers

    ferm::service { 'wikibase_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }

    apache::site { 'wikiba.se':
        content => template('profile/wikibase/apache-wikibase.erb'),
    }

    ensure_resource('file', '/srv/se', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/se/wikiba', {'ensure' => 'directory' })

    git::clone { 'wikibase/wikiba.se-deploy':
        ensure    => 'latest',
        directory => '/srv/se/wikiba',
        branch    => 'master',
    }

}

