class ldap::client::pam($ldapconfig) {
    package { [ "libpam-ldapd" ]:
        ensure => latest;
    }

    File {
        owner => root,
        group => root,
        mode => 0444,
    }

    file {
        "/etc/pam.d/common-auth":
            source => "puppet:///modules/ldap/common-auth";
        "/etc/pam.d/sshd":
            source => "puppet:///modules/ldap/sshd";
        "/etc/pam.d/common-account":
            source => "puppet:///modules/ldap/common-account";
        "/etc/pam.d/common-password":
            source => "puppet:///modules/ldap/common-password";
        "/etc/pam.d/common-session":
            source => "puppet:///modules/ldap/common-session";
        "/etc/pam.d/common-session-noninteractive":
            source => "puppet:///modules/ldap/common-session-noninteractive";
    }
}

class ldap::client::nss($ldapconfig) {
    package { [ "libnss-ldapd", "nss-updatedb", "libnss-db", "nscd" ]:
        ensure => latest
    }
    package { [ "libnss-ldap" ]:
        ensure => purged;
    }

    service {
        nscd:
            subscribe => File["/etc/ldap/ldap.conf"],
            ensure => running;
        nslcd:
            ensure => running;
    }

    File {
        owner => root,
        group => root,
        mode => 0444,
    }

    file {
        "/etc/nscd.conf":
            notify => Service[nscd],
            source => "puppet:///modules/ldap/nscd.conf";
        "/etc/nsswitch.conf":
            notify => Service[nscd],
            source => "puppet:///modules/ldap/nsswitch.conf";
        "/etc/ldap.conf":
            notify => Service[nscd],
            content => template("ldap/nss_ldap.erb");
        "/etc/nslcd.conf":
            notify => Service[nslcd],
            mode => 0440,
            content => template("ldap/nslcd.conf.erb");
    }
}

# It is recommended that ldap::client::nss be included on systems that
# include ldap::client::utils, since some scripts use getent for ldap user info
# Remember though, that including ldap::client::nss will mean users in the
# ldap database will then be listed as users of the system, so use care.
class ldap::client::utils($ldapconfig) {

    package { [ "python-ldap", "python-pycurl", "python-mwclient" ]:
        ensure => latest;
    }

    file {
        "/usr/local/sbin/add-ldap-user":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/add-ldap-user";
        "/usr/local/sbin/add-labs-user":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/add-labs-user";
        "/usr/local/sbin/modify-ldap-user":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/modify-ldap-user";
        "/usr/local/sbin/delete-ldap-user":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/delete-ldap-user";
        "/usr/local/sbin/add-ldap-group":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/add-ldap-group";
        "/usr/local/sbin/modify-ldap-group":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/modify-ldap-group";
        "/usr/local/sbin/delete-ldap-group":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/delete-ldap-group";
        "/usr/local/sbin/netgroup-mod":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/netgroup-mod";
        "/usr/local/sbin/ldaplist":
            ensure => link,
            target => '/usr/local/bin/ldaplist';
        "/usr/local/bin/ldaplist":
            owner => root,
            group => root,
            mode  => 0555,
            source => "puppet:///modules/ldap/scripts/ldaplist";
        "/usr/local/sbin/change-ldap-passwd":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/change-ldap-passwd";
        "/usr/local/sbin/homedirectorymanager.py":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/homedirectorymanager.py";
        "/usr/local/sbin/manage-exports":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/manage-exports";
        "/usr/local/sbin/manage-volumes-daemon":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/manage-volumes-daemon";
        "/usr/local/sbin/manage-nfs-volumes-daemon":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/manage-nfs-volumes-daemon";
        "/usr/local/sbin/manage-volumes":
            ensure => absent;
        "/usr/local/sbin/ldapsupportlib.py":
            owner => root,
            group => root,
            mode  => 0544,
            source => "puppet:///modules/ldap/scripts/ldapsupportlib.py";
        "/etc/ldap/scriptconfig.py":
            owner => root,
            group => root,
            mode  => 0444,
            content => template("ldap/scriptconfig.py.erb");
    }

    if ( $realm != "labs" ) {
        file {
            "/etc/ldap/.ldapscriptrc":
                owner => root,
                group => root,
                mode  => 0700,
                content => template("ldap/ldapscriptrc.erb");
        }
    }
}

class ldap::client::sudo($ldapconfig) {
    if ! defined (Package['sudo-ldap']) {
        package { 'sudo-ldap':
            ensure => latest;
        }
    }
}

