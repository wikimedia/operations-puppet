class admin::role::ops {
    include admin::groups::ops
    realize Admin::Group[ops]

    include admin::users::ops
    Admin::User <| |>
}
