# SPDX-License-Identifier: Apache-2.0
# == Class profile::statistics::explorer::wikidata_platform
#
# This class sets up team-specific resources on the stat hosts for the Wikidata Platform team.

class profile::statistics::explorer::wikidata_platform(

    String $swift_s3_access_key      = lookup('profile::statistics::explorer::wikidata_platform::swift_s3_access_key'),
    Hash[String, String] $swift_keys = lookup('profile::thanos::swift::accounts_keys'),
    String $swift_endpoint           = lookup('profile::statistics::explorer::wikidata_platform::swift_endpoint', {'default_value' => 'https://thanos-swift.discovery.wmnet'}),
) {

    require profile::statistics::explorer::s3cfg

    $swift_cfg_file = '/etc/s3cmd/cfg.d/wikidata_platform.cfg'
    $swift_s3_secret_key = $swift_keys['wdqs_savepoints']
    file { $swift_cfg_file:
        ensure  => file,
        owner   => 'root',
        group   => 'analytics-wikidata-users',
        mode    => '0440',
        content => template('profile/statistics/explorer/s3cfg/s3cfg.erb'),
    }

}