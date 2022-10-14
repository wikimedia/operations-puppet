# SPDX-License-Identifier: Apache-2.0
class profile::kerberos::client (
    Stdlib::Fqdn $krb_realm_name = lookup('kerberos_realm_name'),
    Array[Stdlib::Fqdn] $krb_kdc_servers = lookup('kerberos_kdc_servers'),
    Stdlib::Fqdn $krb_kadmin_primary = lookup('kerberos_kadmin_server_primary'),
    Boolean $dns_canonicalize_hostname = lookup('profile::kerberos::client::dns_canonicalize_hostname', { 'default_value' => true}),
    Optional[Boolean] $use_new_ccache = lookup('profile::kerberos::client::use_new_ccache', { 'default_value' => false}),
    Boolean $skip_wrapper = lookup('profile::kerberos::client::skip_wrapper', { 'default_value' => false }),
    Boolean $show_krb_ticket_info = lookup('profile::kerberos::client::show_krb_ticket_info', { 'default_value' => false }),
    Boolean $enable_autorenew = lookup('profile::kerberos::client::enable_autorenew', { 'default_value' => false }),
) {

    class { 'kerberos::wrapper':
        skip_wrapper => $skip_wrapper,
    }

    $run_command_script = $::kerberos::wrapper::kerberos_run_command_script

    # Java doesn't support a different default_ccache_name value
    # from the default one, since it is hardcoded in its code
    # (see Openjdk's FileCredentialsCache.java#L448-L456).
    # It does support the KRB5CCNAME env variable override.
    if $use_new_ccache {
        $default_ccache_name = '/run/user/%{uid}/krb_cred'
        file { '/etc/profile.d/java_KRB5CCNAME.sh':
            content => 'export KRB5CCNAME=/run/user/$(id -u)/krb_cred',
        }
    }

    file { '/etc/krb5.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/kerberos/krb.conf.erb')
    }

    file { '/var/log/kerberos':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    # Create the keytabs directory and remove any unmanaged files.
    # See T294124 for further detail.
    file { '/etc/security/keytabs':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
    }

    motd::script { 'kerberos-client-info':
        priority => 1,
        source   => 'puppet:///modules/profile/kerberos/client/motd.sh',
    }

    # Use original ticket info script only if not automatically renewing
    $ensure_krb_info = ($show_krb_ticket_info and !$enable_autorenew) ? {
        true    => 'present',
        default => 'absent',
    }

    if $show_krb_ticket_info {
        file {'/etc/profile.d/kerberos_ticket_info.sh':
            ensure => $ensure_krb_info,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/profile/kerberos/client/kerberos_ticket_info.sh',
        }
    }

    file {'/etc/profile.d/kerberos_autorenew.sh':
        ensure => stdlib::ensure($enable_autorenew, 'file'),
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/kerberos/client/kerberos_autorenew.sh',
    }

    ensure_packages (['krb5-user'])

    $ensure_kstart = $enable_autorenew ? {
        true    => 'present',
        default => 'absent',
    }

    ensure_packages (['kstart'], {'ensure' => $ensure_kstart})
}
