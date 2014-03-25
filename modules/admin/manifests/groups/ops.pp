class admin::groups::ops {
    @admin::group { 'ops':
               gid => 511,
        sudo_privs => ['ALL=(ALL) NOPASSWD: ALL'], #all key based
           members => [
                        'rush',
                        'akosiaris',
                        'andrewb',
                        'ariel',
                        'bblack',
                        'catrope',
                        'cmjohnson',
                        'dzahn',
                        'faidon',
                        'gage',
                        'jgreen',
                        'laner',
                        'marc',
                        'mark',
                        'midom',
                        'otto',
                        'robh',
                    ]
    }
}
