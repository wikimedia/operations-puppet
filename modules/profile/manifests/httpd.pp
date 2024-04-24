# SPDX-License-Identifier: Apache-2.0
# @summary configure httpd daemon
# @param modules list of modules to install
# @param legacy_compat Use Apache 2.2 compatible syntax.
# @param period log rotation period
# @param rotate amount of log rotated files to keep
# @param enable_forensic_log turn on forensic logs
# @param extra_pkgs Extra packages to install which are not pulled in by the "apache2" base package in Debian.
# @param purge_manual_config remove any unmanaged files in the apache directory
# @param remove_default_ports if true remove the default port list
# @param http_only if true only enable to http port
# @param wait_network_online Set to true to have the service to run after
#   network-online.target. Can be used when Apache is configured to Listen to
#   an explicit IP address.
class profile::httpd (
    Array[String]           $modules              = lookup('profile::httpd::modules'),
    Wmflib::Ensure          $legacy_compat        = lookup('profile::httpd::legacy_compat'),
    Enum['daily', 'weekly'] $period               = lookup('profile::httpd::period'),
    Integer                 $rotate               = lookup('profile::httpd::rotate'),
    Boolean                 $enable_forensic_log  = lookup('profile::httpd::enable_forensic_log'),
    Array[String]           $extra_pkgs           = lookup('profile::httpd::extra_pkgs'),
    Boolean                 $purge_manual_config  = lookup('profile::httpd::purge_manual_config'),
    Boolean                 $remove_default_ports = lookup('profile::httpd::remove_default_ports'),
    Boolean                 $http_only            = lookup('profile::httpd::http_only'),
    Boolean                 $wait_network_online  = lookup('profile::httpd::wait_network_online'),
) {
    class { 'httpd':
        * => wmflib::resource::dump_params(),
    }

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }
}
