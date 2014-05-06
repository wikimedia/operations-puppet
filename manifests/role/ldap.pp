# role for a host with LDAP admins and tools
# not necessarily LDAP server
class role::ldap::operations {

    include ldap::role::client::labs
    include admins::ldap
}