class ldap::client::openldap($ldapconfig) {
    package { [ "ldap-utils" ]:
        ensure => latest;
    }

    file {
        "/etc/ldap/ldap.conf":
            owner => root,
            group => root,
            mode  => 0444,
            content => template("ldap/open_ldap.erb");
    }
}

class ldap::client::autofs($ldapconfig) {
    # TODO: parametize this.
    if $realm == "labs" {
        $homedir_location = "/export/home/${instanceproject}"
        $nfs_server_name = $instanceproject ? {
            default => "labs-nfs1",
        }
        $gluster_server_name = $instanceproject ? {
            default => "projectstorage.pmtpa.wmnet",
        }
        $autofs_subscribe = ["/etc/ldap/ldap.conf", "/etc/ldap.conf", "/etc/nslcd.conf", "/data", "/public"]
    } else {
        $homedir_location = "/home"
        $nfs_server_name = "nfs-home.pmtpa.wmnet"
        $autofs_subscribe = ["/etc/ldap/ldap.conf", "/etc/ldap.conf", "/etc/nslcd.conf"]
    }

    package { [ "autofs5", "autofs5-ldap" ]:
        ensure => latest;
    }

    file {
        # autofs requires the permissions of this file to be 0600
        "/etc/autofs_ldap_auth.conf":
            owner => root,
            group => root,
            mode  => 0600,
            notify => Service[autofs],
            content => template("ldap/autofs_ldap_auth.erb");
        "/etc/default/autofs":
            owner => root,
            group => root,
            mode  => 0444,
            notify => Service[autofs],
            content => template("ldap/autofs.default.erb");
    }

    service { "autofs":
        enable => true,
        hasrestart => true,
        pattern => "automount",
        require => Package["autofs5", "autofs5-ldap", "ldap-utils", "libnss-ldapd" ],
        subscribe => File[$autofs_subscribe],
        ensure => running;
    }
}

class ldap::client::includes($ldapincludes, $ldapconfig) {
    if "openldap" in $ldapincludes {
        class { "ldap::client::openldap":
            ldapconfig => $ldapconfig
        }
    }

    if "pam" in $ldapincludes {
        class { "ldap::client::pam":
            ldapconfig => $ldapconfig
        }
    } else {
        # The ldap nss package recommends this package
        # and this package will reconfigure pam as well as add
        # its support
        package { "libpam-ldapd":
            ensure => absent;
        }
    }

    if "nss" in $ldapincludes {
        class { "ldap::client::nss":
            ldapconfig => $ldapconfig
        }
    }

    if "sudo" in $ldapincludes {
        class { "ldap::client::sudo":
            ldapconfig => $ldapconfig
        }
    }

    if "autofs" in $ldapincludes {
        class { "ldap::client::autofs":
            ldapconfig => $ldapconfig
        }
    }

    if "utils" in $ldapincludes {
        class { "ldap::client::utils":
            ldapconfig => $ldapconfig
        }
    }

    if "access" in $ldapincludes {
        file { "/etc/security/access.conf":
            owner => root,
            group => root,
            mode  => 0444,
            content => template("ldap/access.conf.erb");
        }
    }

    if $realm == "labs" {
        if $managehome {
            $ircecho_logs = { "/var/log/manage-exports.log" => "#wikimedia-labs" }
            $ircecho_nick = "labs-home-wm"
            $ircecho_server = "chat.freenode.net"

            package { "ircecho":
                ensure => latest;
            }

            service { "ircecho":
                require => Package[ircecho],
                ensure => running;
            }

            file {
                "/etc/default/ircecho":
                    require => Package[ircecho],
                    content => template('ircecho/default.erb'),
                    owner => root,
                    mode => 0755;
            }

            cron { "manage-exports":
                command => "/usr/sbin/nscd -i passwd; /usr/sbin/nscd -i group; /usr/bin/python /usr/local/sbin/manage-exports --logfile=/var/log/manage-exports.log >/dev/null 2>&1",
                require => [ File["/usr/local/sbin/manage-exports"], Package["nscd"], Package["libnss-ldapd"], Package["ldap-utils"], File["/etc/ldap.conf"], File["/etc/ldap/ldap.conf"], File["/etc/nsswitch.conf"], File["/etc/nslcd.conf"] ];
            }
        } else {
            # This was added to all nodes accidentally
            cron { "manage-exports":
                ensure => absent;
            }
        }

    }
}
