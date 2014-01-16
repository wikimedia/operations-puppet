define admins::user($ensure='present') {
    if !has_key($admins::data::users, $title) {
        fail("User ${title} is not defined")
    }

    $param = {
        "${title}" => $admins::data::users[$title],
    }

    create_resources('admins::account', $param, {
        ensure => $ensure,
    })
}
