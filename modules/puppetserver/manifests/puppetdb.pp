# SPDX-License-Identifier: Apache-2.0
# @summary configure a puppetserver to work with puppetdb automaticaly includes profile::puppetserver
class puppetserver::puppetdb {
    # We call this from profile::puppetserver
    assert_private()
    $urls = $puppetserver::puppetdb_urls
    $submit_only_urls = $puppetserver::puppetdb_submit_only_urls
    $enable = !$urls.empty
    # Always enable command_broadcast if we have more then 1 host
    $command_broadcast = ($urls + $submit_only_urls).length > 1

    ensure_packages('puppet-terminus-puppetdb', { 'ensure' => stdlib::ensure($enable, 'package') })

    $submit_only_config = $submit_only_urls.empty.bool2str(
        '', "submit_only_server_urls = ${submit_only_urls.join(' ')}"
    )

    $puppetdb_config = @("CONFIG")
    [main]
    server_urls = ${urls.join(',')}
    ${submit_only_config}
    command_broadcast = ${command_broadcast}
    | CONFIG

    $routes = {
        'master' => {
            'facts' => {
                'terminus' => 'puppetdb',
                'cache'    => 'yaml',
            },
        },
    }
    file {
        default:
            ensure => stdlib::ensure($enable, file),
            notify => Service['puppetserver'];
        "${puppetserver::config_dir}/puppetdb.conf":
            content => $puppetdb_config;
        "${puppetserver::config_dir}/routes.yaml":
            content => $routes.to_yaml;
    }
}
