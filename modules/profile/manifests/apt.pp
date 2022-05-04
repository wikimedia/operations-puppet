# @summary wrapper profile for apt module
class profile::apt(
    Boolean $purge_sources           = lookup('profile::apt::purge_sources'),
    Boolean $purge_preferences       = lookup('profile::apt::purge_preferences'),
    Boolean $use_proxy               = lookup('profile::apt::use_proxy'),
    Boolean $manage_apt_source       = lookup('profile::apt::manage_apt_source'),
    Boolean $install_audit_installed = lookup('profile::apt::install_audit_installed'),
    String  $mirror                  = lookup('profile::apt::mirror'),
) {
    class { 'apt':
        use_proxy               => $use_proxy,
        purge_sources           => $purge_sources,
        purge_preferences       => $purge_preferences,
        manage_apt_source       => $manage_apt_source,
        mirror                  => $mirror,
        install_audit_installed => $install_audit_installed,
    }
    contain apt  # lint:ignore:wmf_styleguide
}
