# SPDX-License-Identifier: Apache-2.0
# @summary wrapper profile for apt module
class profile::apt(
    Boolean $purge_sources           = lookup('profile::apt::purge_sources'),
    Boolean $purge_preferences       = lookup('profile::apt::purge_preferences'),
    Boolean $use_proxy               = lookup('profile::apt::use_proxy'),
    Boolean $manage_apt_source       = lookup('profile::apt::manage_apt_source'),
    Boolean $install_audit_installed = lookup('profile::apt::install_audit_installed'),
    String  $mirror                  = lookup('profile::apt::mirror'),
    Boolean $use_private_repo        = lookup('profile::apt::use_private_repo')
) {
    class { 'apt':
        use_proxy               => $use_proxy,
        purge_sources           => $purge_sources,
        purge_preferences       => $purge_preferences,
        manage_apt_source       => $manage_apt_source,
        mirror                  => $mirror,
        install_audit_installed => $install_audit_installed,
        use_private_repo        => $use_private_repo,
    }
    contain apt  # lint:ignore:wmf_styleguide
    # Ensure the correct apt configuration is in place so we install from
    # WMF sources list instead of debian default see T158562
    # We exclude gnupg as its used by apt::repository.  this is fine as long as we dont
    # start relying on a gnupg we build our self.
    Class['apt'] -> Package<| title != 'gnupg' |>
}
