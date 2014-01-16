define admins::group(
  $ensure='present',
) {
    admins::user { $admins::members[$title]:
        ensure => $ensure,
    }

    # realize Group, plus assign a gid from our admins map
    Group <| title == $title |> {
        gid    => $admins::gids[$title],
    }

    $sudo_group = "%${title}"
    if has_key($admins::sudo, $sudo_group) {
        create_resources(sudo, $admins::sudo[$sudo_group], {
            ensure => $ensure,
        })
    }
}
