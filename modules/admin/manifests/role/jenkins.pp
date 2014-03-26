class admin::role::jenkins {
    include admin::groups::misc
    realize Admin::Group[jenkins]
    realize Admin::Group[wikidev]

    include admin::users::dev
    realize Admin::User[demon]
    realize Admin::User[krinkle]
    realize Admin::User[dsc]
    realize Admin::User[mholmquist]
    realize Admin::User[hashar]

    admin::sudo{ 'hashar_root':
        user       => 'hashar',
        comment    => 'RT 401',
        privs      => ['ALL = NOPASSWD: ALL'],
    }
}
