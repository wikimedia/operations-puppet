# Make a server reachable by unprivileged Cumin (and eventually Spicerack)
#
# - Install the Kerberos client tools
# - Deploy the host keytab needed for kerberised SSH

class profile::base::cuminunpriv(
) {
    include profile::kerberos::client
    include profile::kerberos::keytabs
}
