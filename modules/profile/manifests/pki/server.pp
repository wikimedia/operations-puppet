# @summary configure a PKI sevrver
class profile::pki::server () {
    class {'cfssl': }
}
