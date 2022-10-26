# This prevents normal users who are not a member of tools.admin
# from authenticating via SSH.

class profile::toolforge::infrastructure (
    Boolean $login_server        = lookup('login_server',  {default_value => false}),
){
    unless $login_server {
        if ($::wmcs_project in ['tools', 'toolsbeta']) {
            motd::script { 'infrastructure-banner':
                ensure => present,
                source => "puppet:///modules/profile/toolforge/40-${::wmcs_project}-infrastructure-banner.sh",
            }
        }

        # Infrastructure instances are limited to an (arbitrarily picked) local
        # service group and root.
        security::access::config { 'labs-admin-only':
            content => "-:ALL EXCEPT (${::wmcs_project}.admin) root:ALL\n",
        }
    }
}
