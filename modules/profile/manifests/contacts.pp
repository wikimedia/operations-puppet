# @summary class for managing contact meta data
# @param role_contacts the default contact for this role, most often this is a Team
class profile::contacts (
    Array[String[3]] $role_contacts = lookup('profile::contacts::role_contacts'),
) {
    # We shouldn't use role unless we have to, in this profile it make sense
    # as such we should check that its defined and fail early if not
    unless defined('$::_role') {
        fail('This profile is only valid for nodes using the role() function')
    }

    $contacts_file = '/etc/wikimedia/contacts.yaml'
    ensure_resource('file', $contacts_file.dirname, {'ensure' => 'directory'})
    concat {$contacts_file:
        ensure => present,
    }
    $role_fixup = "role::${::_role.regsubst('/', '::')}"
    concat::fragment {'main contacts':
        target  => $contacts_file,
        order   => '01',
        content => {$role_fixup => $role_contacts}.to_yaml
    }
}
