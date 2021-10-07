# == Class profile::environment
#
# Sets up the base environment for all hosts (profile, editor, sysctl, etc)
#
# === Parameters
# @ls_aliases if true, will setup the ll/la aliases
# @custom_bashrc when set, will replace the system bashrc with the given template (as a path)
# @custom_skel_bashrc when set, will replace the system skel bashrc with the given template (as a path)
# @editor choose the default editor, if 'use_default' will use the system's default
# @with_wmcs_etc_files if true, will add some extra files to /etc related to wmcs project, instance name, etc.
# @profile_scripts list of script names to be added to /etc/profile.d and their source
# @core_dump_pattern pattern to use when generating core dumps
#
class profile::environment (
    Boolean $ls_aliases = lookup('profile::environment::ls_aliases'),
    Optional[String[1]] $custom_skel_bashrc = lookup('profile::environment::custom_skel_bashrc'),
    Optional[String[1]] $custom_bashrc = lookup('profile::environment::custom_bashrc'),
    Enum['vim', 'use_default'] $editor = lookup('profile::environment::editor'),
    Boolean $with_wmcs_etc_files = lookup('profile::environment::with_wmcs_etc_files'),
    Hash[String, Stdlib::Filesource] $profile_scripts = lookup('profile::environment::profile_scripts'),
    String $core_dump_pattern = lookup('profile::environment::core_dump_pattern'),
) {
    if $ls_aliases {
        exec { 'uncomment root bash aliases':
            path    => '/bin:/usr/bin',
            command => "sed -i '
                    /^#alias ll=/ s/^#//
                    /^#alias la=/ s/^#//
                ' /root/.bashrc",
            onlyif  => "grep -q '^#alias ll' /root/.bashrc",
        }
    }

    if $custom_bashrc {
        file { '/etc/bash.bashrc':
                content => template($custom_bashrc),
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
        }
    }
    if $custom_skel_bashrc {
        file { '/etc/skel/.bashrc':
                content => template($custom_skel_bashrc),
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
        }
    }

    if $editor != 'use_default' {
        file { '/etc/alternatives/editor':
            ensure => link,
            target => "/usr/bin/${editor}",
        }
    }

    if $with_wmcs_etc_files {
        # TODO in next patches: Move to it's own cloud profile/class
        # wmflabs_imageversion is provided by labs_vmbuilder/files/postinst.copy
        # because this is a pre-installed file, migrating is nontrivial, so we keep
        # the original file name.
        file { '/etc/wmcs-imageversion':
            ensure => link,
            target => '/etc/wmflabs_imageversion',
        }

        file { '/etc/wmcs-instancename':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "${::hostname}\n",
        }
        file { '/etc/wmflabs-instancename':
            ensure => link,
            target => '/etc/wmcs-instancename',
        }
        if( $::labsproject ) {
            file { '/etc/wmcs-project':
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => "${::labsproject}\n",
            }
            file { '/etc/wmflabs-project':
                ensure => link,
                target => '/etc/wmcs-project',
            }
        }
    }

    $profile_scripts.each |$name, $source| {
        file {
            "/etc/profile.d/${name}":
                ensure => present,
                owner  => 'root',
                group  => 'root',
                mode   => '0444',
                source => $source,
        }
    }

    ### Settings commons to all realms

    $wikimedia_cluster = $::realm ? {
        'labs'  => "labs\n",
        default => "${::site}\n",
    }

    file { '/etc/wikimedia-cluster':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $wikimedia_cluster,
    }

    # script to generate ssh fingerprints of the server
    file { '/usr/local/bin/gen_fingerprints':
        source => 'puppet:///modules/base/environment/gen_fingerprints',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    ### Core dumps
    # TODO in next patches: move under base::sysctl::coredupms
    # Write core dumps to /var/tmp/core/core.<host>.<executable>.<pid>.<timestamp>.
    # Remove core dumps with atime > one week.

    file { '/var/tmp/core':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '1773',
    }

    sysctl::parameters { 'core_dumps':
        values  => { 'kernel.core_pattern' => $core_dump_pattern, },
        require => File['/var/tmp/core'],
    }

    tidy { '/var/tmp/core':
        age     => '1w',
        recurse => 1,
        matches => 'core.*',
    }

    # Global vim defaults
    file { '/etc/vim/vimrc.local':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/environment/vimrc.local',
    }
}
