# lint:ignore:wmf_styleguide
# This is a role for systems which are in the process of being reclaimed
# or decommissioned. IOW. the host once had a feature role assigned, but
# currently no has it. If such hosts are simply reset to "include
# ::profile::standard" in site.pp, they are no longer matched by role-based
# server addressing in debdeploy.
#
# This role is entirely transient. Once a system has been reclaimed to spares
# or decomissioned, this role is removed from site.pp along with the host entry.
#
# filtertags: labs-project-puppet
class role::spare::system {
    include ::profile::standard
    include ::profile::base::firewall
    # This is a style validation however it makes senses in this instance as
    # a) people will likely forget to add this parameter when moving hosts to
    # the spare role
    # b) We will hopefully move this to profile::standard shortly
    interface::add_ip6_mapped { 'main': }

    system::role { 'spare::system': description => 'Unused spare system' }
}
# lint:endignore
