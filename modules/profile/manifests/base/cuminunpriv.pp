# Make a server reachable by unprivileged Cumin (and eventually Spicerack)
#
# - Install the Kerberos client tools
# - Deploy the host keytab needed for kerberised SSH
# - Make the SSH port accessible to the unpriv. Cumin masters in Ferm

class profile::base::cuminunpriv(
    Array[Stdlib::IP::Address] $unpriv_cumin_masters = lookup('unpriv_cumin_masters', {default_value => []}),
) {
    include profile::kerberos::client
    include profile::kerberos::keytabs

    $cumin_hosts_ferm = join($unpriv_cumin_masters, ' ')
    ferm::service { 'ssh-from-unprivcumin-masters':
        proto  => 'tcp',
        port   => '22',
        srange => "(${cumin_hosts_ferm})",
    }
}
