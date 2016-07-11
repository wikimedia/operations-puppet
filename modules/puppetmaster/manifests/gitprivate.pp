# Sets up the private repo dir and all the corresponding git hooks
define puppetmaster::gitprivate (
    $bare=false,
    $owner = 'root',
    $group = 'root',
    $dir_params={mode => '0750'})
{
    if $bare {
        $init = '/usr/bin/git --bare init'
        $creates = "${title}/config"
    } else {
        $init = '/usr/bin/git init'
        $creates = "${title}/.git"
    }

    # Create the directory
    $params = merge(
        {ensure => 'directory', owner => $owner, group => $group },
        $dir_params
    )
    ensure_resource('file', $title, $params)

    # Initialize a git repository (bare or otherwise)
    exec { "git init for ${title}":
        command => $init,
        user    => $owner,
        group   => $group,
        cwd     => $title,
        creates => $creates,
        require => File[$title]
    }

    # Now all the common hooks there
    file {
        "${title}/.git/hooks/post-merge":
            source  => 'puppet:///modules/puppetmaster/git/private/post-merge',
            owner   => $owner,
            group   => $group,
            mode    => '0550',
            require => Exec["git init for ${title}"];
        "${title}/.git/hooks/pre-commit":
            source  => 'puppet:///modules/puppetmaster/git/private/pre-commit',
            owner => $owner,
            group   => $group,
            mode    => '0550',
            require => Exec["git init for ${title}"];
        "${title}/.git/hooks/pre-merge":
            source  => 'puppet:///modules/puppetmaster/git/private/pre-merge',
            owner => $owner,
            group   => $group,
            mode    => '0550',
            require => Exec["git init for ${title}"];
        "${title}/.git/hooks/pre-rebase":
            source  => 'puppet:///modules/puppetmaster/git/private/pre-rebase',
            owner => $owner,
            group   => $group,
            mode    => '0550',
            require => Exec["git init for ${title}"];
    }

}
