class toollabs::mono_external {
    #
    # external repo configuration
    #
    $mono_repo_url = $facts['lsbdistcodename'] ? {
        'trusty' => 'https://download.mono-project.com/repo/ubuntu',
        'jessie' => 'https://download.mono-project.com/repo/debian',
    }
    $mono_repo_dist = $facts['lsbdistcodename'] ? {
        'trusty' => 'stable-trusty',
        'jessie' => 'stable-jessie',
    }
    apt::repository { 'monoproject':
        uri        => $mono_repo_url,
        dist       => $mono_repo_dist,
        components => 'main',
        keyfile    => 'puppet:///modules/toollabs/mono_external_apt.key',
        notify     => Exec['apt_key_and_update'];
    }

    # First installs can trip without this seeing the mid-run repo as untrusted
    exec {'apt_key_and_update':
        command     => '/usr/bin/apt-key update && /usr/bin/apt-get update',
        refreshonly => true,
        logoutput   => true,
    }

    #
    # apt pinnings to use the external repo
    #
    $mono_pinning = $facts['lsbdistcodename'] ? {
        'trusty' => 'release o=stable-trusty',
        'jessie' => 'release o=stable-jessie',
    }
    apt::pin { 'toolforge-mono-external-pinning':
        package  => '*mono* *cairo* *cecil*',
        pin      => $mono_pinning,
        priority => '1001',
    }
}
