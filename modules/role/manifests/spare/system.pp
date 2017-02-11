# This is a role for systems which are in the process of being reclaimed
# or decommissioned. IOW. the host once had a feature role assigned, but
# currently no has it. If such hosts are simply reset to "include ::standard"
# in site.pp, they are no longer matched by role-based grains for debdeploy.
#
# This role is entirely transient. Once a system has been reclaimed to spares
# or decomissioned, this role is removed from site.pp along with the host entry.
#
# filtertags: labs-project-puppet
class role::spare::system {
    include ::standard
    include ::base::firewall

    system::role { 'role::spare::system': description => 'Unused spare system' }
}
