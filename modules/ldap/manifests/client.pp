class ldap::client::pam($ldapconfig) {
    package { 'libpam-ldapd':
        ensure => latest,
    }

    File {
        owner => 'root',
        group => 'root',
        mode  => '0444',
    }

    file { '/etc/pam.d/common-auth':
            source => 'puppet:///modules/ldap/common-auth',
    }

    file { '/etc/pam.d/sshd':
            source => 'puppet:///modules/ldap/sshd',
    }

    file { '/etc/pam.d/common-account':
            source => 'puppet:///modules/ldap/common-account',
    }

    file { '/etc/pam.d/common-password':
            source => 'puppet:///modules/ldap/common-password',
    }

    file { '/etc/pam.d/common-session':
            source => 'puppet:///modules/ldap/common-session',
    }

    file { '/etc/pam.d/common-session-noninteractive':
            source => 'puppet:///modules/ldap/common-session-noninteractive',
    }
}

class ldap::client::nss($ldapconfig) {
    package { [ 'libnss-ldapd',
                'nss-updatedb',
                'libnss-db',
                'nscd' ]:
        ensure => latest,
    }
    package { [ 'libnss-ldap' ]:
        ensure => purged,
    }

    service { 'nscd':
        ensure    => running,
        subscribe => File['/etc/ldap/ldap.conf'],
    }

    service { 'nslcd':
        ensure => running,
    }

    File {
        owner => 'root',
        group => 'root',
        mode  => '0444',
    }

    file { '/etc/nscd.conf':
        notify => Service['nscd'],
        source => 'puppet:///modules/ldap/nscd.conf',
    }

    file { '/etc/nsswitch.conf':
        notify => Service['nscd'],
        source => 'puppet:///modules/ldap/nsswitch.conf',
    }

    file { '/etc/ldap.conf':
        notify  => Service['nscd'],
        content => template('ldap/nss_ldap.erb'),
    }

    file { '/etc/nslcd.conf':
        notify  => Service[nslcd],
        mode    => '0440',
        content => template('ldap/nslcd.conf.erb'),
    }
}

# It is recommended that ldap::client::nss be included on systems that
# include ldap::client::utils, since some scripts use getent for ldap user info
# Remember though, that including ldap::client::nss will mean users in the
# ldap database will then be listed as users of the system, so use care.
class ldap::client::utils($ldapconfig) {

    package { [ 'python-ldap',
                'python-pycurl',
                'python-mwclient' ]:
        ensure => latest,
    }

    file { '/usr/local/sbin/add-ldap-user':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/add-ldap-user',
    }

    file { '/usr/local/sbin/add-labs-user':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/add-labs-user',
    }

    file { '/usr/local/sbin/modify-ldap-user':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/modify-ldap-user',
    }

    file { '/usr/local/sbin/delete-ldap-user':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/delete-ldap-user',
    }

    file { '/usr/local/sbin/add-ldap-group':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/add-ldap-group',
    }

    file { '/usr/local/sbin/modify-ldap-group':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/modify-ldap-group',
    }

    file { '/usr/local/sbin/delete-ldap-group':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/delete-ldap-group',
    }

    file { '/usr/local/sbin/netgroup-mod':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/netgroup-mod',
    }

    file { '/usr/local/sbin/ldaplist':
        ensure => link,
        target => '/usr/local/bin/ldaplist',
    }

    file { '/usr/local/bin/ldaplist':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/ldap/scripts/ldaplist',
    }

    file { '/usr/local/sbin/change-ldap-passwd':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/change-ldap-passwd',
    }

    file { '/usr/local/sbin/homedirectorymanager.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/homedirectorymanager.py',
    }

    file { '/usr/local/sbin/manage-nfs-volumes-daemon':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/ldap/scripts/manage-nfs-volumes-daemon',
    }

    file { '/usr/local/sbin/sync-exports':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/ldap/scripts/sync-exports',
    }

