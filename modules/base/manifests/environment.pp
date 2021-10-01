# = Class: base::environment
#
# Sets up the base environment for all hosts (profile, editor, sysctl, etc)
#
# = Parameters
#
# [*core_dump_pattern*]
#   Sets the pattern for the path where core dumps are kept.
#   See documentation for values at http://man7.org/linux/man-pages/man5/core.5.html under 'Naming of core dump files'
#
class base::environment(
    String $core_dump_pattern = '/var/tmp/core/core.%h.%e.%p.%t',
){
    case $::realm {
        'production': {
            $ls_aliases = true
            $custom_bashrc = undef
            $custom_skel_bashrc = undef
            $editor = 'vim'
            $with_wmcs_etc_files = false
            $profile_scripts = {
                'mysql-ps1.sh' => 'puppet:///modules/base/environment/mysql-ps1.sh',
                'bash_autologout.sh' => 'puppet:///modules/base/environment/bash_autologout.sh',
                'field.sh' => 'puppet:///modules/base/environment/field.sh',
            }
        } # /production
        'labs': {
            $ls_aliases = false
            $custom_bashrc = template('base/environment/bash.bashrc.erb')
            $custom_skel_bashrc = template('base/environment/skel/bashrc.erb')
            $editor = 'use_default'
            $with_wmcs_etc_files = true
            $profile_scripts = {
                'field.sh' => 'puppet:///modules/base/environment/field.sh',
            }
        } # /labs
        default: {
            err('realm must be either "labs" or "production".')
        }
    }

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
                content => $custom_bashrc,
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
        }
    }
    if $custom_skel_bashrc {
        file { '/etc/skel/.bashrc':
                content => $custom_skel_bashrc,
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
