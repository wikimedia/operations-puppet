# XXX: this is just for illustrative purposes.

class admins::data {
    $gids = {
        'wikidev'     => 500,
        'roots'       => 501,
        'mortals'     => 502,
        'restricted'  => 503,
        'labs'        => 504,
        'jenkins'     => 505,
        'dctech'      => 506,
        'globaldev'   => 507,
        'privatedata' => 508,
        'fr-tech'     => 509,
        'parsoid'     => 510,
        'search'      => 538,
        'l10nupdate'  => 10002, # XXX: move to another module
        'file_mover'  => 30001, # XXX: used by fundraising, move to another module
        'revoked'     => 600,
    }

    $members = {
        'wikidev' => [],
        'ops' => [
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
            'lcarr',
            'marc',
            'mark',
            'midom',
            'ori',
            'otto',
            'robh',
            'springle',
            'tstarling',
        ],
        'mortals' => [
            'aaron',
            'abaso',
            'andrew',
            'anomie',
            'aude', # RT 6460
            'awight',
            'awjrichards',
            'bd808',
            'brion', # RT 4798
            'bsitu',
            'cmcmahon',
            'csteipp',
            'demon',
            'ebernhardson', # RT 5717
            'gdubuc', # RT 6619
            'gjg',
            'gwicke',
            'halfak',
            'hashar',
            'kaldari',
            'kartik', # RT 6533
            'khorn',
            'krinkle',
            'manybubbles', # RT 5691
            'maxsem',
            'mflaschen',
            'mholmquist',
            'mhoover',
            'milimetric', # RT 5982
            'mlitn',
            'mwalker', # RT 4747
            'nikerabbit',
            'pgehres',
            'reedy',
            'rmoen',
            'robla',
            'spage',
            'ssastry', # RT 5512
            'sumanah', # RT 3752
            'tfinc', # RT 5485
            'yurik', # RT 4835, RT 5069
        ],
        'restricted' => [
            'avar',
            'dab',
            'dartar',
            'diederik',
            'erik',
            'ezachte',
            'ironholds', # RT 5935
            'jamesofu',
            'khorn',
            'mgrover', # RT 4600
            'qchris', # RT 5403
            'rainman',
            'spetrea', # RT 5406
            'ssastry', # RT 5512
            'tnegrin', # RT 5391
            'tparscal',
        ],
        'labs' => [
            'mhoover',
        ],
        'jenkins' => [
            'demon',
            'hashar',
            'krinkle',
            'reedy',
            'mholmquist',
        ],
        'dctech'=> [
            'sbernardin',
        ],
        'globaldev' => [
            'erosen',
            'haithams',
            'handrade',
        ],
        'privatedata' => [
            'erosen',
            'haithams', # RT 3219
            'handrade', # RT 4726
            'ezachte',
            'milimetric',
            'diederik',
            'dartar',
            'spetrea',
            'yurik', # RT 4835
            'howief', # RT 3576
            'mgrover', # RT 4600
            'mwalker', # RT 5038
            'awight', # RT 5048
            'abaso', # RT 5446
            'qchris', # RT 5474
            'tnegrin', # RT 5391
            'nuria', # RT 6617
        ],
        'fr-tech' => [
            'awight',
            'khorn',
            'pgehres',
            'mwalker',
            'ssmith',
        ],
        'parsoid' => [
            'gwicke',
            'catrope',
            'ssastry',
        ],
        'revoked' => [
            'asher',
            'ashields',
            'austin',
            'bastique',
            'ben',
            'daniel',
            'dsc',
            'fvassard',
            'jeluf',
            'kate',
            'neilk', # RT 2345
            'nimishg',
            'olivneh', # renamed to 'ori'
            'pdhanda',
            'preilly',
            'py',
            'raindrift', # RT 3088
            'ram',
            'rcole',
            'sara',
            'zak',
        ],
    }

    $sudo = {
        '%ops' => {
            privileges => [ 'ALL=(ALL) NOPASSWD: ALL' ],
        },
        '%parsoid' => {
            privileges => [ 'ALL=(parsoid) NOPASSWD: ALL' ],
        },
    }

    $users = {
        'faidon' => {
            realname => 'Faidon Liambotis',
            uid      => 592,
            gid      => 'wikidev',
            groups   => [ 'ops' ],
            ssh      => [
                    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/m5mZhy2bpvmBNzaLLhlqhjLuuGd5vNGgAtRKmvfa+nbHi7upm8d/e1RoSGVueXSVdjcVYfqqfNnJQ9GIC9flhgVhTwz1zezCEWREqMQ3XuauqAr+Tb/031BtgLCHfTmUjdsDKTigwTMPOnRG+DNo+ZHyxfpTCP5Oy6TChcK6+Om247eiXEhHZNL8Sk0idSy2mSJxavzs25F/lsGjsl4YyVV3jNqgVqoz3Evl1VO0E3xlbOOeWeJnROq+g2JJqZfoCtdAYidtg8oJ6yBKJHoxynqI6EhBJtnwulIXGTZmdY2cMJwT2YpkqljQFBwtWIy/T+WNkZnLuJXT4DRlBb1F faidon@wmf',
                ],
        },
        # XXX
    }
}
