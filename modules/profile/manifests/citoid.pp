# == Class: profile::citoid
#
# This class installs and configures citoid
#
# === Parameters
#
# [*zotero_host*]
#   The DNS/IP address of the zotero host
#
# [*zotero_port*]
#   The zotero host's TCP port
#
# [*wskey*]
#   The WorldCat Search API key to use. Default: ''
#
class profile::citoid(
    $zotero_host=hiera('profile::citoid::zotero_host'),
    $zotero_port=hiera('profile::citoid::zotero_port'),
    $wskey = hiera('citoid::wskey', ''), # TODO: fix namespace
) {
    service::node { 'citoid':
        port              => 1970,
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            zotero_host => $zotero_host,
            zotero_port => $zotero_port,
            wskey       => $wskey,
        },
    }
}
