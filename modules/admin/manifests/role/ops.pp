class admin::role::ops {
    include admin::groups::ops
    realize Admin::Group[ops]

    include admin::groups::misc
    realize Admin::Group[wikidev]

    include admin::users::ops
    Admin::User <| |>
}
