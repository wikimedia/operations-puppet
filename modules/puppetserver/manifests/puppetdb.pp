# SPDX-License-Identifier: Apache-2.0
# @summary configure a puppetserver to work with puppetdb automaticaly includes profile::puppetserver
class puppetserver::puppetdb {
    # We call this from profile::puppetserver
    assert_private()
    $urls = $puppetserver::puppetdb_urls
    $enable = !$urls.empty

    ensure_packages('puppet-terminus-puppetdb', { 'ensure' => stdlib::ensure($enable, 'package') })

    $puppetdb_config = @("CONFIG")
    [main]
    server_urls = ${urls.join(',')}
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
