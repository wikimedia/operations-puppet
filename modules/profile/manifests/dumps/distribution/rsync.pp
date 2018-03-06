# Set up rsync server and base config
class profile::dumps::distribution:rsync(
    $rsyncer_settings = hiera('profile::dumps::rsyncer'),
) {
    $user = $rsyncer_settings['dumps_user']
    $group = $rsyncer_settings['dumps_group']
    $deploygroup = $rsyncer_settings['dumps_deploygroup']
    $mntpoint = $rsyncer_settings['dumps_mntpoint']

    class {'::dumps::rsync::common':
        user  => $user,
        group => $group,
    }

    class {'::dumps::rsync::default':}

    class {'::vm::higher_min_free_kbytes':}

}
