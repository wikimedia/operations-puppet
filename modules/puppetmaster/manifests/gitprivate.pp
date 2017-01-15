# Sets up the private repo dir and all the corresponding git hooks
define puppetmaster::gitprivate (
    $bare=false,
    $owner='root',
    $group='root',
    $dir_mode='0750',
    $origin=undef,
    ){

    if $bare {
        $init = '/usr/bin/git --bare init'
        $creates = "${title}/config"
        $prefix = $title
    } else {
        $init = '/usr/bin/git init'
        $creates = "${title}/.git"
        $prefix = $creates
    }

    if ($origin and !$bare) {
        git::clone { 'operations/private':
            directory => $title,
            owner     => $owner,
            group     => $group,
            origin    => $origin,
            mode      => $dir_mode,
        }
    } else {
        # Create the directory
        file { $title:
            ensure => directory,
            owner  => $owner,
            group  => $group,
            mode   => $dir_mode,
        }


        # Initialize a git repository (bare or otherwise)
        exec { "git init for ${title}":
            command => $init,
            user    => $owner,
            group   => $group,
            cwd     => $title,
            creates => $creates,
            require => File[$title],
        }
    }


    # Now all the common hooks there
    file {
        "${prefix}/hooks/post-merge":
            ensure => 'absent';
        "${prefix}/hooks/pre-commit":
            source => 'puppet:///modules/puppetmaster/git/private/pre-commit',
            owner  => $owner,
            group  => $group,
            mode   => '0550';
        "${prefix}/hooks/pre-merge":
            source => 'puppet:///modules/puppetmaster/git/private/pre-merge',
            owner  => $owner,
            group  => $group,
            mode   => '0550';
        "${prefix}/hooks/pre-rebase":
            source => 'puppet:///modules/puppetmaster/git/private/pre-rebase',
            owner  => $owner,
            group  => $group,
            mode   => '0550';
    }

}
