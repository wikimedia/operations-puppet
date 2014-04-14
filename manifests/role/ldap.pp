# role for a host with LDAP admins and tools
# not necessarily LDAP server
class role::ldap::operations {

    class { 'ldap::role::client::labs':
        ldapincludes => ['openldap', 'nss', 'utils'],
    }

    include admins::ldap
}
