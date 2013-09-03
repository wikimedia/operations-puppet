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

            file {
                '/etc/profile.d/mysql-ps1.sh':
                    ensure => present,
                    owner  => root,
                    group  => root,
                    mode   => '0444',
                    source => 'puppet:///files/environment/mysql-ps1.sh';
            }
        } # /production
        'labs': {
            file {
                '/etc/bash.bashrc':
                    content => template('environment/bash.bashrc'),
                    owner   => root,
                    group   => root,
                    mode    => '0444';
                '/etc/skel/.bashrc':
                    content => template('environment/skel/bashrc'),
                    owner   => root,
                    group   => root,
                    mode    => '0644';
            }
            if( $::instancename ) {
                file { '/etc/wmflabs-instancename':
                    owner   => root,
                    group   => root,
                    mode    => '0444',
                    content => "${::instancename}\n" ;
                }
            }
            if( $::instanceproject ) {
                file { '/etc/wmflabs-project':
                    owner   => root,
                    group   => root,
                    mode    => '0444',
                    content => "${::instanceproject}\n" ;
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
        owner   => root,
        group   => root,
        mode    => '0444',
        content => "${::site}\n" ;
    }

    file { '/etc/wikimedia-realm':
        owner   => root,
        group   => root,
        mode    => '0444',
        content => "${::realm}\n" ;
    }

}
