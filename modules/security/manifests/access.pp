# == security::access ==
#
# Allows defining an access.conf stanza to limit logins into the server to
# specified sets of groups or users.  See access.conf(5) for syntax
#
# The actual /etc/security/access.conf file is constructed from fragments
# created by those resources and collected in /etc/security/access.conf.d
# ordered by (numeric) priority.
#
# Having a security::access resource in the manifest implicitly pulls in
# the security::access::conf class that creates the access.conf.d directory
# and adds access.conf checking to the system PAM configuration.
#
# === Parameters ===
#
# [*content*]
#   The content of the access.conf fragment.  Either this or [*source*]
#   must be specified.
#
# [*source*]
#   The source of the access.conf fragment.  Either this or [*content*]
#   must be specified.
#
# [*priority*]
#   The priority at which the fragment will be concatenated with any
#   other specified ones, with lower priorities coming first in the
#   resulting access.conf file.  Note that access.conf is evaluated in
#   order, with the first matching entry being used.
#
# === Example ===
#
# This resource limits logging into the server only to the "ops" group
# and the root user:
#
# security::access { 'ospen-only':
#    content => "- : ALL EXCEPT (ops) root : ALL\n",
# }

define security::access(
    $content  = undef,
    $source   = undef,
    $priority = 50,
)
{
    include security::access::conf

    file { "/etc/security/access.conf.d/${priority}-${name}":
        ensure   => present,
        source   => $source,
        content  => $content,
        owner    => 'root',
        group    => 'root',
        mode     => '0444',
        require  => File['/etc/security/access.conf.d'],
    }
}


class security::access::conf
{
    file { '/etc/security/access.conf.d':
        ensure  => directory,
        recurse => true,
        purge   => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        notify  => Exec['merge-access-conf'],
    }

    exec { 'merge-access-conf':
        refreshonly => true,
        cwd         => '/etc/security',
        command     => '/bin/cat access.conf.d/* >access.conf~ && mv access.conf~ access.conf',
    }

    security::pam::config { 'wikimedia-pam-access':
        source => 'puppet:///modules/security/wikimedia-pam-access',
    }
}

