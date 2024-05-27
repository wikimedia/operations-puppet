# SPDX-License-Identifier: Apache-2.0
# @ summary Prove an apt-repository of local or patched Debian
#   packages. Packages placed in this repository must
#   be licensed in that allows Wikimedia to distribute
#   the software. The repository can be access via:
#   https://apt.wikimedia.org/wikimedia/
#
# @param primary_server The primary server where packages are uploaded and served.
# @param secondary_servers The standby servers. Receive packages via rsync.
#                          These are simply standby servers and not in active use,
#   unless failover/switch over is performed.
# @param aptrepo_vhost the vhost used by apt
# @param public_basedir Where public reprepro stores configuration and distribution files.
# @param private_basedir Where private reprepro stores configuration and distribution files.
# @param homedir Where to store the GPG keys for signing. GPG keys will be
#                stored in .gnupg relative to this path.
# @param gpg_user Owner of the GPG keys.
# @param ztp_juniper_root_password The hash of temp password used in Juniper ZTP file tempalate.
# @param gpg_pubring The GPG public keyring for reprepro to use. Will be passed to secret().
# @param gpg_secring The GPG secret keyring for reprepro to use. Will be passed to secret().
# @param private_repo_port the port of the private repo web site
# @param upload_keys an array of PGP pubkeys which are permitted to upload packages to the
#        incoming directory
class profile::aptrepo::wikimedia (
    Stdlib::Fqdn            $primary_server            = lookup('profile::aptrepo::wikimedia::aptrepo_server'),
    Array[Stdlib::Fqdn]     $secondary_servers         = lookup('profile::aptrepo::wikimedia::aptrepo_servers_failover'),
    String                  $aptrepo_vhost             = lookup('profile::aptrepo::wikimedia::aptrepo_hostname'),
    Stdlib::Unixpath        $public_basedir            = lookup('profile::aptrepo::wikimedia::public_basedir'),
    Stdlib::Unixpath        $private_basedir           = lookup('profile::aptrepo::wikimedia::private_basedir'),
    Stdlib::Unixpath        $homedir                   = lookup('profile::aptrepo::wikimedia::homedir'),
    String                  $gpg_user                  = lookup('profile::aptrepo::wikimedia::gpg_user'),
    String                  $ztp_juniper_root_password = lookup('profile::aptrepo::wikimedia::ztp_juniper_root_password'),
    Optional[String]        $gpg_pubring               = lookup('profile::aptrepo::wikimedia::gpg_pubring'),
    Optional[String]        $gpg_secring               = lookup('profile::aptrepo::wikimedia::gpg_secring'),
    Optional[Stdlib::Port]  $private_repo_port         = lookup('profile::aptrepo::wikimedia::private_port'),
    Optional[Array[String]] $upload_keys               = lookup('profile::aptrepo::wikimedia::upload_keys'),
) {
    firewall::service { 'aptrepos_public_http':
        proto => 'tcp',
        port  => [80,443],
    }

    firewall::service { 'aptrepos_private_http':
        proto    => 'tcp',
        port     => $private_repo_port,
        src_sets => ['DOMAIN_NETWORKS', 'MGMT_NETWORKS'],
    }

    class { 'aptrepo::common':
        homedir     => $homedir,
        basedir     => $public_basedir,
        gpg_user    => $gpg_user,
        gpg_secring => $gpg_secring,
        gpg_pubring => $gpg_pubring,
    }

    # Public repo, served by nginx
    aptrepo::repo { 'public_apt_repository':
        basedir            => $public_basedir,
        incomingdir        => 'incoming',
        upload_keys        => $upload_keys,
        distributions_file => 'puppet:///modules/aptrepo/distributions-wikimedia',
    }

    # Private repo, served by Apache
    aptrepo::repo { 'private_apt_repository':
        basedir            => $private_basedir,
        incomingdir        => 'incoming',
        distributions_file => 'puppet:///modules/aptrepo/distributions-private',
    }

    $private_reprepro_wrapper = @("SCRIPT" /$)
    #!/bin/bash
    REPREPRO_BASE_DIR=${private_basedir} /usr/bin/reprepro "$@"
    |SCRIPT
    file { '/usr/local/sbin/private_reprepro':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
        content => $private_reprepro_wrapper,
    }

    class { 'aptrepo::tftp': }
    include profile::backup::host

    class { 'aptrepo::ztp_juniper':
        ztp_juniper_root_password => $ztp_juniper_root_password
    }

    # The repository data
    backup::set { 'srv-wikimedia': }

    class { 'aptrepo::rsync':
        primary_server    => $primary_server,
        secondary_servers => $secondary_servers,
    }

    if $primary_server == $facts['networking']['fqdn'] {
        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => 'check_ssl_http_letsencrypt_ocsp!apt.wikimedia.org',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/APT_repository',
        }
        $motd_ensure = 'absent'
    } else {
        $motd_ensure = 'present'
    }

    motd::message { '01_inactive_warning':
        ensure   => $motd_ensure,
        priority => 99,  # Use hi priority to ensure this is the last message
        color    => 'red',
        message  => '*** This is not the active server DO Not USE ***'
    }
    motd::message { '02_inactive_warning':
        ensure   => $motd_ensure,
        priority => 99,  # Use hi priority to ensure this is the last message
        color    => 'red',
        message  => "Please use ${primary_server} instead. It will rsync to ${facts['networking']['hostname']}"
    }
}
