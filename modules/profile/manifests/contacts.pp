# SPDX-License-Identifier: Apache-2.0
# @summary class for managing contact meta data
# @param role_contacts the default contact for this role, most often this is a Team
class profile::contacts (
    String[1]           $cluster       = lookup('cluster'),
    Array[Wmflib::Team] $role_contacts = lookup('profile::contacts::role_contacts'),
) {
    # We shouldn't use role unless we have to, in this profile it make sense
    # as such we should check that its defined and fail early if not
    unless defined('$::_role') {
        fail('This profile is only valid for nodes using the role() function')
    }

    $contacts_file = '/etc/wikimedia/contacts.yaml'
    ensure_resource('file', $contacts_file.dirname, { 'ensure' => 'directory' })
    concat { $contacts_file:
        ensure => present,
    }
    $role_fixup = $::_role.regsubst('/', '::', 'G')
    $role_fixup_prefixed = "role::${role_fixup}"
    concat::fragment { 'main contacts':
        target  => $contacts_file,
        order   => '01',
        content => { $role_fixup_prefixed => $role_contacts }.to_yaml,
    }

    # TODO: update the below when we move to Strings for role owner
    # Currently role_contacts is an array, We plan to make this a String at some
    # point and disallow multiple owners for now we just pick the first owner
    # NOTE: we don't use bool2str as the false argument would is still evaluated
    # when true which fails
    $_role_contact = $role_contacts.empty ? {
        true    => 'Unknown',
        default => $role_contacts[0],
    }
    $role_owner_metric = @("METRIC"/L)
    # HELP role_owner The team owner of the server role
    # TYPE role_owner gauge
    role_owner{\
    team="${_role_contact.regsubst('\W', '-', 'G').downcase}",\
    role="${role_fixup}",\
    cluster="${cluster}"} 1.0
    | METRIC
    file { '/var/lib/prometheus/node.d/role_owner.prom':
        ensure  => file,
        content => $role_owner_metric,
    }
}
