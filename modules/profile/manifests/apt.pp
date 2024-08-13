# SPDX-License-Identifier: Apache-2.0
# @summary wrapper profile for apt module
class profile::apt (
    Boolean       $purge_sources           = lookup('profile::apt::purge_sources'),
    Boolean       $purge_preferences       = lookup('profile::apt::purge_preferences'),
    Boolean       $use_proxy               = lookup('profile::apt::use_proxy'),
    Boolean       $install_audit_installed = lookup('profile::apt::install_audit_installed'),
    String        $mirror                  = lookup('profile::apt::mirror'),
    Boolean       $use_private_repo        = lookup('profile::apt::use_private_repo'),
    Array[String] $private_components      = lookup('profile::apt::private_components', default_value => [])
) {
    class { 'apt':
        use_proxy               => $use_proxy,
        purge_sources           => $purge_sources,
        purge_preferences       => $purge_preferences,
        mirror                  => $mirror,
        install_audit_installed => $install_audit_installed,
        use_private_repo        => $use_private_repo,
        private_components      => $private_components,
    }
    contain apt  # lint:ignore:wmf_styleguide
}
