# Setup apache to render static files
#
# === Parameters
#
# [*sitename*]
#  Name of the site, e.g. paws-internal.wikimedia.org
#
# [*static_path*]
#  The base path from which all static files are to be rendered
#
# [*url_prefix*]
#  Url prefix that is aliased to the static path
#
# [*ldap_groups*]
#  List of ldap groups that can access the site


class jupyterhub::static (
    $sitename,
    $static_path,
    $url_prefix,
    $ldap_groups = [],
) {

    include ::passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    file { $static_path:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    apache::site { $sitename:
        content => template('jupyterhub/apache/nbstatic.conf.erb'),
    }

}
