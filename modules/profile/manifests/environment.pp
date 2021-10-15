# == Class profile::environment
#
# Sets up the base environment for all hosts (profile, editor, sysctl, etc)
#
# === Parameters
# @ls_aliases if true, will setup the ll/la aliases
# @custom_bashrc when set, will replace the system bashrc with the given template (as a path)
# @custom_skel_bashrc when set, will replace the system skel bashrc with the given template (as a path)
# @editor choose the default editor, if 'use_default' will use the system's default
# @profile_scripts list of script names to be added to /etc/profile.d and their source
# @core_dump_pattern pattern to use when generating core dumps
#
class profile::environment (
    Boolean $ls_aliases = lookup('profile::environment::ls_aliases'),
    Optional[String[1]] $custom_skel_bashrc = lookup('profile::environment::custom_skel_bashrc'),
    Optional[String[1]] $custom_bashrc = lookup('profile::environment::custom_bashrc'),
    Enum['vim', 'use_default'] $editor = lookup('profile::environment::editor'),
    Hash[String, Stdlib::Filesource] $profile_scripts = lookup('profile::environment::profile_scripts'),
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

    # Global vim defaults
    file { '/etc/vim/vimrc.local':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/environment/vimrc.local',
    }
}
