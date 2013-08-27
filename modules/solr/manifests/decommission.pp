# == Class: solr::decommission
#
# Uninstalls Solr & related configuration data from a node.
#
class solr::decommission {
    package { 'solr-jetty':
        ensure => absent,
    }

    file { [
        '/etc/default/jetty',
        '/etc/solr',
        '/usr/share/jetty/webapps/solr',
        '/usr/share/solr',
    ]:
        ensure  => absent,
        recurse => true,
        purge   => true,
        force   => true,
        require => Service['jetty'],
    }

    service { 'jetty':
        ensure => stopped,
        enable => false,
    }
}
