# SPDX-License-Identifier: Apache-2.0
# @summary
#   Configure a reprepro apt repository on a server.
#
# @param basedir
#   The reprepro base directory.
# @param distributions_file
#   the puppet location of the distributions file
# @param notify_address
#   Where to send upload notifications.
# @param notify_subject
#   The upload notifications subject.
# @param options
#   A list of options for reprepro (see conf/options file).
# @param uploaders
#   A list of uploaders instructions (see "uploaders file")
# @param incomingdir
#   Path considered for incoming uploads.
# @param incomingconf
#   Name of a template with config options for incoming uploads. (conf/incoming)
# @param incominguser
#   The user name that owns the incoming directory.
# @param incominggroup
#   The group name that owns the incoming directory.
# @param default_distro
#   The default distro to use
define aptrepo::repo (
    Stdlib::Unixpath   $basedir,
    Stdlib::Filesource $distributions_file,
    String             $notify_address     = 'root@wikimedia.org',
    String             $notify_subject     = "Reprepro changes in ${title}",
    Array[String]      $options            = [],
    Array[String]      $uploaders          = [],
    Optional[String]   $incomingdir        = undef,
    String             $incomingconf       = 'incoming-wikimedia',
    String             $incominguser       = 'root',
    String             $incominggroup      = 'wikidev',
    String             $default_distro     = 'buster',
) {
    $user = $aptrepo::common::user
    $group = $aptrepo::common::group

    ensure_packages('python3-apt')
    $deb822_validate_cmd = '/usr/bin/python3 -c "import apt_pkg; f=\'%\'; list(apt_pkg.TagFile(f))"'

    file { $basedir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${basedir}/conf":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${basedir}/conf/updates":
        ensure       => file,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        source       => 'puppet:///modules/aptrepo/updates',
        validate_cmd => $deb822_validate_cmd,
    }

    file { "${basedir}/conf/pulls":
        ensure       => file,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        source       => 'puppet:///modules/aptrepo/pulls',
        validate_cmd => $deb822_validate_cmd,
    }

    file { "${basedir}/conf/options":
        ensure       => file,
        owner        => $user,
        group        => $group,
        mode         => '0444',
        content      => inline_template("<%= @options.join(\"\n\") %>\n"),
        validate_cmd => $deb822_validate_cmd,
    }

    file { "${basedir}/conf/uploaders":
        ensure       => file,
        owner        => $user,
        group        => $group,
        mode         => '0444',
        content      => inline_template("<%= @options.join(\"\n\") %>\n"),
        validate_cmd => $deb822_validate_cmd,
    }

    file { "${basedir}/conf/distributions":
        ensure       => file,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        source       => $distributions_file,
        validate_cmd => $deb822_validate_cmd,
    }

    # Reprepro needs the deb-override file to exist.
    # For apt1001/2001 this file already exist and have
    # content which is not managed by Puppet.
    file { "${basedir}/conf/deb-override":
        ensure  => file,
        replace => 'no',
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
    }

    if $incomingdir != undef {
        file { "${basedir}/conf/incoming":
            ensure       => file,
            owner        => 'root',
            group        => 'root',
            mode         => '0444',
            content      => template("aptrepo/${incomingconf}.erb"),
            validate_cmd => $deb822_validate_cmd,
        }
    }

    $log_script = @("SCRIPT"/$)
    #!/bin/bash
    echo -e "reprepro changes:\n\$@" | mail -s "${notify_subject}" ${notify_address}
    | SCRIPT
    file { "${basedir}/conf/log":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => $log_script,
    }

    file { "${basedir}/db":
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0755',
    }

    file { "${basedir}/logs":
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0755',
    }

    file { "${basedir}/tmp":
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0755',
    }

    if $incomingdir != undef {
        file { "${basedir}/${incomingdir}":
            ensure => directory,
            mode   => '1775',
            owner  => $incominguser,
            group  => $incominggroup,
        }
    }
}
