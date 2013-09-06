class base::vimconfig {
    file { "/etc/vim/vimrc.local":
        owner => root,
        group => root,
        mode => 0444,
        source => "puppet:///modules/base/vimconfig/vimrc.local",
        ensure => present;
    }

    if $::lsbdistid == "Ubuntu" {
        # Joe is for pussies
        file { "/etc/alternatives/editor":
            ensure => "/usr/bin/vim"
        }
    }
}
