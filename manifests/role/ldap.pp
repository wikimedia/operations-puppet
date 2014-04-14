# role for a host with LDAP admins and tools
# not necessarily LDAP server
class role::ldap::operations {

    $gid = '550'
    $ssh_tcp_forwarding = 'no'
    $ssh_x11_forwarding = 'no'

    class { 'ldap::role::client::labs':
        ldapincludes => ['openldap', 'nss', 'utils'],
    }

    include admins::ldap
}
