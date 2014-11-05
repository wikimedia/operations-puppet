class base::environment {
    case $::realm {
        'production': {
            exec { 'uncomment root bash aliases':
                path    => '/bin:/usr/bin',
                command => "sed -i '
                        /^#alias ll=/ s/^#//
                        /^#alias la=/ s/^#//
                    ' /root/.bashrc",
                onlyif  => "grep -q '^#alias ll' /root/.bashrc"
            }

            file { '/etc/profile.d/mysql-ps1.sh':
                    ensure => present,
                    owner  => 'root',
                    group  => 'root',
                    mode   => '0444',
                    source => 'puppet:///modules/base/environment/mysql-ps1.sh',
            }

            file { '/etc/alternatives/editor':
                ensure => link,
                target => '/usr/bin/vim',
            }

        } # /production
        'labs': {
            file { '/etc/bash.bashrc':
                    content => template('base/environment/bash.bashrc'),
                    owner   => 'root',
                    group   => 'root',
                    mode    => '0444',
            }

            file { '/etc/skel/.bashrc':
                    content => template('base/environment/skel/bashrc'),
                    owner   => 'root',
                    group   => 'root',
                    mode    => '0644',
            }
            if( $::instancename ) {
                file { '/etc/wmflabs-instancename':
                    owner   => 'root',
                    group   => 'root',
                    mode    => '0444',
                    content => "${::instancename}\n",
                }
            }
            if( $::instanceproject ) {
                file { '/etc/wmflabs-project':
                    owner   => 'root',
                    group   => 'root',
                    mode    => '0444',
                    content => "${::instanceproject}\n",
                }
            }
        } # /labs
        default: {
            err('realm must be either "labs" or "production".')
        }
    }

    ### Settings commons to all realms

    # Once upon a time provided by wikimedia-base debian package
    file { '/etc/wikimedia-site':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "${::site}\n",
    }

    file { '/etc/wikimedia-realm':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "${::realm}\n",
    }


    ### Core dumps

    # Write core dumps to /var/tmp/core/core.<host>.<executable>.<pid>.<timestamp>.
    # Remove core dumps with atime > one week.

    file { '/var/tmp/core':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0703',
    }

    sysctl::parameters { 'core_dumps':
        # Core filename pattern: 'core.<host>.<executable>.<pid>.<timestamp>'
        values  => { 'kernel.core_pattern' => '/var/tmp/core/core.%h.%e.%p.%t', },
        require => File['/var/tmp/core'],
    }

    tidy { '/var/tmp/core':
        age     => '1w',
        recurse => 1,
        matches => 'core.*',
    }

}
