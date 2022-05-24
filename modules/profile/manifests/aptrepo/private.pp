# SPDX-License-Identifier: Apache-2.0

class profile::aptrepo::private (
    Stdlib::Fqdn $primary_server           = lookup('profile::aptrepo::private::primary_server'),
    Array[Stdlib::Fqdn] $secondary_servers = lookup('profile::aptrepo::private::secondary_servers'),
    Stdlib::Unixpath $basedir              = lookup('profile::aptrepo::wikimedia::basedir'),
    Stdlib::Unixpath $homedir              = lookup('profile::aptrepo::wikimedia::basedir'),
    String $aptrepo_hostname               = lookup('profile::aptrepo::private::servername'),
    String $gpg_user                       = lookup('profile::aptrepo::wikimedia::gpg_user'),
    Optional[String] $gpg_pubring          = lookup('profile::aptrepo::wikimedia::gpg_pubring', {'default_value' => undef}),
    Optional[String] $gpg_secring          = lookup('profile::aptrepo::wikimedia::gpg_secring', {'default_value' => undef}),
    Optional[Integer] $repo_port           = lookup('profile::aptrepo::private::port', {'default_value' => 8080}),
){

    # Group and user is temporarily added, as CloudVPS does not have
    # the user and group created automatically.
    # TODO: REMOVE
    group { 'reprepro':
        ensure => present,
        gid    => 901,
    }

    user { 'reprepro':
        ensure => present,
        shell  => '/bin/sh',
        home   => '/var/lib/reprepro',
        uid    => 901,
        gid    => 901,
    }

    class { 'httpd':
        remove_default_ports => true,
    }
    httpd::conf { 'listen on configured port':
        ensure   => present,
        priority => 0,
        content  => "Listen ${repo_port}\n",
    }

    class { 'aptrepo':
        basedir       => $basedir,
        homedir       => $homedir,
        incomingconf  => 'incoming-wikimedia',
        incominguser  => 'root',
        # Allow wikidev users to upload to /srv/wikimedia/incoming
        incominggroup => 'wikidev',
        gpg_pubring   => $gpg_pubring,
        gpg_secring   => $gpg_secring,
        gpg_user      => $gpg_user,
    }

    file { "${basedir}/conf/distributions":
        ensure       => file,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        source       => 'puppet:///modules/profile/aptrepo/distributions-private',
        validate_cmd => '/usr/bin/python3 -c "import apt_pkg; f=\'%\'; list(apt_pkg.TagFile(f))"',
    }

    httpd::site{ 'private-apt-repo':
        content => template('profile/aptrepo/private-apache-vhost.erb'),
    }

    # include ::profile::backup::host

    # The repository data
    backup::set { 'srv-wikimedia': }

    class { 'aptrepo::rsync':
        primary_server    => $primary_server,
        secondary_servers => $secondary_servers,
    }

    motd::script { 'inactive_warning':
        ensure   => ($primary_server == $facts['networking']['fqdn']).bool2str('absent', 'present'),
        priority => 1,
        content  => template('profile/install_server/inactive.motd.erb'),
    }
}
