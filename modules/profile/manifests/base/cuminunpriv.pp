# SPDX-License-Identifier: Apache-2.0
# Make a server reachable by unprivileged Cumin (and eventually Spicerack)
#
# - Install the Kerberos client tools
# - Deploy the host keytab needed for kerberised SSH
# - Make the SSH port accessible to the unpriv. Cumin masters in Ferm

class profile::base::cuminunpriv(
    Array[Stdlib::IP::Address] $unpriv_cumin_masters = lookup('unpriv_cumin_masters', {default_value => []}),
) {
    include profile::kerberos::client

    if !defined(File['/etc/security/keytabs/host']) {
        file { '/etc/security/keytabs/host':
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root',
            mode    => '0550',
            require => File['/etc/security/keytabs']
        }
    }

    file { '/etc/security/keytabs/host/host.keytab':
        ensure    => 'present',
        owner     => 'root',
        group     => 'root',
        mode      => '0440',
        content   => wmflib::secret("kerberos/keytabs/${::fqdn}/host/host.keytab", true),
        show_diff => false,
        require   => File['/etc/security/keytabs/host']
    }

    firewall::service { 'ssh-from-unprivcumin-masters':
        proto  => 'tcp',
        port   => 22,
        srange => $unpriv_cumin_masters,
    }

    # OpenSSH searches for the host keytab in /etc/keytab. We deploy all keytabs
    # centrally via Puppet in /etc/security/keytabs, so add a symlink as a fallback
    file { '/etc/krb5.keytab':
        ensure => link,
        target => '/etc/security/keytabs/host/host.keytab',
    }
}
