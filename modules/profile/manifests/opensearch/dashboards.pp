# SPDX-License-Identifier: Apache-2.0
# == Class: profile::opensearch::dashboards
class profile::opensearch::dashboards (
    Opensearch::SemVer          $version                 = lookup('profile::opensearch::dashboards::version',                 { 'default_value' => '2.7.0' }),
    Boolean                     $enable_backups          = lookup('profile::opensearch::dashboards::enable_backups',          { 'default_value' => false }),
    Optional[Boolean]           $tile_map_enabled        = lookup('profile::opensearch::dashboards::tile_map_enabled',        { 'default_value' => undef }),
    Optional[Boolean]           $region_map_enabled      = lookup('profile::opensearch::dashboards::region_map_enabled',      { 'default_value' => undef }),
    Optional[String]            $index                   = lookup('profile::opensearch::dashboards::index',                   { 'default_value' => undef }),
    Optional[Boolean]           $enable_warnings         = lookup('profile::opensearch::dashboards::enable_warnings',         { 'default_value' => undef }),
    Optional[String]            $pki_intermediate_name   = lookup('profile::opensearch::pki_intermediate_name',               { 'default_value' => undef }),
    Optional[String]            $opensearch_api_username = lookup('profile::opensearch::dashboards::opensearch_api_username', { 'default_value' => undef }),
    Optional[Sensitive[String]] $opensearch_api_password = lookup('profile::opensearch::dashboards::opensearch_api_password', { 'default_value' => undef }),
    Boolean                     $multitenancy_enabled    = lookup('profile::opensearch::dashboards::multitenancy_enabled',    { 'default_value' => false }),
    Hash                        $common_settings         = lookup('profile::opensearch::common_settings'),
    Opensearch::InstanceParams  $dc_settings             = lookup('profile::opensearch::dc_settings'),
) {

    $disable_security_plugin = pick($common_settings['disable_security_plugin'], true)

    class { 'opensearch_dashboards':
        version                 => $version,
        enable_backups          => $enable_backups,
        tile_map_enabled        => $tile_map_enabled,
        region_map_enabled      => $region_map_enabled,
        index                   => $index,
        enable_warnings         => $enable_warnings,
        disable_security_plugin => $disable_security_plugin,
        cluster_name            => pick($dc_settings['cluster_name'], 'default'),
        pki_intermediate_name   => $pki_intermediate_name,
        multitenancy_enabled    => $multitenancy_enabled,
        opensearch_api_username => $opensearch_api_username,
        opensearch_api_password => $opensearch_api_password,
    }

    # the securityDashboards plugin must be installed when the security plugin configuration is present
    # otherwise, opensearch-dashboards will refuse to start
    package { 'securityDashboards':
        ensure   => stdlib::ensure(!$disable_security_plugin),
        source   => "http://apt.wikimedia.org/opensearch/securityDashboards-${version}.zip",
        provider => 'opensearch_dashboards_plugin',
    }

    package { [
            'indexManagementDashboards', # can cause accidental complete data loss - needs working security settings
            'notificationsDashboards',   # servers are firewalled off from reaching targets
            'alertingDashboards',        # requires notification capabilities - see ^^
            'observabilityDashboards',   # needs further investigation to limit write access via ui
        ]:
            ensure   => 'absent',
            provider => 'opensearch_dashboards_plugin',
    }

    if ($enable_backups) {
        include profile::backup::host

        backup::set { 'opensearch-dashboards':
            jobdefaults => 'Daily-productionEqiad', # full backups every day
        }
    }
}
