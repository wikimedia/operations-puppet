# SPDX-License-Identifier: Apache-2.0
# == Class profile::statistics::explorer::search_platform
#
# This class sets up team-specific resources on the stat hosts for the Search Platform team.

class profile::statistics::explorer::search_platform(

    String $swift_s3_access_key      = lookup('profile::statistics::explorer::search_platform::swift_s3_access_key'),
    Hash[String, String] $swift_keys = lookup('profile::thanos::swift::accounts_keys'),
    String $swift_endpoint           = lookup('profile::statistics::explorer::search_platform::swift_endpoint', {'default_value' => 'https://thanos-swift.discovery.wmnet'}),
) {
    # profile::statistics::explorer::s3cfg is required, as it creates directories
    # that this profile uses.
    require profile::statistics::explorer::s3cfg

    $swift_cfg_file = '/etc/s3cmd/cfg.d/search_platform.cfg'
    $swift_s3_secret_key = $swift_keys['search_update_pipeline']
    file { $swift_cfg_file:
        ensure  => file,
        owner   => 'root',
        group   => 'analytics-search-users',
        mode    => '0440',
        content => template('profile/statistics/explorer/s3cfg/s3cfg.erb'),
    }

}
