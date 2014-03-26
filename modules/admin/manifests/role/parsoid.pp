class admin::role::parsoid {

    include admin::groups::misc
    realize Admin::Group[parsoid]
    realize Admin::Group[wikidev]

    include admin::users::dev
    realize Admin::User[gwicke]
    realize Admin::User[ssastry] # RT 5512

    admin::sudo{ 'gwicke_as_parsoid':
        user       => 'gwicke',
        comment    => 'RT 5934',
        privs      => ['ALL = (parsoid) NOPASSWD: ALL'],
    }
}