    file { '/usr/local/sbin/manage-keys-nfs':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/manage-keys-nfs',
    }

    file { ['/usr/local/bin/ldapsupportlib.py',
            '/usr/local/sbin/ldapsupportlib.py']:
        ensure => absent,
    }

    file { '/usr/local/lib/python2.7/dist-packages/ldapsupportlib.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/ldap/scripts/ldapsupportlib.py',
    }

    file { '/etc/ldap/scriptconfig.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ldap/scriptconfig.py.erb'),
    }

    if ( $::realm != 'labs' ) {
        file { '/etc/ldap/.ldapscriptrc':
            owner   => 'root',
            group   => 'root',
            mode    => '0700',
            content => template('ldap/ldapscriptrc.erb'),
        }
    }
}

class ldap::client::sudo($ldapconfig) {
    if ! defined (Package['sudo-ldap']) {
        package { 'sudo-ldap':
            ensure => latest,
        }
    }
}

class ldap::client::openldap($ldapconfig, $ldapincludes) {
    package { 'ldap-utils':
        ensure => latest,
    }

    file { '/etc/ldap/ldap.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ldap/open_ldap.erb'),
    }
}

class ldap::client::autofs($ldapconfig) {
    # TODO: parametize this.
    if $::realm == 'labs' {
        $homedir_location = "/export/home/${instanceproject}"
        $nfs_server_name = $instanceproject ? {
            default => 'labs-nfs1',
        }
        $gluster_server_name = $instanceproject ? {
            default => 'projectstorage.pmtpa.wmnet',
        }
        $autofs_subscribe = ['/etc/ldap/ldap.conf', '/etc/ldap.conf', '/etc/nslcd.conf', '/data', '/public']
    } else {
        $homedir_location = '/home'
        $nfs_server_name = 'nfs-home.pmtpa.wmnet'
        $autofs_subscribe = ['/etc/ldap/ldap.conf', '/etc/ldap.conf', '/etc/nslcd.conf']
    }

    package { [ 'autofs5', 'autofs5-ldap' ]:
        ensure => 'latest',
    }

# autofs requires the permissions of this file to be 0600
    file { '/etc/autofs_ldap_auth.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        notify  => Service['autofs'],
        content => template('ldap/autofs_ldap_auth.erb'),
    }

    file { '/etc/default/autofs':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['autofs'],
        content => template('ldap/autofs.default.erb'),
    }

    service { 'autofs':
        ensure     => running,
        enable     => true,
        hasrestart => true,
        pattern    => 'automount',
        require    => Package['autofs5', 'autofs5-ldap', 'ldap-utils', 'libnss-ldapd' ],
        subscribe  => File[$autofs_subscribe],
    }
}

class ldap::client::includes($ldapincludes, $ldapconfig) {
    if 'openldap' in $ldapincludes {
        class { 'ldap::client::openldap':
            ldapconfig   => $ldapconfig,
            ldapincludes => $ldapincludes,
        }
    }

    if 'pam' in $ldapincludes {
        class { 'ldap::client::pam':
            ldapconfig => $ldapconfig
        }
    } else {
        # The ldap nss package recommends this package
        # and this package will reconfigure pam as well as add
        # its support
        package { 'libpam-ldapd':
            ensure => absent,
        }
    }

    if 'nss' in $ldapincludes {
        class { 'ldap::client::nss':
            ldapconfig => $ldapconfig
        }
    }

    if 'sudo' in $ldapincludes {
        class { 'ldap::client::sudo':
            ldapconfig => $ldapconfig
        }
    }

    if 'autofs' in $ldapincludes {
        class { 'ldap::client::autofs':
            ldapconfig => $ldapconfig
        }
    }

    if 'utils' in $ldapincludes {
        class { 'ldap::client::utils':
            ldapconfig => $ldapconfig
        }
    }

    if 'access' in $ldapincludes {
        file { '/etc/security/access.conf':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('ldap/access.conf.erb'),
        }
    }
}
