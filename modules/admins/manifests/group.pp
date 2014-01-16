define admins::group(
  $ensure='present',
) {
    admins::user { $admins::data::members[$title]:
        ensure => $ensure,
    }

    @group { $title:
        ensure    => $ensure,
        name      => $title,
        allowdupe => false,
    }

    # realize Group, plus assign a gid from our admins map
    Group <| title == $title |> {
        gid    => $admins::data::gids[$title],
    }

    $sudo_group = "%${title}"
    if has_key($admins::data::sudo, $sudo_group) {
        $param = {
            "${sudo_group}" => $admins::data::sudo[$sudo_group],
        }
        create_resources('admins::sudo', $param, {
            ensure => $ensure,
        })
    }
}
