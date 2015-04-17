# Class: citoid
#
# This class installs and configures citoid
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future citoid needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
# Parameters:
#   zotero_host. The DNS/IP address of the zotero host
#
#   zotero_port. The zotero host's TCP port
class citoid( $zotero_host,
              $zotero_port,
) {
    service::node { 'citoid':
        port   => 1970,
        config => template('citoid/config.yaml.erb'),
    }
}
