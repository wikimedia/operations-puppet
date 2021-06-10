# @summary class for managing contact meta data
# @param role_contacts the default contact for this role, most often this is a Team
class profile::contacts (
    Array[String[3]] $role_contacts = lookup('profile::contacts::role_contacts'),
) {
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
