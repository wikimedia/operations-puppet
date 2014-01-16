define admins::user($ensure='present') {
    create_resources('admins::account', $admins::users[$title], {
        ensure => $ensure,
    })
}
