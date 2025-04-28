# @summary This profile is applied to all instances in the tools and tooslbeta projects.
# @param login_server If this is a bastion or not. Access to non-bastions is restricted to admins.
class profile::toolforge::infrastructure (
    Boolean $login_server = lookup('login_server',  {default_value => false}),
) {
    unless $login_server {
        if ($::wmcs_project in ['tools', 'toolsbeta']) {
            motd::script { 'infrastructure-banner':
                ensure => present,
                source => "puppet:///modules/profile/toolforge/40-${::wmcs_project}-infrastructure-banner.sh",
            }
        }

        # Infrastructure instances are limited to an (arbitrarily picked) local
        # service group and root.
        security::access::config { 'toolforge-admin-only':
            content  => "-:ALL EXCEPT (${::wmcs_project}.admin) root:ALL\n",
            priority => 90,
        }
    }

    # By default, Cloud VPS projects have a sudoers policy in
    # LDAP/Horizon that grants all project members the ability to sudo
    # as root. We can't use that as we only want admins to have
    # unrestricted sudo powers (and so have manually removed the
    # default policy via Horizon), and we don't want to manually
    # maintain a sudo policy with a yet another list of roots.
    # Therefore we provision that sudo policy via here, as we can
    # reference groups (like the Toolforge admin group) this way.
    sudo::group { 'toolforge-admin-root':
        group      => "${::wmcs_project}.admin",
        privileges => ['ALL = (ALL) NOPASSWD: ALL'],
    }
}
