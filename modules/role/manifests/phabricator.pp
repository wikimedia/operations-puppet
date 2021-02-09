# phabricator instance
#
# filtertags: labs-project-deployment-prep labs-project-devtools
class role::phabricator {

    system::role { 'phabricator':
        description => 'Phabricator (Main) Server'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::backup::host
    include ::profile::phabricator::main
    include ::profile::phabricator::httpd
    include ::profile::phabricator::monitoring
    include ::profile::phabricator::performance
    include ::profile::prometheus::apache_exporter
    include ::profile::tlsproxy::envoy # TLS termination
    include ::rsync::server # copy repo data between servers

    if $::realm == 'production' {
        include ::lvs::realserver
    }

    # in cloud, use a local db server
    if $::realm == 'labs' {
        include ::profile::mariadb::generic_server
    }
}
