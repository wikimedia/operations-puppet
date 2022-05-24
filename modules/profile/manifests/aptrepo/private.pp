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

    class { 'httpd':}

    # If the http port is not a standard port, disable port 80
    # in ports.conf to avoid conflicts with other webservers.
    # Currently only needed during a transition from nginx to
    # Apache2.
    if ($repo_port != 80 and $repo_port != 443) {
        file_line { '/etc/apache2/ports.conf':
            path  => '/etc/apache2/ports.conf',
            line  => '# Listen 80',
            match => 'Listen 80',
        }
    }

    class { '::aptrepo':
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
        ensure       => present,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        source       => 'puppet:///modules/aptrepo/distributions-private',
        validate_cmd => '/usr/bin/python3 -c "import apt_pkg; f=\'%\'; list(apt_pkg.TagFile(f))"',
    }

    httpd::site{ 'private-apt-repo':
        content => template('aptrepo/private-apache-vhost.erb'),
    }

    # include ::profile::backup::host

    # The repository data
    backup::set { 'srv-wikimedia': }

    class { 'aptrepo::rsync':
        primary_server    => $primary_server,
        secondary_servers => $secondary_servers,
    }

    motd::script { 'inactive_warning':
        ensure   => if $primary_server == $::fqdn { 'absent' } else { 'present' },
        priority => 1,
        content  => template('profile/install_server/inactive.motd.erb'),
    }
}
