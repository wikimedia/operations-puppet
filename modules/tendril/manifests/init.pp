# tendril: MariaDB Analytics
# git clones from operations/software/tendril to /srv/tendril

class tendril (
    $site_name,
    $docroot,
    $ldap_binddn,
    $ldap_authurl,
    $ldap_groups,
    $auth_name,
) {

    include passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    apache::site { $site_name:
        content => template("tendril/apache/${site_name}.erb");
    }

    file { '/srv/tendril':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
    }

    git::clone { 'operations/software/tendril':
        directory => '/srv/tendril',
        branch    => 'master',
        owner     => 'www-data',
        group     => 'www-data',
        require   => File['/srv/tendril'],
    }

}
