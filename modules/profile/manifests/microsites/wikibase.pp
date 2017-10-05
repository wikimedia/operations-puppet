# https://wikiba.se (T99531)
class profile::microsites::wikibase {

    include ::base::firewall

    ferm::service { 'wikibase_http':
        proto => 'tcp',
        port  => '80',
    }

    class { '::apache': }
    class { '::apache::mod::headers': }

    apache::site { 'wikiba.se':
        content => template('profile/wikibase/apache-wikibase.erb'),
    }

    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikibase', {'ensure' => 'directory' })

    git::clone { 'wikibase/wikibase.se':
        ensure    => 'latest', # TODO: talk about latest vs. present
        directory => '/srv/org/wikibase',
        branch    => 'master', # are we using master to deploy?
    }

}

