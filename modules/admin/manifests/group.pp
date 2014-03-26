define admin::group(
  $ensure='present',
) {

    include admin::data
    $members = $admin::data::members
    admin::account{ $members[$title]: ensure => $ensure }

    #create_resources(admin::user, $members[$title])

    @group { $name:
        ensure    => $ensure,
        name      => $name,
        allowdupe => false,
    }

    # realize Group, plus assign a gid from our admin map
    Group <| title == $name |> {
        gid    => $admin::data::gids[$name],
    }

    if has_key($admin::data::sudo, $sudo_group) {
        $param = {
            "${sudo_group}" => $admin::data::sudo[$sudo_group],
        }
        create_resources('admin::sudo', $param, {
            ensure => $ensure,
        })
    }
}
