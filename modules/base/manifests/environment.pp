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
    $core_dump_pattern = '/var/tmp/core/core.%h.%e.%p.%t',
){
    case $::realm {
        'production': {
            exec { 'uncomment root bash aliases':
                path    => '/bin:/usr/bin',
                command => "sed -i '
                        /^#alias ll=/ s/^#//
                        /^#alias la=/ s/^#//
                    ' /root/.bashrc",
                onlyif  => "grep -q '^#alias ll' /root/.bashrc",
            }

            file { '/etc/profile.d/mysql-ps1.sh':
                    ensure => present,
                    owner  => 'root',
                    group  => 'root',
                    mode   => '0444',
                    source => 'puppet:///modules/base/environment/mysql-ps1.sh',
            }

            file { '/etc/profile.d/bash_autologout.sh':
                    ensure => present,
                    owner  => 'root',
                    group  => 'root',
                    mode   => '0755',
                    source => 'puppet:///modules/base/environment/bash_autologout.sh',
            }

            file { '/etc/alternatives/editor':
                ensure => link,
                target => '/usr/bin/vim',
            }

        } # /production
        'labs': {
            file { '/etc/bash.bashrc':
                    content => template('base/environment/bash.bashrc.erb'),
                    owner   => 'root',
                    group   => 'root',
                    mode    => '0444',
            }

            file { '/etc/skel/.bashrc':
                    content => template('base/environment/skel/bashrc.erb'),
                    owner   => 'root',
                    group   => 'root',
                    mode    => '0644',
            }

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
        } # /labs
        default: {
            err('realm must be either "labs" or "production".')
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

    file { '/etc/profile.d/field.sh':
        source => 'puppet:///modules/base/environment/field.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # script to generate ssh fingerprints of the server
    file { '/usr/local/bin/gen_fingerprints':
        source => 'puppet:///modules/base/environment/gen_fingerprints',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    ### Core dumps

    # Write core dumps to /var/tmp/core/core.<host>.<executable>.<pid>.<timestamp>.
    # Remove core dumps with atime > one week.

    file { '/var/tmp/core':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '1773',
    }

    # lint:ignore:arrow_alignment
    sysctl::parameters { 'core_dumps':
        values  => { 'kernel.core_pattern' => $core_dump_pattern, },
        require => File['/var/tmp/core'],
    }

    # lint:endignore
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
