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
        'brion' => {
            realname => 'Brion Vibber',
            uid      => 500,
            gid      => 'wikidev',
        },
        'tstarling' => {
            realname => 'Tim Starling',
            uid      => 501,
            gid      => 'wikidev',
        },
        'erik' => {
            realname => 'Erik Moeller',
            uid      => 503,
            gid      => 'wikidev',
        },
        'jeluf' => {
            realname => 'Jens Frank',
            uid      => 518,
            gid      => 'wikidev',
        },
        'hashar' => {
            realname => 'Antoine Musso',
            uid      => 519,
            gid      => 'wikidev',
        },
        'ezachte' => {
            realname => 'Erik Zachte',
            uid      => 523,
            gid      => 'wikidev',
        },
        'kate' => {
            realname => 'River Tarnell',
            uid      => 524,
            gid      => 'wikidev',
        },
        'midom' => {
            realname => 'Domas Mituzas',
            uid      => 527,
            gid      => 'wikidev',
        },
        'mark' => {
            realname => 'Mark Bergsma',
            uid      => 531,
            gid      => 'wikidev',
        },
        'avar' => {
            realname => 'Avar',
            uid      => 534,
            gid      => 'wikidev',
        },
        'dab' => {
            realname => 'Daniel Bauer',
            uid      => 536,
            gid      => 536,
        },
        'rainman' => {
            realname => 'Robert Stojnic',
            uid      => 538,
            gid      => 538,
        },
        'bastique' => {
            realname => 'Cary Bass',
            uid      => 539,
            gid      => 'wikidev',
        },
        'andrew' => {
            realname => 'Andrew Garrett',
            uid      => 540,
            gid      => 'wikidev',
        },
        'tparscal' => {
            realname => 'Trevor Parscal',
            uid      => 541,
            gid      => 'wikidev',
        },
        'fvassard' => {
            realname => 'Fred Vassard',
            uid      => 542,
            gid      => 'wikidev',
        },
        'ariel' => {
            realname => 'Ariel T. Glenn',
            uid      => 543,
            gid      => 'wikidev',
        },
        'aaron' => {
            realname => 'Aaron Schulz',
            uid      => 544,
            gid      => 'wikidev',
        },
        'daniel' => {
            realname => 'Daniel Kinzler',
            uid      => 545,
            gid      => 'wikidev',
        },
        'catrope' => {
            realname => 'Roan Kattouw',
            uid      => 546,
            gid      => 'wikidev',
        },
        'pdhanda' => {
            realname => 'Priyanka Dhanda',
            uid      => 547,
            gid      => 'wikidev',
        },
        'austin' => {
            realname => 'Austin Hair',
            uid      => 548,
            gid      => 'wikidev',
        },
        'nimishg' => {
            realname => 'Nimish Gautam',
            uid      => 549,
            gid      => 'wikidev',
        },
        'zak' => {
            realname => 'Zak Greant',
            uid      => 551,
            gid      => 'wikidev',
        },
        'awjrichards' => {
            realname => 'Richards',
            uid      => 552,
            gid      => 'wikidev',
        },
        'laner' => {
            realname => 'Ryan Lane',
            uid      => 553,
            gid      => 'wikidev',
        },
        'rcole' => {
            realname => 'Richard Cole',
            uid      => 554,
            gid      => 'wikidev',
        },
        'robla' => {
            realname => 'Rob Lanphier',
            uid      => 556,
            gid      => 'wikidev',
        },
        'reedy' => {
            realname => 'Sam Reed',
            uid      => 558,
            gid      => 'wikidev',
        },
        'py' => {
            realname => 'Peter Youngmeister',
            uid      => 559,
            gid      => 'wikidev',
        },
        'neilk' => {
            realname => 'Neil Kandalgaonkar',
            uid      => 560,
            gid      => 'wikidev',
        },
        'asher' => {
            realname => 'Asher Feldman',
            uid      => 561,
            gid      => 'wikidev',
        },
        'halfak' => {
            realname => 'Aaron Halfaker',
            uid      => 564,
            gid      => 'wikidev',
        },
        'diederik' => {
            realname => 'Diederik van Liere',
            uid      => 565,
            gid      => 'wikidev',
        },
        'ashields' => {
            realname => 'Andrew Shields',
            uid      => 569,
            gid      => 'wikidev',
        },
        'preilly' => {
            realname => 'Patrick Reilly',
            uid      => 570,
            gid      => 'wikidev',
        },
        'jgreen' => {
            realname => 'Jeff Green',
            uid      => 571,
            gid      => 'wikidev',
        },
        'khorn' => {
            realname => 'Katie Horn',
            uid      => 572,
            gid      => 'wikidev',
        },
        'kaldari' => {
            realname => 'Ryan Kaldari',
            uid      => 573,
            gid      => 'wikidev',
        },
        'dzahn' => {
            realname => 'Daniel Zahn',
            uid      => 575,
            gid      => 'wikidev',
        },
        'ben' => {
            realname => 'Ben Hartshorne',
            uid      => 576,
            gid      => 'wikidev',
        },
        'sumanah' => {
            realname => 'Sumana Harihareswara',
            uid      => 578,
            gid      => 'wikidev',
        },
        'cmjohnson' => {
            realname => 'Chris Johnson',
            uid      => 579,
            gid      => 'wikidev',
        },
        'jamesofur' => {
            realname => 'James Alexander',
            uid      => 580,
            gid      => 'wikidev',
        },
        'pgehres' => {
            realname => 'Peter Gehres',
            uid      => 581,
            gid      => 'wikidev',
        },
        'lcarr' => {
            realname => 'Leslie Carr',
            uid      => 582,
            gid      => 'wikidev',
        },
        'nikerabbit' => {
            realname => 'Niklas Laxström',
            uid      => 583,
            gid      => 'wikidev',
        },
        'sara' => {
            realname => 'Sara Smollett',
            uid      => 584,
            gid      => 'wikidev',
        },
        'dartar' => {
            realname => 'Dario Tarborelli',
            uid      => 585,
            gid      => 'wikidev',
        },
        'dsc' => {
            realname => 'David Schoonover',
            uid      => 588,
            gid      => 'wikidev',
        },
        'otto' => {
            realname => 'Andrew Otto',
            uid      => 589,
            gid      => 'wikidev',
        },
        'andrewb' => {
            realname => 'Andrew Bogott',
            uid      => 590,
            gid      => 'wikidev',
        },
        'faidon' => {
            realname => 'Faidon Liambotis',
            uid      => 592,
            gid      => 'wikidev',
            ssh_keys => [
                    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/m5mZhy2bpvmBNzaLLhlqhjLuuGd5vNGgAtRKmvfa+nbHi7upm8d/e1RoSGVueXSVdjcVYfqqfNnJQ9GIC9flhgVhTwz1zezCEWREqMQ3XuauqAr+Tb/031BtgLCHfTmUjdsDKTigwTMPOnRG+DNo+ZHyxfpTCP5Oy6TChcK6+Om247eiXEhHZNL8Sk0idSy2mSJxavzs25F/lsGjsl4YyVV3jNqgVqoz3Evl1VO0E3xlbOOeWeJnROq+g2JJqZfoCtdAYidtg8oJ6yBKJHoxynqI6EhBJtnwulIXGTZmdY2cMJwT2YpkqljQFBwtWIy/T+WNkZnLuJXT4DRlBb1F faidon@wmf',
                ],
        },
        'raindrift' => {
            realname => 'Ian Baker',
            uid      => 593,
            gid      => 'wikidev',
        },
        'bsitu' => {
            realname => 'Benny Situ',
            uid      => 595,
            gid      => 'wikidev',
        },
        'mlitn' => {
            realname => 'Matthias Mullie',
            uid      => 596,
            gid      => 'wikidev',
        },
        'maxsem' => {
            realname => 'Max Semenik',
            uid      => 597,
            gid      => 'wikidev',
        },
        'erosen' => {
            realname => 'Evan Rosen',
            uid      => 602,
            gid      => 'wikidev',
        },
        'olivneh' => {
            realname => 'Ori Livneh (disabled)',
            uid      => 604,
            gid      => 'wikidev',
        },
        'mwalker' => {
            realname => 'Matt Walker',
            uid      => 605,
            gid      => 'wikidev',
        },
        'haithams' => {
            realname => 'Haitham Shammaa',
            uid      => 606,
            gid      => 'wikidev',
        },
        'krinkle' => {
            realname => 'Timo Tijhof',
            uid      => 607,
            gid      => 'wikidev',
        },
        'spage' => {
            realname => 'S Page',
            uid      => 608,
            gid      => 'wikidev',
        },
        'csteipp' => {
            realname => 'Chris Steipp',
            uid      => 609,
            gid      => 'wikidev',
        },
        'dandreescu' => {
            realname => 'Dan Andreescu (disabled)',
            uid      => 610,
            gid      => 'wikidev',
        },
        'howief' => {
            realname => 'Howie Fung',
            uid      => 611,
            gid      => 'wikidev',
        },
        'spetrea' => {
            realname => 'Stefan Petrea',
            uid      => 612,
            gid      => 'wikidev',
        },
        'rmoen' => {
            realname => 'Rob Moen',
            uid      => 614,
            gid      => 'wikidev',
        },
        'awight' => {
            realname => 'Adam Wight',
            uid      => 616,
            gid      => 'wikidev',
        },
        'anomie' => {
            realname => 'Brad Jorsch',
            uid      => 617,
            gid      => 'wikidev',
        },
        'ironholds' => {
            realname => 'Oliver Keyes',
            uid      => 619,
            gid      => 'wikidev',
        },
        'gwicke' => {
            realname => 'Gabriel Wicke',
            uid      => 622,
            gid      => 'wikidev',
        },
        'sbernardin' => {
            realname => 'Steve Bernardin',
            uid      => 623,
            gid      => 'wikidev',
        },
        'mflaschen' => {
            realname => 'Matthew Flaschen',
            uid      => 625,
            gid      => 'wikidev',
        },
        'mholmquist' => {
            realname => 'Mark Holmquist',
            uid      => 626,
            gid      => 'wikidev',
        },
        'cmcmahon' => {
            realname => 'Chris McMahon',
            uid      => 627,
            gid      => 'wikidev',
        },
        'ram' => {
            realname => 'Munagala Ramanath',
            uid      => 628,
            gid      => 'wikidev',
        },
        'handrade' => {
            realname => 'Henrique Andrade',
            uid      => 633,
            gid      => 'wikidev',
        },
        'marc' => {
            realname => 'Marc-Andre Pelletier',
            uid      => 634,
            gid      => 'wikidev',
        },
        'bblack' => {
            realname => 'Brandon Black',
            uid      => 635,
            gid      => 'wikidev',
        },
        'yurik' => {
            realname => 'Yuri Astrakhan',
            uid      => 636,
            gid      => 'wikidev',
        },
        'mgrover' => {
            realname => 'Michelle Grover',
            uid      => 637,
            gid      => 'wikidev',
        },
        'abaso' => {
            realname => 'Adam Baso',
            uid      => 639,
            gid      => 'wikidev',
        },
        'milimetric' => {
            realname => 'Dan Andreescu',
            uid      => 640,
            gid      => 'wikidev',
        },
        'ebernhardson' => {
            realname => 'Erik Bernhardson',
            uid      => 641,
            gid      => 'wikidev',
        },
        'akosiaris' => {
            realname => 'Alexandros Kosiaris',
            uid      => 642,
            gid      => 'wikidev',
        },
        'manybubbles' => {
            realname => 'Nik Everett',
            uid      => 644,
            gid      => 'wikidev',
        },
        'springle' => {
            realname => 'Sean Pringle',
            uid      => 645,
            gid      => 'wikidev',
        },
        'qchris' => {
            realname => 'Christian Aistleitner',
            uid      => 646,
            gid      => 'wikidev',
        },
        'tnegrin' => {
            realname => 'Toby Negrin',
            uid      => 647,
            gid      => 'wikidev',
        },
        'ssastry' => {
            realname => 'Subramanya Sastry',
            uid      => 648,
            gid      => 'wikidev',
        },
        'bd808' => {
            realname => 'Bryan Davis',
            uid      => 652,
            gid      => 'wikidev',
        },
        'ori' => {
            realname => 'Ori Livneh',
            uid      => 654,
            gid      => 'wikidev',
        },
        'gjg' => {
            realname => 'Greg Grossmeier',
            uid      => 655,
            gid      => 'wikidev',
        },
        'mhoover' => {
            realname => 'Mike Hoover',
            uid      => 656,
            gid      => 'wikidev',
        },
        'ssmith' => {
            realname => 'Sherah Smith',
            uid      => 658,
            gid      => 'wikidev',
        },
        'gdubuc' => {
            realname => 'Gilles Dubuc',
            uid      => 659,
            gid      => 'wikidev',
        },
        'demon' => {
            realname => 'Chad Horohoe',
            uid      => 1145,
            gid      => 'wikidev',
        },
        'aude' => {
            realname => 'Katie Filbert',
            uid      => 1185,
            gid      => 'wikidev',
        },
        'tfinc' => {
            realname => 'Tomasz Finc',
            uid      => 2006,
            gid      => 'wikidev',
        },
        'robh' => {
            realname => 'Rob Halsell',
            uid      => 2007,
            gid      => 'wikidev',
        },
        'kartik' => {
            realname => 'Kartik Mistry',
            uid      => 3033,
            gid      => 'wikidev',
        },
        'gage' => {
            realname => 'Jeff Gage',
            uid      => 4177,
            gid      => 'wikidev',
        },
        'nuria' => {
            realname => 'Nuria Ruiz',
            uid      => 4193,
            gid      => 'wikidev',
        },
    }
}
