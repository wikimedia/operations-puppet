#PLEASE DO NOT ADD NEW CONFIGURATION HERE

#SEE: http://git.wikimedia.org/blob/operations%2Fpuppet.git/65d82b3f8d06bd8087e5f083e7ccf75612748591/modules%2Fadmin%2FREADME

define unixaccount($username, $uid, $gid, $enabled=true, $shell='/bin/bash') {
    if defined(Class['nfs::home']) {
        $manage_home = false
    } else {
        $manage_home = true
    }

    user { $username:
        name       => $username,
        uid        => $uid,
        gid        => $gid,
        comment    => $title,
        shell      => $shell,
        ensure     => $enabled ? {
                    false   => 'absent',
                    default => 'present',
                },
        managehome => $manage_home,
        allowdupe  => false,
        require    => Group[$gid],
    }
}

define account_ssh_key($user, $type, $key, $enabled=true) {
    ssh_authorized_key { $title:
        user => $user,
        type => $type,
        key  => $key,
    }
}

class groups {

    class wikidev {
        group { 'wikidevgroup':
            ensure    => 'present',
            name      => 'wikidev',
            gid       => '500',
            alias     => '500',
            allowdupe => false,
        }
    }

    class l10nupdate {
        group { 'l10nupdate':
            ensure    => 'present',
            name      => 'l10nupdate',
            gid       => '10002',
            alias     => '10002',
            allowdupe => false,
        }
    }
}

class baseaccount {
    $enabled = true

        if !defined(Class['nfs::home']) {
                $manage_home = true
        }

    ssh_authorized_key {
        ensure => $enabled ? {
            false   => 'absent',
            default => 'present',
        }
    }
}

class accounts {
    class dr0ptp4kt inherits baseaccount {
        $username = 'dr0ptp4kt'
        $realname = 'Adam Baso'
        $uid      = '2962'
        $enabled  = true

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $enabled == true and $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'abaso@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDoKHi5isY9FixH31qz/81V7fOHsorLZI/NLKr9Z6Xawl2a2Ih0ZV/pJtD+BTu1ufK2QOdgobeRSrnybzf2/1aCqi3Z9H2XxJhMCfnLb/9AIcKJ9tN63T4nRnjLoPsmRgDQrOSIqY5NfLKzXBsQOqc3chZ5SaDf8f09OdBk+Obn5vhr6yWh4GhrfTzoZUfp6+JRiueZZYuGMIKdBAH82s9TyuhuGWvHJmO9WC1MJOV/3hIcim+X0xR+BNLEU/Uj4OPEXC0/EiXh2CJDLugBpLU28RF+Y16TRj/WmO2H0H6qVdmkiK7Ez9PCbsy4RFPq4hdART9QiQbQJzZzaYSAkSFV',
            }
        }
    }
    class aengels inherits baseaccount {
        $username = 'aengels'
        $realname = 'Andre Engels'
        $uid      = '587'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'aengels-rsa-key-20120215':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAIEA0kG/cHOrVwI14kI+xGgCZuidimqeXyh9vqoI2+EwGFu8o8bq3LmmqElEH7eHwpsOcaJlSMHC2ErbpXSPMiZoulgK6y/Ko9LKl4+0iRhPsQoyiOE/GHgbj025YTkjswNrYmQKwMTGaU+rnGFr82IFDMUoSFilUfcLMNPNo6ZATXs=',
            }
        }
    }
    class akosiaris inherits baseaccount {
        $username = 'akosiaris'
        $realname = 'Alexandros Kosiaris'
        $uid      = '3194'
        $enabled  = true

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $enabled == true and $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'akosiaris':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQC5IbCL8F2mKMLVL2yp3RP+1rs5v6R4iveIctHQA6kccymfoUa5y9FLT9+hx9ljXZDjrUN3rPeagbZDrGQj6UlI32YZVKRwAeaLkp85HpbzaL/2GKM9UlSq6Qztnuxp/cQGQtDrSK9rwPHk1kqxhXQDeu0+mzqgKMsTqZshG2pH+T27rpZMcUyyF0nX14yoqPHdxvetYfjhAo0WIuwmMcyDcv/Au4AaDgOoKqbYVNY/I5gRYxEotRuJeNg9NLFlUDmntA5mXthotK4uWimfDV8rI1695n2Idvf/iNtZiO6tnIFfs7nrv3C0vFZO+MMbrU0cz/Abbhq4zaQH7zqrP0GfaR4AJu+0SgOjDbmAhOgwgYOxpdhChIABjVJTP3chKgJ1y1JeUxyUaIayddp/Kyye7z0kFJw0+D8YROAPWkkJvpV6c0/U88LMjupG2kcVlxqPrUCJiL4e8viyZQxxJOJhS/Zdf56AO8Xh8WAxX0RZGLbA2GYln1euu+8zZuvfYuZa+IRPihlY9b1fkyYP4Y7WtVNkvtFuwqKzwI2qyRGPH9W6PI0yva1BYNf/jg2qdFiboH44cBzc0MoFoqjzD7RHJpPQJQFeEiZsrQjDvm18MMCONJTPHYJaA5YwxClRXH8scWx+H0MjDwC9KmhMPm+Rb0iXPh7KePhP1jAxN+Ldew==',
            }
        }
    }
    class anomie inherits baseaccount {
        $username = 'anomie'
        $realname = 'Brad Jorsch'
        $uid      = '2248'
        $enabled  = true

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $enabled == true and $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key {
            'bjorsch@wikimedia.org':
                ensure => 'absent',  # RT 6675
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDN9+TME+RHccrQypKmHUXdRdlr1TVQkhCEL6DJ4dMA2CaWIsqwIkfqIjzBzVoqLUxNVjVPh+AF8ahrtSnx5qQKrPn3icv1G1J1J9d4pagHuFcNQiYWS+7xk5P/rz8GETOcNkKOl4ZaCJf1KGvSiFv67mC8ERqY3238UIougv74uTm8u6KHfJQoNMMgtQ0YlGD5pD5HjKMMkzSG2Li6a9gR7nXQ4WKHDKyZW1lt8v4U4v79ZcTTIDk8jie6DNOgJLq6NHpurosfMjZI7d7wWi84mqQTazTpgNvRtaAyO3dg+iZYGrc0d642e+kBA6izMlz8QpWOiem5tR1PGN2itTrL',
            'bjorsch@wikimedia.org-2':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDGhaxbWveDEQ8giBB9YMMDJrNIYGS8Mlz03EYp74ZlQIzxyIaRpJiGjWPthDMioWINFrKbZSQVkYeDuiVNpvC1r14iry/LukVaCBSG/M8VCX1lEAGKTU6CwGiBWuoKrTeMkuPMnciasuSVsllHwluAUxiMw5Y3VcyFUcqI8FIKWZ8p2ovsTa/H1ADaGEGDD6FHp34Mu3k/xMbBZ+xZwOm8igLmEPbpOxJp6CcdBDK2Wqwp4mpMutgC5FxLBHCbmnXoMopnNc02xhDEi6IUqaV36nwxp7HaqqTYdSNJvLK1v4aIZCjlYGDQnVNiLK4lhkVWEzt35XwtBx13JBVgRAPv6EM+E2kiZviV6mPoRhPh6NJNPITLhC9lE4HBVrR25Cxe6l74w53enARfRythtDobD5EZE0CtvSZO/lRwYxwGqJd2EEE+JV+oAPhG8OxD8/IBTRAa7RsZcazluzs+M6h0iSSn5yz1D1H9J6IvXn+cRKg/6KWRCBehCKBGDtVhZMKpnvHMjDnK/GmXuD/V5mSqpZBoJjEYyuQi6pDj+9RRV2UeDcjSvU8bqYSZA3iiMUe7i9xMlN9st6NnKhqgZE5nAAF2MxFVdVzk5qk5e/VPBGM8Gw9PUT73m8RLBcRrmz32keLodrNtReo5768SIxS6GwVFWKtZRj9OTGCAJtN0yQ==',
            }
        }
    }
    class ashields inherits baseaccount {
        $username = 'ashields'
        $realname = 'Andrew Shields'
        $uid      = '569'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'ashields@local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAK2KMwlLfnArieW+Obz2e8V+7EgK+9tsX+eUOyRM6MDNHLlxnSLr9b0EVpS6dBtSaWt1LcfZtSBGAJvFBloROZBRDup+w+N+S27QTBdfxLtsnn4j16zHjaF/psameua+f9onQ8yK4lAPZfxpvY/6Fr0nt9skFTrC60V3kgdu18WJAAAAFQCHIvPCAB6Yg56Ha2ST7JT1iorrYQAAAIA4F6foFJB/PJ0wcySUVlXYI0KahgnZkQDnhsPebX/g2L/5/IVOCOxDH5EttA/w+IsmArO9Lrj7T8fAvs8bykaYOAhVNdP2kLq387T0LgBD8b9eexK0zdbhqoHDiyx2+Z80gaewKB/tOVzhE0QCN3Krr/ubdI2dM57fzjygDCp1GAAAAIEApbMDfrRfJZk0GL14ykKDj83bHUfjn/KrH+BULMctePytaIwfDjsKvy/ntj5mIglipX2Y2QL7H+/pEGkQbP8SdNNb8tEb2iDjq6jKKsKB5lFfUHX5rk9sUfViEOUNJ6JJCcSVMmj7hgVWKA2UdI0XQuaBoxEARVXtLnCp5LGcDbw=',
            }
        }
    }
    class austin inherits baseaccount {
        $username = 'austin'
        $realname = 'Austin Hair'
        $uid      = '548'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }

        if $enabled == true and $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'austin@constantinople.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA7DUF4Y5YNJpMJsjuaXkJ3yQlamEWIahV9l0ASjcQJOmokjg78bThu5jqOMK7+ekqmlPRrURP7qskh4fi3KMwltJpWDunKKRSd9iwpB/19MNhB7KOQITPz6XgaSTQYLhxjzVgZVrIbbAdw60uv/BIaYCEae0FPVz6qxEx6Y0Az4rZ9kA1NODXOM42Bimg/VWetXPaBEEhcm6D9v4Ut0ZF7dE7FG9vUVAAwNwLyJWWAozxm2tVyOKTtSVKkzv7w3X8tH6nXC8blO94h37oIX+c+AHzMoswsuj9avdMEEQ7/7KC8DQAbkyrZtItqWCiRnBXcHls1kABaGGdobpeeKt0Aw==',
            }
        }

    }
    class avar inherits baseaccount {
        $username = 'avar'
        $realname = 'Avar'
        $uid      = '534'

        unixaccount { 'Avar': username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'avar@Rancorwe':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAIEAvRT1SgaE5Us4I7yMEQEOhT/A4dkOnar036SLOfnYZ4pSez/rYFwO7IRkkvx5PbC/1BAUztJESW6iVVpbGoYyYCI6qoLJ5/Bk3RM7HCfEe/1HIIPsaKNOKkUL+M552DKNKynUAtoBOQk5c7oSrdKQu0LZqR0Vh3zLfhiOpidL6GU=',
            }
        }
    }

    class werdna inherits baseaccount {
        $username = 'werdna'
        $realname = 'Andrew Garrett'
        $uid      = '1039'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'andrew@voltaire':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA2Di7q/bc8OJ5HP4X2U19r8w/mIH6CDbZHkOv//5cNvE50udM7McwxRWSz5idIF2P2JyIU2tQhixM3vkWO2chcifIom60F2/vhKA+TuUr9l/IbnBv6CoCjeAxre0g3gVhcazHKKtjbpRMYRxMSrLs+SBzsQpTuB/MqJB/jy1rUDTLCwN8Dtz3nAR5vRtgM673kivDLvDsHrfgR1uScESawPe6c9iFLbnzptH4z86r98tj3s4U+3yVFaH9AG7YuovulyA6UEgXFL8swsrpp58s1+XIausfYAqjetIL0YS3vOwEeBw3Hg57c+bZ+dVODEV6wc+uOgtJFZs6zVHTFq5QoQ==',
            'andrew@zwinger':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAub5dQVlS7jvr0e3Df+5xDYXqEmROgb0vpEkjBlJwl7Ak+J7k5bfQL+YcHs0oPyjLEJ4ZxwN4JQw+AsB9Ifw2eFIFB+tlKmXj++d9I9PS/IY9hSKJHJ8Og8uqK4X08tqURnyfL8QvH3g+VuSuCTwQcyfIm0MVKpJ5/grpK+Zg3OYSU4JQJpa4TDcJpJrx+V6GCC5yNJshs2VSsXyUZYWHaa3r+MXHE+KRZDlVP1tkQhzdK1g+/vcp7s13+QaWioiUDbxkCN63pKxY5qQwOugT31EEacBOCgXsS2jY00mJ5KpVt0zJychsX7WTtNfk6Rt9u9xt/imghT80rCd97P63Hw==',
            }
        }
    }

    class ariel inherits baseaccount {
        $username = 'ariel'
        $realname = 'Ariel T. Glenn'
        $uid      = '543'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'ariel@ariel-desktop':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAwaTYlLZ90/oQ5tDYDkhI2mHa1L6Vh+zcekCt8D08N7/CrFI5sUVteTwMWw2ytQlWnyT3HVgHb4IS1EPjpjyuqseRcNW0HYsqBk3E36PCBQIqjLZ0nDAeHQtm6T6pXiKC5qUppghwrvDxVYFpF3lFzAzfYMrF7iugk0xRPTHZWm8df7dqIB/6FfbxSD95yQVAlJefxoFWbo3Yn+exEZQvWv6lQYXnjV5DSwMf8tPGDkc2DRjrnR52ZrXPRZFCqc9JGkA/l8QsYtjmqJdnOgq5raOb56aRulJYdP2j//B4lRJJlglMuj8dSZE/j04zub+P2QhfdqeEHmeaTUqbwcnZZw==',
            'ariel@zwinger.wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAAEBALcKsz9HL20xCAB/hWLUxE/26tdeZBQqLWlNiWUC1ilKlqYtHL99ffkrJIlwst+IN/1SOfBhs+5pZxfUyfIT/DaeVNVQXTBfyAXM8iImtY/RsQ9M+v0xhwTLVGs6jTXQX8bkOYAEIZd+x5eGFhSTyIVZmxkz38XpLsTuNyUjs2gFUWZtPGZIgOTToxnYK9mpvpM1gRsHuhLMYg9ZpgFpul41Im+znRcWnrmW6uPAYebvO4V3uNwqdPBh50mrrqyakRj7QlCiFs88zufyj3BmC5mwTNlHClAbVyLyOBY6GCgfof5wFkbvAnYA0iglGZBnk5qIIuPdO+6vxRztUIY3gI8AAAAVAODnUYfx53vWxQVx1GHkzuwSP5JJAAABAEUZuasCiK2tMhQyDIJuad0F8H3aW1CrVtG3ZJuZXjLxpsXQsaOrG/DcFLxKxV4YheQSAVYc098IoQmAiTBc4W++b5lqgu1lmEMwMxQd+o+V8/1ywla61DA7feAAc1H5+eiKUWJDGs9J4HnUiAJc//B//rflE32po1S4Al+8q5GnngOqGEc66u203V/CCtkEbFCOqBXcj36nlTEtxbkbHe633z/TMM/bAwH3vNDo/9Ia/SdTTnQ3XaOD+y2PYF2ley6ImedGrGM71RU2zUv8tmQW8s7/5SygoAWGkljjk3IZy+nYRH232fcWumwORmGvpiq9pPPHhC6zYXjF/5thXRcAAAEAC4uOPvwmzpdwWjJ0QzbcPknWtdc9pvjWC2OWGoJP3VxQckZnWwBEIi9TjxeneX1xU1ZZKQ7s5xcIBWE1qn8P8gNgpqGLVK7rmErN9EYHGcxPR/n0SfujHVo7qEHB0tRhCtABFEpYczl/K/xIfZ7+bCQmvWKuyYETP5QTwbAD5efJh88/kfFKqtI1qhhAenfG3afATU0SHya31HYjrghXZBbA8YvAmX2DfBkP+WYllFaeUmUlvMpnW6wx2+SW0cbMik8CFJIjcMO3NAWppsR3mgSwSGvWorlH6Tskei7MaEUBaYJH01aZbkJOkigGVQhna3tQ2JeKhe37GjednwoBGQ==',
            }
        }
    }

    class bastique inherits baseaccount {
        $username = 'bastique'
        $realname = 'Cary Bass'
        $enabled  = false
        $uid      = '539'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'cbass@Cary-Bass':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA390DUZg46zDR+o7PdEMypqqtCzg6rOj+ZP2FXWi8pof3bsGJ0J/bhRqP5/CPwdoAKsqhfAumYj2RAu1m4ikaQ3Kx7bhyCTqYNYpiqvARd2FgACFLPPhht6cG9sgF3KeQk6I1B8/vfx/fjtANQSxT5oRMle+71n0TmRWptdEVflYOwtBA/huIcrqXWR6Fnb7S6HntsNlWboZq0vdget8eB8WhOIPffeX5kpE2AbmCk4RtxiWif5rFjWPtOHHiBugDGhP7y0ljzimeBCmVFcWQ9ySQcQQbBFYj4QLc8B1U357E6HYSL1xNyCgWzVdjpHUCaXBkk4xoziIRuLbugzfwhw==',
            }
        }
    }

    class bd808 inherits baseaccount {
        $username = 'bd808'
        $realname = 'Bryan Davis'
        $uid      = '3518'
        $enabled    = true

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $enabled == true and $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'bd808+cluster8@wmf-bd808-mbp01.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCdtHX29Vcd5n950X3H11kAbQdmKTCJvOOclRKkaXGofp6UuCzgbbdK4Lfvz3cZ2dH9Kvv6M+Yf2uzh6XN470XxXIP91IzA7lVcaMV0sjOuhZKSvqe0NlA4kN/uytHGcfmBxlYAM+b1RxtveXTle3vVWefo1SkQ4fHteA8U/WWXhQ11HnCGd/ZAuiPTf4Fyfe5HFY6y4ECj7zTBEX6I6m2vDyJB7vsthfsmjWbll5Nr+wpcEp2ILVYdp+N+BUhHLkH4C6pivdxpAZQMSpACPPI7Bs+2Fmr08aVnaYKSFC6eZAFogf2lQ3l1oUVBhJRO4OX++E3TNEHNmJ6FeHD4acFv',
            }
        }
    }

    class brion inherits baseaccount {
        $username = 'brion'
        $realname = 'Brion Vibber'
        $uid      = '500'
        $enabled  = true

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }

        if $enabled == true and $manage_home {
            ssh_authorized_key {
            'brion@Verda-Majo.local.':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAM1lLHYwJW5sCLFGF70Kg8c7/Azrnlep68ufEZUPGrJkMfUHog0zLDlwVKTm5iRozUxwAidKS4wexcdmvbrz2SG35wsqjmEbd+jc8nJ2RLIz9y8EfzPLD8d0RyMsGYyQAm2mdyeLjMXsvSs8vq5DyBtvn87EUiAZoElmPTHsXQirAAAAFQDpigMj47QooCg5ql3YwfNLbHYP8wAAAIBWOJEimpUdjQF6FFEotuJc9G4FRHGC6Wpakx12KthAvywmWOCR+BHPlBVeufocCzkRxteCZeMddDi8EimXJJeN8CitsmYZCFFZYIkY2nntxWJLAKRI7LgsB/jjyw45HGO0piim5Phb0pqPjtJ04vaEc2k0xQq8a50IV5aolloM6gAAAIA7LQ8WRvWhj4gBgaCiHDc5TkqJksYd/lY1/hLY2prMSngkn/DLi0bepKmgBRQKFxqEBDl8kPFoVN7kb6qflwD+MBZumyIJmcw3mjgyNdnD/mlgGluAMBdrTKu3BtExyCqZsRvdlDYNFo/Dc4HZ6RuX4HM8MUHvrqmdyvLKHEk+QQ==',
            'brion@zwinger.wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAJfPpdbExtg6TAGRhCIk0Q3hduv8O6YEPjhl1VnyH86rO8BBQyrT5+bsmcBP+jpNk8+/daN5C6vkPIEGSmBg9pbzAMcbemerZw+t7nFL7PCD9b+L7y1/UwqXwrqnnJYTnIqBb+oR95u1E+DEh/j6+N5VFuKmSRZ96K+g5OuDoAkrAAAAFQD0PDU8fmx7Km/7XvzaU1zHHGUSrwAAAIEAkfK8xRWF7OtdVc2+UqVyWf3pnAvGgpsPdoZvVu57O/YT1nbQLIBot6v/5GU+k1L16OlUYMmD5DYR67N7dqbY4tOer4591/qLFErMsb/o4n0/c1hquOZk4Kj53W8JD1eA+kQ+Cp84/oQ0p1+O1GgAzo0PqWOdKSu+WY4o3yDIrHwAAACAW8bxIKTVNZTReUWGHdvFrdDqDvLKkLTvntA64apMh8s0cG3L9PbaKwVibG+hORyiH2ETviy4x1NNKhniCigQFTKr6KhPv6+G/95s14tPo5CTFbrA7WKngbr1Y6qT4a4e5QhW0ciQQAW3cBraYIGGeERz+vAxnkadI1XhiBc+1yk=',
            'brion@smidge':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEArC590xpWpe26evaQ424SBC3AnfHy7yb5M84F/3Wa/Pwb2Uh1ujHYmVHHnYee0ChWfsNXc3lHDlH278v//hMDagxR/O2sCjCjq9loyQQnb/t+f2INvrtna/YPRNO8nxH7dMT1mi4+i0LFlIkxwjwvNWoqJpZQouwckXzV44Ssx61IWR7S1s6Q9jthUa4O9U8Ffc75IQ4NgsGMcZoKS7lpqn7xQoVcQQ+RsfNLcmekUZ4tSdh3qp8R//Me6dg0h62VWucvjey6uLie/TW9y2TgT2XRxxLGZKWyp0YqVzZF2r2AZLvB0yxlb30+/qxTKzs9g51dUg+d8M7w8gAURggjwQ==',
            'brion@Hawkeye.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDPe5ARdfajt7cDlcK6Fn3uFf5d5hvFdefqdr3L4Q2qeojQYioEvgcbZfVXRzpoSuPPx1cl/tDZCdfYityJiZWaE3T+gDZqYh/zO4M/JkiRp0vfnHKQeRbW7ledlitPKi9ZoEGE0e8FX17V9DNxnSolI3wBrEOOHxmBnnqS2Q04bM1/MRuMH/jxkcOWEp/SG5TOJtlSqKMAOrui7vU0gycQ9Kn6bwB0csuRA2IUwAnn07oVlCoBLR4nDTzj+iXF9j3aB2nyuZE0huXJM4ys3oL5CSDVTDow42vLyH4jwMlugxsgC2QBwUuCPLGz0uTVOvdFG5PstXBEWJnr6lL/0D13',
            'brion@stormcloud':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAmi7DfRt6vSuT7oQLE8kBjXN6tZvskked8ZHkAhwB80d6yuSa317XqMzYrxzU2SqDnprNqZZTdK0i2l7G+X8jLodTADrTvxX3oANQy9ConVkXFrd6+qfZxUs6y8rTMX/FPNxCCK/G7iQSg1GjMGzyIwdOwHPOaxx/ASJFKNbCbAhxaf/lRUdz/rirPm11KcS/h5qplA/G/Kbcgd7oopBBXnmmEPLEyVI0agIBNb8E4r7GNXikycJqPON2Wxp3id1Fs84ALacStTs49ZPtynUuRhprslhN3z6G6uliighcc0PzHMRSR/H8zjBREfqcfvAgdqSgn8DSqIv2bzWDjcNtOw==',
            }
        }
    }

    class cmjohnson inherits baseaccount {
        $username = 'cmjohnson'
        $realname = 'Chris Johnson'
        $uid      = '2399'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key {
            'chrisj@ubuntu':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDnDmdyh5Stw9bMTm7qL1kWuNpazc1m6HiaN0ZlaqwbUIhvtADWobHZcHvTHMwyauU/X6joE+a6pyvYgM2hr6+wRawjmgOuK8cak90weyp+i20HCiPb5GqOLE0uDmDizI8Hb50kxjiXLF6k+7cT7i0Lksa9EKhsYEwCjgnOiGor6wEvN1RlwRuwNBOZcI6OUvV39G/VP/pjpZBeUNoUZHWgpr9nbX+rlctjzK0s8sRbUamvCG3lyeB1pNIVCkY9YOwvf1D2UpRnhIm3XQspojphCFzC6HqRqZOyygweKc98fmvxkbkiyzh9XPtKyV5CtRS+9ECUmZjfmcWZpomCN2tp',
            'chrisj@chrisj-VPCEB23FM':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDP7wD7CRHLh4V9Sjn72a/eh3hTQhprQ3fPxUX+G7oCGuRXmWAwHcoB2Rm7vZxiAEa6hA151YOEorYN8e6bYP0eqcpEu9G9cbDirnaAhKHf+r+n9OgJmpA8hDQQ0H4MuWH9W6uQLEi1Xl9Z41/u/LlfrmD9F77ed2jXCYAYgVwuNuO5lnOevMxLWH+aCtfYdp/QtEA9a+o2j0Dc0JveqXNFlCdcacLAME2q7ZHnyRwFndMgTiljnOSb3SjV/1tkNtq3Dkhnp1T3LXgSIX7gtxbfVd2u5b8HoaQYmpXSlRhyL+ulVJDJAEFVA+tp5lbcGK4kglNnBNKrQO9Bng+FlKwR',
            'chrisj@chrisjohnson':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDRLeXOUkI5OZkubtTv8jVVq7itOUQ38usJdMap8zjSQw9g7kbLj66369NQrp4g8MRiD1WhDGkxL5IeU8leQcAhTYB0SmAr/JAK363a/bgcR3OJL3LZcoji6iIhhDukanXNwo19uotoqJVj+J/CdSWzIbYefihN/FGf6CW9bqHhrBKY0t8k2HaT7EXxvxx7NXlCUQCSKHlkfNyd+BT+nYQ+oQQxyxFHrvKPhs9TPy8U7eVKpU1d0DfVVlKKB65l0O2Ldny0K4i8NPv+CmwX1zJqRzqc0inqfT3Eatc6a47pqJq2tL8ah4hYyrtYh2swicY3JbOP8lVWvnV3PZ2/iRMN',
            'chrisj@chrisjohnson2':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDjVPy2od8cEq1waL62yVzYmppKJSg95xFecXKVUutsE8P9VcHEdGFIg+pZoOv9X9u1rV4zrjxFomLka4RD9fhV4be3r4aXIswQ08Y9fQhQ6ixs0Y0rNmfF0P/C1vxZgZ9gPp5nSIAfng+W+CU6Ecsf/0TUc136KnpliYBIOWUD0kcgTRd3cu24w+6JYHXelZXvMB7dImlb9ilkk3OehXfNuABZpBN0PHM4CDDiZeSO1G6OD38evfuigFBo1U5zezRuOdDh5tTWug3fkmGf9bBH5MKnnIEfrzsbzQomeB0fJs1LEweFlwPZAsjQ4o0riJEhLwWFUlE88ABGbPhwJ9/X',
            'cmjohnson@wmf-production':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC7y4rw4Np/Xy1MgQYx6dciv+vszegmZjZbh5p7PHdddLI+8wDM2Q7tz+ghm6PkKuUlcwK99fD2ixlb8FoBrznUABTEmaSMBdSIhXS2J81mJ5ycrCeb/+bG9YQ8e1sABjfFSWu07wqUgPZqx6roeduc1fkp9DvH8FasbFZcuPsgkvANwaWm+TTSY8Ik1h7l1bJHIp7iRuLRQ9fZjsZCHD4svfuU3YEyIHKPYmPQFgJn1wyYDKgIbfewcK/rFX43E9Kqd/SpKqapIex1fYWA0/MtbAzVLb3YdX/vWQP6lx4Kwzc6OPzib++RY6bR0zd14IdkGZ2wgwcqR/MRaafotARV',
            }
        }
    }

    class csteipp inherits baseaccount {
        $username = 'csteipp'
        $realname = 'Chris Steipp'
        $uid      = '2246'
        $enabled  = true

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'Chris Steipp':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDsUn5XTWrJ8ojk6O7kF7kdQS1RrKtjkaMk2QtsdYOOCPo3YbK+70Q3Dy6gVBNOhsRWHeCimzfH2Uv/pVb0wNkrwenmBeD7nQyNICudewEANcnt5YF2znlke3lsW6TGzKUzrXIncdhDh4LWjmpJR/+hnKyGz7uQKXm8xWw9LGk1PEpeHpt+0TH/bUWzWjpYXfbt5W4GbYPwnHo1Pn27pcGwqgsgb8whX9ufDjw5qyLPTVW3AqP4XPRXYDB5Ui7udQeuCk4Omou9CirtC36o4ih2NrZ4CsacHyIMJf09HZo6yLE9EeGM06SO7qYqjYwapKGv6csZGney84udKaCHcdm/'
            }
        }
    }

    class jamesofur inherits baseaccount {
        $username = 'jamesofur'
        $realname = 'James Alexander (former)'
        $uid      = '580'
        $enabled  = false
    }

    class jamesur inherits baseaccount {
        $username = 'jamesur'
        $realname = 'James Alexander'
        $uid      = '2054'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'jalexander@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAIBt7ePL3ps6MVHEAMGdNHVd/lO2L3Yc0szq/M5gSino+bNmn7yOmNMk7QxVHHwsPOBPbEuBhKEUj5LC/K5oxMT4jOW5lH/PTGntsHNK+42nLsrbkTV20MVZerf5JUw7y/IL12RYzrzk6/uvA5LqBLGucha2yi2llcrWCzbvlnxTUw==',
            'jalexander@wikimedia.org2':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC+bZ1KKVo3jL93NYN/9++YVvbJobz5onNLMhQz37Ec8UZnb+m22R16JN0Fl++HfHy19RkI2H9Ex1vg5mqQHD+8BGpbRfl5VEJSmXB1zcbr+yJgk/b3G51EDCulJuuqQpcieI2Z4D8ds4q8NVl3cI3kH3hbjrIT4bojWz+GB0WzG2aNdkgwMUZynvLjQb+VrxcTd6fnWQsjEIVdtXXsp1croF3+lDPwrC3DFq0svPsDLu8jaFPM45VQ5VdxVZNYBGBAy+IzMeLCnLph/lBW0vS9jhAR+r0QYzzNHOiEnOISnoiw8ECtwOTAQjTaGdkv3enFme9/KXbdk6YWByapygrL',
            }
        }
    }

    class pgehres inherits baseaccount {
        $username = 'pgehres'
        $realname = 'Peter Gehres'
        $uid      = '581'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'pgehres@wikimedia.org':
                ensure => 'absent',
                user => $username,
                type => 'ssh-rsa',
                key  => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC8+5CuJlnFqzlYcs8QRu42ur5Y+9yM5g+uQIDYX+3SRA1UzOOOmj/Tqv0pzGhmvK15/y+Vz5LwE927fcI9VwAxBpCgfcV97r68aDF3YD4Zqo8ksV51GhRwk2QPNlwvCtf7+BMCLFt+ymLpAIsq3L1YReovJgfkDHvOQrujXH7LGd6tEXaUksqyn9L7TTbFEyHUZxTkrV33OOlaSxIJM1EZu1fsVSL0LppmXaLH1bi4/gPSbw3A4l8EAttWAqkvK0zrty022wn/1JRa868/OD3WWCoDNp4SSH0DisURdPlT4Jc+q+P6+P/RqeWJAx5IqEQhVg2GxW6BMIKQP5VigS5j',
            }
        }
    }

    class dab inherits baseaccount {
        $username = 'dab'
        $realname = 'Daniel Bauer'
        $uid      = '536'
        $gid      = '536'  # group 'dab'
        $enabled  = false

        group { 'dab':
            ensure    => 'present',
            name      => $username,
            gid       => $gid,
            alias     => $gid,
            allowdupe => false,
        }

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'knoppix@DanielXX':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAIEA4Xz2/yn/LREJbem/0IFF8wdAhn8n/dahlqB94K5hLXDXqFyiSHI3UBqnGlO2vTiwP/zU0/6cqVFQb1dqhftYn/Fet0MuekZRog2wHTrOkPy63Ph6dqVl5IeIqkHu0tEGXehd/3cktJs0ZiDjR6HrThJxLfRXsSsFQgxrHcSXLeM=',
            }
        }
    }

    class daniel inherits baseaccount {
        $username = 'daniel'
        $realname = 'Daniel Kinzler'
        $uid      = '545'
        $enabled  = true

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'daniel.kinzler@wikimedia.de':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAIEAuH1eNAxPgzMG0GoCZBtNx/eTnneQRT0Z/IZvbj0uQusaNlSG7MlFrUEI/HWCwIcWZlAdMBCvp2Ywc7+flvgH+JuBzbjvXDhhkC9o0/9wxKEwGRnP8RDnNBlaouzk/ROP4m8L2FZahAahFzoqDqYxzBl7bQ/iw+N811rAo+R0AGU=',
            }
        }
    }

    class dsc inherits baseaccount {
        $username = 'dsc'
        $realname = 'David Schoonover'
        $enabled  = false
        $uid      = '588'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'dschoonover@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA90Dj4DCHCIIRQv4K3+s+HAZUWZXmmY6rEhgaClq7tWZ2cnwQrGZJbRlhgTjfykPkyI6l+hx1xqMDz4ORGzMf1y/Ee5tEa+Btca1kfvY/N8bma1c3xO40M06/AC+1jyRsvng6byoCpDzbN+TrLWhwkKZglACR9i0eqoa8eJ6Sv9L1hz6bqjDoS8DXEx1xJNT/It60wyB08OVN2s2WiM/Cr340j6AdkyoTx9O2oigiOdOqfTUVXpK87zU6Ph4PxbkDtpfmyPEwX1LPmuwAie6b3MW0/G48sIZpJG0847m4qEDE4k04/E6jDYFssGB1vWDTAA1O0L2rIcQ5K6d4bFkzgQ==',
            }
        }
    }

    class dzahn inherits baseaccount {
        $username = 'dzahn'
        $realname = 'Daniel Zahn'
        $uid      = '2075'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'dz@ubuntu':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDY3GzbCE2eOM7IxQClHag9FRVg0eryA6PVa7p80Yp4suPzW73KVv9BgbSDvkdGNv9NOsVqkZkp01oZe7+XVxh1jaxM60nkF02DGKI0jn2lbzzWR5YS6gabjjn9SaOnh0MAwC8Jpvdz/YKOyE9/PAIFXajNwTuE6alHU/nWnLHaR1FJQRlfZLDlP9deNRAPaXOyn/jbO+ODNQIFeKSV0TmvZAh994wUlLoDYa1UcuqTRc9tJBmpLALVPZs1U2FZvLr7fkuOnUhcOC/uqE/pDdalSy0k6bAh/pkILOMFzhCHtrsbUV0AT7cVBogE7qYRuTo3eBrpzj9Bbsi41Q4y29lridBoyBgEMH/fnEIMDivNLzec5nYLPJ/XIDSc0G2iFoWY/u7SaVT7A6rjlSuzS7owunNXEj1mhmNW7v/FIOqG2Zl3K7INBj8Y0rFL9GuwP5LIkZxlNZT7NEdUOA3i8L4sT3YJJgiaup4Ss66TpWCDQ/znZoz5Vi5ODhXjqMVVFbrHI/7eIYMChoR5HkcRdjaIShvFgSfWcKXlwHouIVUiXprnoZZGmAa9CTAx9GFrjgC7DixK654yx4Gb47q4dttSE2nZKY1njfDRHcbLRuZ1ESEpAcoxkos1agvShw5B4ysSYRcMHkF2yqi2srq7Us19JWCmLm2RW5z+4xPBAfEMcw=='
            }
        }
    }

    class swalling inherits baseaccount {
        $username = 'swalling'
        $realname = 'Steven Walling'
        $uid      = '2516'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'swalling@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDmsa2kRWHxgjNbw51CafupOENyZF6aTC7uuWeaPQZpVAK7epFoyjdajAnIBq9q81rJ6JUWwVNyiwsC4VuNlpk29v5y7PmsbLvQU0nXHQ0VEDeorGfSdbYrv5I1/JhHQCFIPIGdsoiamTlnM6jqlRFSnUaTVtpLnQVJAkjnh6xZxZNBPhkplHgj31/XOTw0KUVnrVhWLdkyYzgT4452/EF1arPaPWgh6SczGTOkNkK0kUlzXYTST/jdTX7NiYJ+N6via64Ccro1hu6w+gTc0WdA9gg1TaaASzKpQtutddo0xMInzp3EIs6gsfoICRgbYiO5NuHluFd73UBQ2FTmaw6T'
            }
        }
    }

    class jpostlethwaite inherits baseaccount {
        $username = 'jpostlethwaite'
        $realname = 'Jeremy Postlethwaite'
        $uid      = '577'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'jpostlethwaite@WMF299s-MacBook-Pro.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDnBJKG5HDdWCOK9Ow8xPZpjQCeFlkIY6nPKMIpcM47uJPfZC6V1OmRgbTpmcaC1QeMzkZEeP/JSInkgHcuGShaZRiGKd5dYVWVEl+SLuS1kru9VVbX1F8MTn9OFSuQRYVq8r9spvUDVWIJvkAsdq5WR2gJgrhhspGEXCIzP+Orcqboj71oNaq9TUUhhZS+ueY39Sx6h9nH6k180/BxIudmGS8TmUQXyI+x3NoGDXUoxWpug00vTZNdssKU0943c/8CsVtNNEbvCzGQ9+Hh8XlHrp70FJIfy3wQLNVIKF0EpZzhHLUTiul7zrmTc9nBMiN07gzWHVQlAeSjsZcvTD6z'
            }
        }
    }

    class sumanah inherits baseaccount {
        $username = 'sumanah'
        $realname = 'Sumana Harihareswara'
        $uid      = '578'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'sumanah@sumana-ThinkPad-X220':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDLxspOGfRjS0t6C7j2WVLFjxy5u0rdqt3gm8/RSZCkGGqpzdHNfRGIqWAd+BfKTAPwA1dk78p034bfAm6Rmyy8vsCX3+Rep9ZgwXuAguBZsMV91qumT4wG2gNMH1yuMFxL/TZzx7gZeb/Qb5VFpZ7qvmtWnwBqQBWoKg5qDGffwHJRS0CRxbrbB59mbJXKyEqij2FzFcTpLNIg+waBhAPIrjpzSBv5WHeGkLwx/1DS6McjuFifyNMl3FXLv2JBUYct0ja+N57aASXSHKBsQxdvMYM7FMgmB3+h/okX3NMrHcDLJs5kINepy4Mve7EcNZwUZb9m4f0zywFA16wzgukV'
            }
        }
    }

    class ebernhardson inherits baseaccount {
        $username = 'ebernhardson'
        $realname = 'Erik Bernhardson'
        $uid      = '3088'
        $enabled  = true

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

            if $enabled == true and $manage_home {
                ssh_authorized_key { require => Unixaccount[$realname]}

                ssh_authorized_key { 'ebernhardson@wikimedia.org':
                    ensure => 'present',
                    user   => $username,
                    type   => 'ssh-rsa',
                    key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDnafs6VPTCwrVEEqllEMpH6zhLreme1qGFuLxKD5uYQu2OJ01fhxICnswF7uuDrOSs5X9kTyj4zYjoGLHkEbucv3tBunEwYvzbrtRh+WxWkNjBNqhnUkM6T3IxOIpGlXwFxs6rD57i5ZtG2RPdRbOd+NYMjjkR/tELNSwuOfwi0vFeaumqhrbs5Q4XRqcdjPpMxE/BwqqAFA0SU/WeU5ewifF+FedAwYp5LRaeGmgWt0wuRnTjib8xxyyoH8ZJa79bYHK1CSWo4HU/EPsFdAgTWhrX59UQwOWTFOztQKU6zUc50bfh3cpv3wQ/4+VXFWG4J6XMdL4jLVxZwhCebYnf',
            }
        }
    }

    class erik inherits baseaccount {
        $username = 'erik'
        $realname = 'Erik Moeller'
        $uid      = '503'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'moeller@peace':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAK+lRTWsGdEVTUMpERPE2pDREkNPXbNhFaHx+LZdfzCusOD6DRqv1yposhhjkMH4a1WpLxw2PM6Ew+YE5D8bJ1UCPYDDt7sjLXkVF/OtynNZchl+Eo2haanZzYzaRh/2+aZNoXfJ5OrpBCYAh7vt9a/aHKB3rKxgAR81rdjZ78gVAAAAFQCLF+CasSOhQIK1li8z5LIlpeUj4QAAAIB/QzV7a9w8xSjJbpfiUgPNeGBFTuZuizKUoygNPEgoPcKlaBT/0WuHfwshk5I6UKFwT0zkf3Ph8xdnwR3C+diM5F8ecJxVDIJjnSmNbX8FLYxkCqiawQMtlICIp7t3yHCJ7ziwG4yb3ayp0h5hfJ381xVoYyZe5XfLHUPziF8PKwAAAIA8LQPhqnGLa7TFW0Oc3exIHbEKGdH0I0D9BpgRNmGH5eOfxhYqm/DTsM9tN40XT/MIKb2dJuwIRXluCs5I2zThblTfVJzba71+uI88ou0s0iglfF4X+KdDyV+6ZR2N2rLqxi0QIJkobg2JUjUSmgzad7TtSPa6cc66AdMGjbhMhQ==',
            'erik@zwinger.wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAIEA2FOxgqYXUNKz/wcmyMY+dJyH9zStGNd4vM/RGjo5M3AI7J1qZpzVgJjphtrH1O8K8eJw2LAxIuqWt2MnHUzjCvOIT9zrMbZzsCGE81po88RTtZBYW9321/KnFpnuTrfAtQagRyge7KX/8TrRa8iE0CTuRB03sIH1BtF4U0OSTmc=',
            'erik@deep_thought':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDYiVifze8jetMrDIeZd8NRMKYofzT8fval1kdjAE2/3lAPpewZw8UxCM8Voz7jlJ2/NnGntNt99uGEp+6Z6VmUu15NUyeWSTdfe6BEQtLqtWaZ2qqdhoIS1bwdOEwZhSPGrP2Hp5LE0WRhAaCtVXQsCsKEFLwBjyXHQi3d1tR+qxFouKm2Yhq4atFksGfaJGCcUZ9k3qHJPheOM/0lIaOMm8cBkfacDFb7cZPHoNx8JrUcmKTHeqV8mYeIQQ4lfbwFSYnVy6F43psXWLIOYoHXmneu1840Of8Nxqd02ExEqZKBpwTZa/qPiLnVbexuPYzD3RcUE3g0NtL1smYZo6pr',
            }
        }
    }

    class ezachte inherits baseaccount {
        $username = 'ezachte'
        $realname = 'Erik Zachte'
        $uid      = '523'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'rsa-key-20040727':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAIEA30NTewvOFOErJeFtgi+Bpf52+aGI3fmQtOgmsmBIIdnMXdJAdduKZU95OIvsCVCpGKdtT602Twp3R4tOoe001ObTDpF14i28zwYcXgk1VD+ErPpOqcO1S2Ojs1qAaOOGEMCo/yDYkfgT7qLiplX3q9JdVDLkSlVvm+NiWSmzqnU=',
            }
        }
    }

    class fvassard inherits baseaccount {
        $username = 'fvassard'
        $realname = 'Fred Vassard'
        $enabled  = false
        $uid      = '542'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled, shell => '/usr/bin/zsh' }

        if $enabled == true and $manage_home {
            ssh_authorized_key { 'fred@depthstar.polanet.net':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAudXr3BJ9jDtPIJhZhEjk9JLynjNR/jVknQvMpDWR5mwXJJ1aicsNthxP3tYWHDMSCQnQ6Jt6lYR0Ha/QWh9PANCeNc5TAAeXuE55Etbv34sCP5EkRAwRFkQrBasTT480fA5KRxQFsA8oterA8kI65+c6IlctCHpMaVyctZPIpjpZwZDfqxGn1k0pyVdHj/z7BtMZaviLsHYbBO/+/Z4zqYFqGSWBT3dpYZu69FqYzM0jLajqV+s+UjiMmyiEe93jFG2nN2HzqiSDpjAhk/kZBdZlPHtWZclsTJUDqI2xUrqElprr8FQEd37IMCXNLh7Qv7ZXLEjd8fx6NaalEU3F4Q==',
            }
        }
    }

    class gwicke inherits baseaccount {
        $username = 'gwicke'
        $realname = 'Gabriel Wicke'
        $uid      = '1239'
        $gid      = '500'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }

        if $enabled == true and $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'gabriel@tosh':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDSPEnznabK4A8LBxTt/z18gW9THN2QVmGuY+y6uvSsqM2cXrj0PCvN3+sDKqNrp7jvuu/3JRGl2UcYTT3uU2L+r4nYud7axhodwlCepEUZlVABu4n2BXaBAKb1vlAdOnGLZm88rviT08aJkmiQGlm4dV/u+kPVJIcN/1ewjynWVcH7suZtVD0I6GIvZUU8PthbktBFZ6lpC5b3TFv7IShY2/qmbVFXjrFrfDZ6fMecabx5OvpQK36teM3LD0DYfpE/o8JCsjEYmBNQAXvK4MBvyKnqPT9QL2lkVd7vLpfjtVPOFlaRRc6ku7nS2gRZSpGgE70pAmu4KxGrzQvhi7txECmVIcfvKG2474xwwTVLdqhqdEkhvdPPLRGCp5Ic3YY0w9DLx91rwLKh/7OdbxC5EKF+ZNaB4pnuq9vYuC6Vl89/g+Dw28OQyE6pEjltqybEA5T0sQPrNd5U9mEabRWhjX7hkXXDSmfRs0XZ6Yi6u7QZUO+0aqaoiHCaAygmyi94aiAXqxFaRu+2JceiTpRDOxeHU1KupbuIDPXK49zyi+QkfKNJ37GPqe5hRsw5cq0AA6+GchzpJr8p8XIstFv87eNB467NdQft8uVvMjL0fT6HZ9Gzkr/ThCZs34OnGDPLybkK3pwSuv8zRkggDK7yRB6bvDDYX4s7qoHOb1naLQ=='
            }
        }
    }

    class hashar inherits baseaccount {
        $username = 'hashar'
        $realname = 'Antoine Musso'
        $uid      = '1010'
        $gid      = '500'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key  {
            'hashar@bihash':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAIEAvt7LIRTvsztelZFaFB+3eovqapFo5Lur/SJoxcV+O5YxPAA6+BBXuhaORJIPgq022VcJAZagZ4CaOEDRVIMJnu3olP5DRwgjGbiLxtFaMglahp9aFUFDXQ8z7ChY3HE1YYPJVkSwchWBcELZEOoIm4423AleQb0ZOie24xH/l4M=',
            'hashar@zwinger.wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAIEAzNhpIeuPMLolSk17uv9edHPmPHrxSNEAT/TofxgFyDrebbiExixcT0+riF5kB1BKlpyIIpiIHA5FNgQI6v40QOJ8YA94n1KIxp9hXGNPBgEaoTs212LljrfH3Yx4/6FPGhiFCC29N5oHwwav1RGi6+YwaoW4lSDH+x6YVI21xQE=',
            }
        }
    }

    class hcatlin inherits baseaccount {
        $username = 'hcatlin'
        $realname = 'Hampton Catlin'
        $uid      = '550'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'hcatlin@greed.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAoET83J1YKyC8C0su4RfGVWz9Lx69dwSgPamrAGue/BvQ4W7IDvCQZPi8pKMZuhY4N7OkjjhTjV7JqMqqjKICCwFVHZQSuMbFKYbaMtuYGGno0kGVRpGd7n9x4bHAep5K6H/FUpedPPjuhfXmvl7EYRIYHJrayMS2P79o5GcFFwQ6rYuBvc/vAMkOp1NFjfOktPLUmaU4PMroeIPf1XJ+n2Wr5hFw7fehHcYF7VmJft6jhPN+DVHyziJPRWEhFe5axfkqEC6wIk2O/d7OqnPATlk+7+vEh69yOzZu8Jh/FrNn9HzGHH8ZzvuksUvVoRyw8qlhFRxJKLbl/IPPZ5v7Dw==',
            }
        }
    }

    class jdavis inherits baseaccount {
        $username = 'jdavis'
        $realname = 'Jon Davis'
        $uid      = '1004'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'jdavis@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAQEAliYsMiUqipe/HtqzehVebaH8/kVl6RddesJC8fy/jV4TTTFpp+Ow9zpwqgS4lVgeYmrHnp3iDraTiqLlTzoB9e3hXwatzysUASn6sgep5zSTIqC7pb5xYHi6dsI+47L72vFoGfZdugXUYXqgml5JIRk++CK2KaH6udsxev/vW7iJWLxoPbXA9/dsX32/JHnHcNKWkYSjOvl+kvDsLqgnBO+smrLqLey5h1T6BObo7sM6hUUe+COpzNyJC5stP/GMUaYohHu2u9lwcIUFDB/5Wn7aY2ZyNgeoiGrS2angNoI2kNMucHw0eAtIFpXVYuuz7+ijDdGICeh0auIRfOg54Q==',
            }
        }
    }

    class jeluf inherits baseaccount {
        $username = 'jeluf'
        $realname = 'Jens Frank'
        $uid      = '518'
        $gid      = '500'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'jf@htz1.mormo.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA6oJQl5pStZupvWuqliV4iyRwEO5XPOG5SWVdctyf/DJA6FnSB3MLqfui+NJFeShIbrAyVMeHPk009wC4SCUsuxJz52/YlfMXLRfmYMOy2QvsLVlXATzU2koCafyqdmPETWPazCAobNtgH1eTfhtewOqBaL63gulYZHIrgGjUxqv02JEdMsaLB9KcmKbtbwiUnilCAx1agsjXVkxrBD/Pl+wcMWgJklfxnt80czndvBPPzxPKQOkJGvuqNp39JqHoKVZtJ9wFhEXM5greAu4JXhz18OcGZFtXUlBaCvHsVIpWwkg0DHMqTbtEaxlWuJXj5whOgc2xwao4Dvu1p5h5eQ==',
            'jf@nx7400':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAIEAm0iSI9O2ThFVmGXGzdKCnhPHt/1+qWfanOu7gyhlTvNu4Mt7EtrjoiagsDkYSQMqkFion/u7l5r27nJ63elGfBuND1RrJEbgQqCjSZA2hFKRrwCD9N8pMiffxJiRB/tb3PTghdYCdzDrBYyHgi1WKtO/0eCsBpwD/zSwQobEHr8=',
            'jf@hpmini':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAMEAqilgQkGZLiuyqSt3nvPTb68otGHrwB7yPm5BI0TcHML2eMqOifGwSBBjuPbXiNFtenWG5uZtBHLhTJyLTTQ1sJx0nz0qdOc0hWQzGAv3AIQl5casuiD7UQd4xtmJ81ZBxcsDtlllDN+ceQhiitP2iR9gIlda6SpgIiNxK3CvbEGE7Ep/LdTeNrb6/j3NLjvQtHBMYt45jz0WcWBy0zF33fNZGX43ActpYvO79L7vULPQk+eFAPiCoPUhIzh0O6nB',
            'jf@mormo':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAP+T1xnSHS4r8qwJw4np5syradidl7RYfpz2ZTn1yDdaKdfV7J9uMGswhILdTCnH/2RawgH0Y+q0AYY41qBZ/GLYrTdOy9MS+coK4j71l7jDPxQob+IazGwSvo/7A2WzOH0F/oaGAqDg2m66QVvtofbfUgmxBzA8zHkvzYFsUUeRAAAAFQCSLmm2GvN4tlLOL8addUUo8MDOxQAAAIA0qVhPLKA8k4oEzM1DE8C36xIMs7DU7ymDW2pbjq2VU8RjpZjhCH5ewaVEnN7CMmsVLaUsC9rFCMiT0N7z02Y5Zup4gzGuoxgdD5DtLFPdRMyVMEmPrOJIrYWL7cnd+KCZ6xmLrj7TSjzgEr6lGVwmLprBtHrx3Nvwm2f81kqXeQAAAIBj/ZLel34m5FItEK5LZiY/Ljg87iMsZW/AKcl2abKmF9Tuoi8y76BS+3WtaMD0X1ic90oSc3EacLDyDpwE1XzWk9rO3FhHXnsVZFYQIdK7LINy8+yGrccGVMpIR9OUMFpMCPC+td6VrXfRM/5DX7NZXSBbzCHJ/Co9ztHS8FIH4Q==',
            'jeluf@zwinger':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBANooK6FcUTzatD5XDUFAN03FFvJ2mYkBy9vF/OtH/hnWxH43vtgtyf7N+/f2JEmRo3gcTEpfV4eIztE4gLNd2u6S5dSXuZDIy146AD3PHRwcYjEuEL/fNC0oKEIYOKYiLoQqpnB+/idQHP7uQaiGNHC6lhEy5oWpui+kTCZBTr9bAAAAFQDJ7lk/ddYc7Wo+/IhR0EOQ3mTpjQAAAIEAtagACraVrg8PtpbpK7tjNjqQkgK8IaQDjEMGbGyJdpASBZkyw+EZSLV/10pihQktIYcHJCmjEBOsFN9BEf0IlgoQkJO4IhhgoRXA8eZRRl106GpIv18QUmayjWNtvG321oibmSJdi4VwdfckH6x63bS5t3RQP2ExW/3KiBDa91cAAACAW2t7AgL3qI7NhXjIGeo4lPY45SVSy+KxHuyQKiGs7v753mtdrhSDD4xaawzQf53jOlYe1yBIlEbqICRJ8zhT+e5eS9ZiXWM+G0V5P6U1f6HeRDBLm1SPsvJUdYFPdoIlcg8e9ys5E3sHNy6xYF1zjzMe+EtCsiM1+mC5olBWl8I=',
            'jf@alster089.server4you.de':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAAEBAIWL+yGT24UBP1leJnF7hkaG/AyyUWKP0uCFX4tJNdIlKj3sLb4V7AEtiRaX+h93Df1L5SPOr96iN1TOd51+ny5K/D3iOse8ACQTa0Zigll/mo6S30ceixBk218ud/k0q/hAIvMnZj2AxPIX/jYV3Akjp1sPaT9/Ed06SHGyj9LfdOTK8YlrkH6eO3lUJ6DBU5Qg3KurUXGgnfFx75Ij7nr+C6tekgj7eF+stg87lSt2Q0gi4fu/jBMd3HQyPY3kFBRpe5Ey3RfGRwA0Zre1gvyByliFRSx+zuBHLph2djyXRgS0GeyR/txxKS4dcE/7Qk4dQed3m91VyRCikbs6M/sAAAAVANahyQS99I9cKiiLig3L907M06fjAAABACphqj549n+hJk+PQNY8wiYjxUsH0JMybiVPmihnSa7P9Eys7YCn3onT+Qs12POzvo69sCM20HSulZe5UJu3cLNxlwrphkg+Rmm6PBULNJYNFA1Va+aotEuk3yeXhJUFcFgKYax2QsMbTUXSvGjwICGH+5g5Mv+be4NMhDG1iFALpIprVxRY0dvbRnh5PlAozjfrDL08XnEZWneOPp5AQtZrkwLIynM//z7DRE2VKN2yoxGkqQO6fBRqp9Dn3kzxDf1A8DGmzahZl7h8YMHLgR8CjKYzd/GGeOL5VnQtDj+/wVeXvBm5HSbnoAJJ1jqahPcIzT1faHZKliANxOuhbOIAAAEAPaef9bwlLj+nNqHhc9uT9DHQABMzclB5TFjO9XO4Tm0kqjlp//itY2Jqz9lUnKty6uymvIioIuGgqsTeznAqIDSv+74h96jXAL5GveXtHHFK4ItLd1tadbfCpGN19s6ONDCng162XHHeCdQlB711Ua38Sn2FZOdNkIXiDby4FzXOdC1G0SYdBa5uPfgA7ljLojvYgH5gNSGJXGj2e///433FRM5N9tn9WzilIuEcWloNTkabgdIwc2PWWv/bA0mZOlV44AR1u29P39IklQrBTmBYxMRv/XyP8CpNHiD9wnUinO8b78mZiIp78Cxbo3cyIPIusRzc+m7A9cKR13EWOw==',
            }
        }
    }

    class jkrauska inherits baseaccount {
        $username = 'jkrauska'
        $realname = 'Joel Krauska'
        $uid      = '3874'
        $enabled  = true

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'jkrauska@wmf-2013-10':
                ensure  => 'present',
                user    => $username,
                type    => 'ssh-rsa',
                key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDqrv9BOJmXXCVP3QZfTJ9Nx6H0BVSxk8EM64g9p5/r1j365Doe/gZX5BATskGpV3LVUkzy91ZTSVP7j0TfPplj0iF025BFgDuHUVIy/Jac+qXryIHuH5BdeI9Gz10l+k0tVUFL/MzuOPR9M/jU/40KbdX1m4ezAfNXFmBXoXSpDwy8ft8xxYjFTFSuxvQMprC+je4N+0mtolb3PpmhQCQLB9Ekhjw9jZm1J5uPDqJyplOmFxC0i2dk7MNzQ5OT8Qmw7D50Jg500rQHLzzHeBhgxDQ6ZGpDWnRD93fdFaBCU+8VZIkOIumme6VGyhFWgj1UF30t9gV44qo5+SYff63n',
            }
        }
    }

    class kate inherits baseaccount {
        $username = 'kate'
        $realname = 'River Tarnell'
        $uid      = '524'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'kate@zwinger.wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAIEAtj96Qh5uNEsO6bgK+4Uj5dFQ6TAJlV3DAtB/FCNJNXmcV4eggnHxAcMVy7jbGYk/gRhPUNLBil59ZImrXcsRF7wP+/QYegeJQ5er/KqNKd4EtSnD7+mEaM90rSlm0suG93k5VDShMS/Yb74XWMEMwcFwrltaXve16P+9IpmTF2k=',
            'river@loreley':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAyszt9jTA88Dz4SjVVevwgCKHY1GfS5hla0XatqtAWNI+9O5eXasbybB7UfHo5Y6FB8Xu7Snu1NAj/xVGKLlQ69cNT6YMaj3TC1TLfhK2pmHxWHXDUqffU5ZOE/C4VSdING8FateJ5E7oOw9152UKNRoI12Fsu9yzzUZnKm0+43kFg/XfGioGqagm4jAUNhwylqRulRxFWCpZLjEjJOiRI+6pgVK8+wsq5kpuwVe36k0wmHEPWhbGabNY1Uw6dkVWIz3pI1PtaAmmb4FZ6KLYFh6kO4u3M+uhPfj94mtJb3Yr5jPkOb/9DKhCaZqYLVm3cs7pyQZtN3oRkitjzJC34Q==',
            }
        }
    }

    class krinkle inherits baseaccount {
        $username = 'krinkle'
        $realname = 'Timo Tijhof'
        $uid      = '2008'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'krinkle @ MacBook Pro, Mid-2011':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCm44jLSJBG8Qul5VNqrgvfUCjOACM0v1RzehkF7XMYRr+yBzBGJlRSHOs6/aUoBauJDPdM2VSb1LR3PCALwczYmA4Slnm/9rTfq0U/CAeFjHKBiQey4cntKFrYIUM0Qf+XsaDBQ2uK9C2GOw3Lo9RIYfq8Kz7keS+xtkk/6t1oypAcdG6Yt4Wi9z8Mgwmtd08mmT17yszxCf9emq5fo8otUC5nxWmXhAtnL5baaPDbi/0CpX6jm4BIAMm2jhGN6raYHLPIBhqk/uUa3k2EqkQ2gncY1judpyiUHmNB7dg9rDpbHF9pR+EvdE+tGRq8iirJzEbP4ErF0Vw461swIOB5',
            'krinkle @ MacBook Pro, Early-2013':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCrF4bY2ygHf70rOL3GGIWGurAXo2d5X07g+tzV5189kgKZs7Bz7l8R3NwzcCwuSIQqEWryjZN/lGa6lUhXaln16Ks/tn21eSfuI7TFjWZbLbQHJtf+QYhLA6dRBk87qfGW2z05w526OxRt7vPYo6uutdV+jt1wbpbMhA40cttsyDzWVqZ63TwielxaAZFABA1Tr5cWZbS0tz0Bmoiri8PPPDjeV9GCS6ApRZAeOJjtAeChu4RwEgTgHLkdACGJSg96G0BCT0Zd0RE7q357j8DlMbvw6a93DIrlhSrma0snHRHsi/fS7g8ULa/HmhweJocM+Rzd+URAaBSegNnlK/Hr',
            'krinkle @ krinkle-mbp003':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDftk5lndsGU70RXMNRlwGOT2qr/SSBQZog07fs4F5wBL5Uevf0bZkwFokissYOO02cgYy2q6SyN64SppfnWXjOJtX7uv1gasfxmufNMx1c/JIl3m+DUodkGzXsECM66ykHSmaIjLvdpsqS5FJ7FzmkAOQsQVvnzK+Ltb7XyOd1zf6y90SB6wo03RHalLoAXEP0GmKPyv0Tzvad3wjSxS6FxTAFji7wtdSdwOxd4xOQ606h4H7J/JRHWJrmGX9yn8BLPDXXB/3a1lBasaZXEyhd+a2RXvnMgPdqfRSpQRD6gRsaMoj6UiKG1+RoUlttXaKb4COI8llG+Q3tVzWm6IJr',
            }
        }
    }

    class lcarr inherits baseaccount {
        $username = 'lcarr'
        $realname = 'Leslie Carr'
        $uid      = '582'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'lcarr@Administrators-MacBook-Air.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC84js+fBru2S9Ty5loT2mWEoS2WcXDykJIUOKhT976JsANeP9sL0ox2/V+sAY4OPsAv1INxTbuPp5pl3B4yk8aSBZjZO5OwSZSfkICmVuqzKrzyZnvCwEr2dwZRW7Bf0sIlzMrg7gJKbKPn85zsZHSrRChouJxmeV6w5gIaA8asdsATNIgIU1BmRhbPQkMx5UkbqcbxK8mPpFPGZvEOBt7ZUxls/lT9CmUqInkrQ93usZYzo8RQk2KqTiv3gx/K4vkNSqaESQRvcg+JKrdN9QnB9IUzdeW0M16xTittN4ETWT2cAVZ1HNWmIvrxua5GDsrjI4psFEd8saWD8IJrfR3'
            }
        }
    }

    class mark inherits baseaccount {
        $username = 'mark'
        $realname = 'Mark Bergsma'
        $uid      = '531'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'Mark\'s main public key':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAIEAorTmQ0qlrxB3RL+GULLzex3k1Pg/c6tgLbKsl1A7Qo0B5XI4eNgfWwaAXUrKyQW3/9gwDH3YJ2eoOue0/BGhKX6voOTnNPeGE9ZbrufpPLT6DXDEbvpmXQd/qw8s0GxdftleHYl28av0nTZgKY+1/Oc+ZHNUN5YxmdGehWBvTXs=',
            }
        }
    }

    # disabled in favor of mattflaschen
    class mflaschen inherits baseaccount {
        $username = 'mflaschen'
        $realname = 'Matthew Flaschen (disabled)'
        $uid      = '625'
        $gid      = '500'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }
    }

    class mattflaschen inherits baseaccount {
        $username = 'mattflaschen'
        $realname = 'Matthew Flaschen'
        $uid      = '2662'
        $gid      = '500'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }

        if $enabled == true and $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'matthew@matthew-t520':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCermpz3BWUs5f0Cw4kD5+ngYPoE2/L+5Semq+6/LTboD2+mmXVF6vF0ODSt/Q9VVipzuiYVF0C+MQxMeSZDLKe/scBE3eIftLEQouHSiYq/YS19+ym4Q11rio3gmdqF4yS8Go4cg09FeSXmWy2F1H1apnWqZ9ISfZkeO/ScWQgcW9mY5GzbgZDEK+suXq8CjA3xU6HpPKcnWfRc+nG0ryLkO932Lh4L5Foev0buVEIIbVHcBZijsH2phdYkxAAytP4arRDdMxhpIHfaHdDYTu9OfJq8v+pAFigEj2jAnxCO2gtZRloEanzbTfgUgIhg9/vXcokaaDKtYZ3ezoMu5kJ'
            }
        }
    }

    class marktraceur  inherits baseaccount {
        $username = 'marktraceur'
        $realname = 'Mark Holmquist'
        $uid      = '2165'
        $gid      = '500'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }

        if $enabled == true and $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'administrator@WMF-ThinkPad-T420s':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDIAim5ZuEvBLdg2XabmNI5OHHQgBzi7HJ/AHZj0AeZCdfFg/wwB1TiarcDXRITf2ZVVn2caTuayKeA5dzDWOz1ouZycJ9L4rr2cgs3pz0TJfyP63usqevnwYpHFiFlYHqyR37+JaUrWknHTcslAxeiL3zAHrRLjqI2H8zyajWJ7AWdBLMSKKan9EoFpZ4oKzTYr7A4fGqj70yXw2c4R2qJNuXxmG4CbeVL1bjyTd+a8OT1Ixx3zuMtVCHL1QZDeCtBaMpF62cKKkUM88btoKh1ESSmzQTWu7ZJP/LA1nnTukRt4l4kWv33zt+iAa5KffxCppx77fRSbOlkyk0dqjrj'
            }
        }
    }

    class midom inherits baseaccount {
        $username = 'midom'
        $realname = 'Domas Mituzas'
        $uid      = '527'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'domas-wikimedia-200904':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAMOWDta08PH5U6hxvnHq7xT7lqIxWxMzP8wr20np4thUtlOqLsxmpJzHzdWJMlaEu0cLrJXxYq2Bm5jBpDb8Tmfo2TeIPgmFWmLgLpF9A4biXmMA6V9Dp5W/eyZgmlHjWlTLu6Y5WaK+Dr42rKzCMHeSxY8T/gvVIXvjZliNb7cvAAAAFQCLTv4hEekK6nLpqX2j/ac7Wj4eHQAAAIA3D0eTxabhSGD8a1IL/2i+Fb8YBLm6uJOXHmeIZNrpl78ml7lOcXxlQSlrQ8Gixc9eKz1a4vzuqKhxqdSFMFcA3wK0cGtXQuCtbiKGgFdKDsK1uBk/5d5mowqYNwZ62taA41NO4VGB7rYHga8Wg2ph5NZ5yuQgmOI8JqlbALH9oQAAAIAwDc1SQBOYJacBv/NeXhQIuDUO2x7gnqyr9Ud8hlnzy34GQldo+03AvL9vq2RSemCQBjnEqxXYUGhHqDshUvnHq5JxpeWjKRP+p5e0Xy7aepss3g9/IzUUrZ5m9HskczSfrlNBwDG5ybgaCJfyRX0MXnV1GCjaGlI2k0iymqGT+w==',
            'root@zwinger.wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAIEAomwyIAuPEDxmRFl3O11IH1yH+n7th+meS4dmB9OzKxh5Sg/aURrfFPUV/rSh+2QqfR7M7kB59ganKpc/7tCXW9mxoIr/c1kQ9jBzpyc7VUox/VTlSTZOFJA9sH9PUVIDINVNPyPFLNy9RtvWkSfHwffo6LHNju+us9PaUlmAaE0=',
            }

            ssh_authorized_key {
            'midom@flute.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAIRBscJUrqCDE7vK6YwlQdEXsGCBaW44dbPoG8QRtHU+bD8wZg/ViI5RX6hRCEJ7EWC8W+3xfocbo48UP94cAuvsQCquDvE+mwnVPihy3EtfbPFdPj0X8E/dGGD3YzRhq7ALMAnRPYlsgixd2YMDUrEYM7gsmeZbwfDrfgFYihTxAAAAFQCZv5NzAdGZSURVo/oAGr/27rxYswAAAIAlzeKOSWRBHV+01jPhESwbQpDhgVWd7KcowZ8JP/Ok2isperY9Yyi49udCy3PTNR63zyVqsrA8HHFbAmQvMXInAQxeqLxthWQL5MPYGKaZ7GeFiR5IhJjW1uK7flmdL8855BAbFbtdMGXgLVfH+Wa5o68e8hdNfP5jKkzTQRqkbAAAAIAhIqRn8sfBgd8vh0oZfzEJKaU8mOentbfN/tGXoFsPZF1kI4HTnYlktfzxo6wd9GGeXb8dJOa3r5OBvuw35zs/4ChPyONaMwyXCLRIDf6Iamhn6Vh81UFrGjuhng5awW5VLhQJcAr5zZ2tw0YWHQ8UExFnIYPnKuWnAs+qIFv0rA==',
            'root@flake.defau.lt':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAO+dLGWJQ2nu3jsNnRG2zsX7W9HK/XHOvWRRiezAf8e/d0n8vHOUL20MszrIRenM+F/WP4DPhIpDBpZ0DlIslY1IxX0hNeG5kgkq0dftRbO+qnf70nurWmggAlK5H+omCDgn9odR68f+ovfkcCz7edYz2Gq2vNHFpuK4wOJhQGZTAAAAFQCWwe8yW7iddPkBaViWTDpvLwBd4QAAAIEA5AYTGGVu8DAuL0OShVduean+IQd3j2xiU0HTCuALQZHTxMcN9BSxbgYY7Moh1TRAKpNwQUvtw6RVS2k58s69RAj8URpFzMSmnrgbTZt6CZ3AuRrnlz74S8FLTwDWMeHDyg5ey5ezOcQn0o34wuK3H0EFtkshykKQA53nd6aFmfYAAACAax/cZBm/Sjrb2+c3HE6WKfVSSi0dLLe/D1LidksSYEv/Kfcgx+/6ze7o+yHT3n+5cW813/2Iaa18cYD591o9tD6NM+WI/WtWrJIx/4sIwudow90N6P1JMkf+gr8hnIszaw52Zf0Xw5C7tLSkR6gMcI4WgwTQakQkram1DaJEIPk=',
            'midom@flare.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAvIaIOXvgvLTMPmSIEg/ebFWQtwj9x8KGs4148oj/ytyhwtcBcx1qT+dy03YyZebxt1snVUr/o/xYnzQNksYJug61dmGZLmeG7ktTVkLeUJqoLDmgP450vR/Vlug+YX63kGCKZIaCO47AzINfSSBfaXJq+GF8OBWEThfxq8V5GoOp2BMqf7e3LPIQOe/p7/Yr0yGAjFXZ5ju+KLs3JFP5wDVKSKNjjs+x8a74DYyUYiKeFox549e/iOXq8cLSfGyLQ7asYRKS0+UjPLO5Pi3iW5bGLMibiSNui+sWLL8meEPVr7DtqtZ2/XptzDCb9KUaxldRtYNoYczls1dR0fXjmw==',
            }
        }
    }

    class nikerabbit inherits baseaccount {
        $username = 'nikerabbit'
        $realname = 'Niklas Laxström'
        $uid      = '1008'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'jadekukka':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAgEAz5I9ctvMwZwehidz3oen7Teoj3pWi6M7+q0PnjXCWy6JuqkIv5vFtmi8NvCDSTCEaAdNdr7WPQHpGTSqUkbWsz0sswPlODZLDM97x9fzC8z4YhckJt9nlhGCYYqUi9hbchxTOGX2LL18/9IeU7yA5nb8qd3PPzhzjzgJkSjTgMnU5Ni+OBY3WiNJ4FFwYyitokYPVIF9ZFKkUWwuM0bSiNUjbNIUb4834i/tJ3g2plxX+9+7d5b6wFSWu7+e8wgN4avaTC46B3zKcYmfDUA2ebiZuhwUU2NdsP/z0Q3rOZ3LxRmVkOJFbK9vgmkQtTzSkhG3ZEgUiHc2QCjgccjkv+KFayn26WujtbmZZoIELC7/46lgwWGEZtb0QUbo2rY8yHaeetoVuVzZGtCrr0tEBx0w2AH9BfOYsQOnM7eOVzM/VSdW+3sTrQMCvfpd8HZsWT7d2dSyM4hsvRaETwxxoXQEiZZfik0oH/EJSH/AogfvXu4MTUiCekNtPRazJPa9nI5M8CVtMiSUb3mY7OJ1OLfn4nWBvVTxp2sP3nTSwLEYpop2lMUwEwy/O4POXUuKDZQOEqKb5yRxuW7bOSGSDKZKHaZn5X25BwVOT/oNX/vqSRGxf8OWGVj6Ic2RNuGnYWDmEf1Rp4BVn8xATzOO8/o3yDnElw3M2gBkQ3hDWFM=',
            }
        }
    }

    class nimishg inherits baseaccount {
        $username = 'nimishg'
        $realname = 'Nimish Gautam'
        $enabled  = false
        $uid      = '549'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'Nimish@Nimish-Laptop':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAvxpHpaUUDrX95CkroBTDEDMpfUj/S/5mgd//+SiVZIuCkbnhT9a1WR/XtX8Z6uUBrv5nya+9MR+Xhw5h8dG4GRM3UP0IDVku3K0M9BBP/3rYMssiqb5oLDBoLh/m7mmYuvMbs9CegFFYj6M+c+eUvu0omrp/koIiWLOE2QXT2sVVooJazKLoCaeIxiw9A31b99gNfl0cCwZMOwY+eqL0TY3G7d0O0fgE0lODwtAyoh3SxvMmyWWatwhEcWb+/knQx+cDquNr+q4TDl5I1B4fzExV+4sVrvrgP2JwM12rmcmF4VRnJOGNpjC0DXMbaFnvaO6TPh5EmGY8GtDRYQtTyQ==',
                        }
                }

    }


    class otto inherits baseaccount {
        $username = 'otto'
        $realname = 'Andrew Otto'
        $uid      = '2129'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key {
            'otto@hundchen.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAw+oSU5aOOAxlmjTZvJnOEPbOAOchKKeTi5RO6KIVddIVXspHbBZKhuBmDLbppsB2x/kA5XYC0otA/FD1Ldr7v+OQp3XRTUlxchjGKci91ztPL4WbedCR33DUjjZW4ro2XlvoSLgH0vIZU8B3a7a49BgtXIPxtXw/evmzRmRfguNam/pvVfv6AE+1NGNQGadLNP2nHTjd8B2WEC1aVIblk3ZOsLsGvvFQQvuwLdMsDcK9/6Khy6rE4fYXJGd9ucVYIH0V/487Syg9tvk9xMEX46z4O38EV42CVhBm4ebpQ8roJJwwuD7MGIUeRicylvmVHHd+KxMqB6VkvGYIUXcasQ==',
            'otto@klein.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCyYwXitC3hSK+Gwfq3y0PlGlQMRHaqsTtJcDbgoxuE0kzEEKwSVpyXIxoUdUK0Luh2eVkR+CZ8+5lLVDJOhrGpBT6r/Z9p+o+9rVopNEkHM8QxqbhDoS5gbSEngISM+Zcyo1wTK+bB4tbzCcX7eJEVlxmPv4Tb85zDcMWSR2ZWV+jPMai9/3uO61Q3n9GOX94+3qIWmZE55AIjLT/lw3iGffwSMffO9/8UC9U2sVW3v3daXuvDgmjKkAiGaJp+Evq82ahQEOgOWPDuLXYo1DyFuqsL67CDA1hYZfA9FJRfUhOW9I32mGmFpjdJsFeWSU4VIOHO//Blpy0j6h4IPacJ',
            }
        }
    }

    class robh inherits baseaccount {
        $username = 'robh'
        $realname = 'Rob Halsell'
        $uid      = '2007'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 
            'rob@laptop':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAoDAuzkYEIeGVC10zh3i6WnyJjhWK/JpQbSFlWfb5t02kGPvmi8m+fdCPhvqiOpOCcQqTL1Knia6AeRNMx+dj3qxctsas/RnJtIUbACK5gH6aKg0OMmcG9LNiVLN5knx1UMHhQ7Ma6KSiDLeqsID009j7+Fj8qgGup7lKOQs7WYRpaXlAyR0hdKeyxcXWh+GPQEZAhl0DHrjFgdDcc5n2K8GBRESfdfCKm0SomHYGWPsTIpWrY13se0kUJzWXIafzr0U/czEdVDuSuil6P65d9cU7vypcUC3i5d2L4QiO4MBVNcXluFuFNZ8UY/QAlixz/5x/ARbgjcMvXwJQWjhh+w==',
            'rob@Navi.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAsyIODQk6BtkDVp8rHfMRZFcDJxdv7jLK6ga2U5oRUb/thKLoocECQ8fEzkAJBOmuyhv825W86NmiAmPj320gI72zQacCyu3Mj1FnLQV9P9z2G6POqs/OdnG+3wZV1aTRoWHFREalEon1FoBOSE2TOgr5UtNnL+X+pmFkqjIKmCx/97KOq27xwNlYLEzO6FJcSptDoWoYEChT+/MtUiKoh5ZwAxSH1j8iLLwsKhV7+RC5EKKor21teTRMzYj59oYR7wM9IuhKFJRewKRJwaZSFboS0H33QxMsEgZhbawOSBn1r3mepfNsa+AI4B8T/1EIdSe3H+NArq8Wm/oAR3hN2w==',
            'robh@zwinger':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA8SKRT6tT1G/qDHuSoZsR/qTEREN7Zk39P/Gptzr4Ttu2TdCRDLyStHrssqfVXVXwa9AJ7UG8FOnwkz6Ow1zjQEOce6dOAPnZI/hdrxChsUOULTzxK56KwHh9J51vu26+2xpuW6CG0w2ycohTjAXiNEQJbfGthQTXto0h26KdZsCGqTbAlKy1X/Gm/kJeOXzGNja9ezivWRfD8XsNX4igKz/2PHRlWhv6hWIzBVZmMJ1yYm9guhwWaya97uRTWhD9H0OL8/xKBwMrM5eXlVWX5BQhFwkqwvtArSioIWf5wD3e6a0OdOjfCHZEpBpUY/Rv1BW+9FXJ310nleoN4kfuvQ==',
            }
        }
    }

    class robla inherits baseaccount {
        $username = 'robla'
        $realname = 'Rob Lanphier'
        $uid      = '1233'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'robla@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAu53QXIYXig1FTP4ve0MOMSXZXtMORld4y+f9cqmKA7OAStnT1VYw6F0eBSPJH0WUo541iMKcsigENytdn/kuSu8zmh1+nyHvhndB3LvP467IBo82LRBaZ6X0+0y5X+w1w56oX5H+t2zixWPHTQu0f9XQBPCsZzfV8DkVbJjwoHk9wcHI/lJSa7r5dI0xWPWYXXHM6BeAHbET1kcUAe3km1jWDsh2gBgKfwis7iIZx6ROSBOfHdYs9MU6miFq/9kk2/Z1vKOY6bj3adVe+wbd6JFF0UZdQzstIW3/15NfWJjJ8X6gx5U7wchtuPjnIyydUTU5u4UiS6uUS4e+MFsoOw==',
            }
        }
    }

    class rmoen inherits baseaccount {
        $username = 'rmoen'
        $realname = 'Rob Moen'
        $uid      = '2099'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'rmoen@WMF317':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDG/0pPRUoAhvHvgodmPYnqh6JZH3+QFlECg1rCbetr2sVx/0cpEPkqciEC3UlYm8iIRHLr1AyxXS2fq9ruB1oNnzzCzSHitzCP1XkjqqofkKVWSAUhnjhZyJ6VN61XDj7PvMJW1dPY6ueqKfjFR5/1icbG1yIqeUeJ89frPsOQiXxUAnebOojRK5dNkhVuX41jJfUBI5y0CaxxE2EqEQn+LlI6ZYDpORj5q8vP6YyvrDYS/708pJltUN+4rM/BKTSbJ2TTqc89klkY9AcLgGW/i6QMw+Qaxc22cx9TmpAAhUmvh8GX+yX1jylh6Nt4mky8L2cf6wW4ShAuDKLZoRFF',
            }
        }
    }

    class samreed inherits baseaccount {
        $username = 'samreed'
        $realname = 'Sam Reed Old'
        $uid      = '557'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'reedy':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA3k6XjeMEmIHonzsmRBbHCkeVhxS6oObibs3PPP4DAO3WYXPIGBye+OpPtCpSZUuVp4t/GwnqIHCM0MrlVoFKeFcC3tHtVwmxhIsTp/RQRPjjKNdH60Iz6RlDTZ3TJDaYkYOiW7spdCONLzkYpOgkiph973aMNQ3D0vS87jht1apUl06bkxYeC+Bziq4DSBVNqpGKa+NqSYOvtS1kapwCYTtRm6YASb0YeMXzTUyfClgvq86h9XLsbx7klWgjHfKbfi/yheAm5EY6jxicnYaVAmy2gq2ERO9e2dVbpJihHmhPTpdRba5Eln0CoPkWrLVX0jyiAVB4biRtYoTtxGDPww==',
            }
        }
    }

    class reedy inherits baseaccount {
        $username = 'reedy'
        $realname = 'Sam Reed'
        $uid      = '1226'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'reedy':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA3k6XjeMEmIHonzsmRBbHCkeVhxS6oObibs3PPP4DAO3WYXPIGBye+OpPtCpSZUuVp4t/GwnqIHCM0MrlVoFKeFcC3tHtVwmxhIsTp/RQRPjjKNdH60Iz6RlDTZ3TJDaYkYOiW7spdCONLzkYpOgkiph973aMNQ3D0vS87jht1apUl06bkxYeC+Bziq4DSBVNqpGKa+NqSYOvtS1kapwCYTtRm6YASb0YeMXzTUyfClgvq86h9XLsbx7klWgjHfKbfi/yheAm5EY6jxicnYaVAmy2gq2ERO9e2dVbpJihHmhPTpdRba5Eln0CoPkWrLVX0jyiAVB4biRtYoTtxGDPww==',
            }
        }
    }

    class sbernardin inherits baseaccount {
        $username = 'sbernardin'
        $realname = 'Steve Bernardin'
        $uid      = '623'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'sbernardin@administrator-ThinkPad-X220':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCjegqSa+EXwVFeeNU/vBWj/h/cQyDg9eUKGhuSVQt57klqZHU0c/QfACx+bIuNNsfP7x03TeukA9AoGk4wpXyyLT9bgaBNPTjjDMz0p3FHzCTdjGTlTx/Lq8cOPaiVd0jgRFnVhny1PJ4ml8KrKw+57oIA0n8LYzrT79QN6AEe/egvd3lvdutopQtKbrw7u9zvw5xvdv8s/u3fibvNlrHaBwYUPahOa77FuqS6rZDeIcOBVFxqYNYawSmPRQUWqVXgntQUOqI3sCaodsbcXnw3wVO03wEWTzjnG7WnHApAHZ4fbRpDrgtJIn1EhrxXJtf2A/sA13sdXx8Uk1uIyLqn',
            }
        }
    }

    class tfinc inherits baseaccount {
        $username = 'tfinc'
        $realname = 'Tomasz Finc (disabled)'
        $uid      = '2006'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }
    }

    class tomasz inherits baseaccount {
        $username = 'tomasz'
        $realname = 'Tomasz Finc'
        $uid      = '1155'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'tomasz@scratch':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAME+XGr43e1N0iWu7qmC2Do/mGBoWEGrSObLXk6Fll9+WJ9nRNHvmQAkEUexWEQaolI+ItWFEAVU/j9pO10MvF4YcGQSGcUEbsQD50W91P3+T/ojnP6bhjI2/aX4HAg6bk0Sq2ckYNpu4owJdhDnTHNk3luptOSwVLnJ92Nm9S7JAAAAFQD7L3zwmi9owkB+HhHxzqgwWAB7LQAAAIAOTsZLkm8nfbqMF0QRWKCb4NU7spftTiFLgVNiq1nQcSA69krEzZPi17vOfJ1a1iMWJL1zKHZhIxbXimDxMAwKS45WU2RxfMbtZw70dAK4AW635yb5riIyuc94NwmhquRypPcGUQKN+/mhxB+NDs8AG32iQjVD5e7M+fczfLsRfAAAAIBoRL51kK9c36OMcrzOJVR8J9b6bkV/AclSQmlNzm2b3armXf9w2OlifqobOpoJL2PG8HWKd7QAqv7PvON20HErNDBMCYhfRmX/Bn4WcWgZzq5y5I66rGs86nqyycbWAFbz/Yd+zq6P1z/LpzXnGsy8j8CAJGQ8c2tXvNGhHToHtA==',
            'tomasz@wmf-barry':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAxk8Zks1Z1qsFhu7CmcYC8474ikLmDVXXLqeC2ekBznIsdX2/1IPaYIZp8w4G8M2X1InMOqQswCqTfvQFuMOFWxJvTQXxZOJUC8L2El1xB7t4O7mvDXw8uq1h20L7ODsLkFga3M7W7IIg3pU12HS1UAInYDQt0SCXtLaTbPQpgP8H0XNZhn/I3P/NVQnaUx00YzrS9ZojNbwEHB8cUpwp2N/gfv/byTTe48Xaq3wlAxw/QTow5G+r3atEOVJ0QKGztl+uScF/ZzP8QYficdMP7aNffg9aQhf/uER10hXu2F16UZQyoMx/sFkS2U8ZNVkCKLhI7MKti7+ZGz4/+fcCOw==',
            'tfinc@kumo':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDOXgblcBarO8An5LNYfIBOjl+//EK6XhJu3agV8nQvmuaT2qnPtIiLl3W/X34bKHcRJbWsJRe7C3MqJqFWF6BWWtU9MZWj/s1TRtyA8Olgx4y7cXGXSUY/0woJnM6yIh6WitQEPX35iZyKaVapX5FCYlkkSbTEAbJwm/bFV5j2hOTyews7Cff1E0Zp0+E4hli39MvflkMOtllcZvFoLjve5AjETeabZEppvvSR8VPAK5bNMl7zo7fWcoExaNNlglLLRxP8y8Ne2PQlks5gTMrsh5e55BGVr/Nd6kD5OIB7s63InMbudYViWX66MjPgKMXXg8m7RKqkLB33nBifQrY5',
            }
        }
    }

    class tparscal inherits baseaccount {
        $username = 'tparscal'
        $realname = 'Trevor Parscal'
        $uid      = '541'

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'tparscal@Trevor-Parscals-MacBook-Air.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC7az/zEdHr8aB1y2uojbvCq/5qM9hSS6GV4TQwN1OojwyuSVipsliJ0ikuGXSHRfzhjfNTx4WRYCTG9TdoXgIRly/+QUA52/4dxaV32f1JakYhdRtnTDtuD8GCju3J6JFcd2FN6pipYV7jhzAHHbug8q2PlD99PZ35sBJ6/Of9aCGA9v1tG8nSQ3vXOg1kcSDtxUQLf8cGyNlBIKOjSmJHp8ym9/ADI2yXufqYccuunqdVgUxJ2XsqGAXtq8Y4AJdUyIoQVVFtXq/ek0RY9kIW22910V7aipFvLBahUUnnYsQ1T++A8yyGHVw+ApL+lT5SCtJwy6eHXdENhxrwgKTF',
            }
        }
        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }
    }

    class aaron inherits baseaccount {
        $username = 'aaron'
        $realname = 'Aaron Schulz'
        $uid      = '544'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'rsa-key-20130812':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAQEAljtlNa6pQX9gEyjrpCUqqQyO1HtYtHFSDuWBiWX5oiLnTSXRr0e7pECiuy9ISEI6oIt7KkaU68+cxSkqK6gwr9YwZ5Pmj3kkopT9LjguzBYxN3jEOj5+oGwdyK6ivQQA/PwPEtVgk8LgJ0EKf+74lQ4cQVsZXyu25HTq3cjfLgQRpwoYc9OBuuwIj//3uhLvIBKS3JvO3BGFsjZBPJmxoZr6+HJI7lXNfy6wWbbinXMS0gzVYhHvPwU5lFYSN0/njh3gCV8EwBYdzV6PmF0q6HXM0R1gLH2FfrhwJY3mnveWu30B7VXENYUHqc6H3wUt3rS2koTHOMvBgy3PbNCyXw==',
            'rsa-key-20101031':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAIBv9rklx9iBwtRUh9JB9ZwRGPX60KrS22X48XR4VjMIa56+IG2/yfQ9Z2nUl8Jt2gNHg/SG6JXelctU6kvmg5J9nU+fTYz88Yq4+DOkMwl88Q431IMXW8WKODKkj3dC4I5xHPZP4YH+eWuLoFphJtifiLNm4lbhKG7cxtNtowWj6Q==',
            'aaron@scratch':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAIBwXVG0SwhtFVCJGfsOi+P5suGzST9RjFeyXIXMQJX6JrpcyCjwmA11eISlnwuOIpd4vyjJ+uJ4IVyizj9xWjLQH0Gl2+ptkyR5IvIyi8EosSpTLlYyZxVXqod4q0vnEGmFPcOMN6eQKOEX8VX4JpplodBlEVl+p1lyr+YAO3S3hw==',
            'rsa-key-20061225':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAQEApNzNTrx3FjBamdXUIXzaI34JNbhaz0cYmU9UZiOsgRulBuDLV3V9tefWdg8AS4sH+Zl4nMXHqwQHt4+95u9j2LwoBGbfSRqowo/T0Y1WGuU+vRBFIzRPRwardRdkqw/dGaVFGTRkWG5sAS+tNmjgwPLp4gKEho35mw5J9pljwI9KS0+BUgTOGcbApjIWJLS+XYLb4zPKsb5SMl4ZDfEa1ULSQp24xrjOk8vSfgsxxplSOMsfeETmkIv9CD/OpRQWWpAOakMS2KrLSf8IRn/Wm3dbky5RKCW8Y6RRA7pV0Mi1/1JoFMTRAUrTrjxqqVid/qXGZo7GjKz6UbXmai6XOQ==',
            }
        }
    }


    class tstarling inherits baseaccount {
        $username = 'tstarling'
        $realname = 'Tim Starling'
        $uid      = '501'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'tstarling@zwinger.wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAAIBAIjSwE2k6G3cE1QPq9/6S027XqAdKDOCw3nEKxaGnPdoLCxaLic54URUyvrpqsZ24fp3iC7dlTXegvdVx3cLpHIopoyDvqVgU/gf5ZxivpfjVkygtygg721IG0YC3wtgIPey3ipQ0KbDUfSAOBmMEJ8+g47U5TOzeOsP7kNCKEbRLf1+e1uiz9D971o50haYjcNzDUZHQbuAwFo/tk4sPS0RKmI+FPupT5wXAqGy0CAV+MxDBIj98wvIXXu3qPOFocLXXFSCmjD9zjrKWrs8hvB64I9tGuErIEKn9sX7ZKugyA+tZ0eCUtOvKkCv9g6+gQ94CpyMIVHzosT0yE39qxnSBW7OeRLguoiX9w7AkhgRuWc6rHKj4IZ+lT15GW/oj4ZXcl4o+NlwgXAr1LT+S1jR/fJdCcCPp/+cDhfpfWSlns2+jnCmL4QxaHZjgqhUJIao74XxceCH0wKk9c3ZLb/6xQ2md4boL8nNcomik1Gi+iOF/nkx1Zw74r7MOXFil2oHvTPwUWym1gwBJhUONtcvb6y96JztP0gWLGAnG/EitQ7JidHYWXbR8Zg5Vo7bCYyVcPgTzbEHOoHXrLJqIq3nRf/aV6tktU5fUcMwhhzpfio8yhvya0zwC1lsc9SN/jWXQYOkqXPfwSxcdpS9DNAL7CiRT3/eM+VCovqXld5HAAAAFQDvsFdTtuyeTEj800ToW79X4qb+oQAAAgAWhCcL41TnRZuR10VpaWWZBFAn5STbSJ6/d4TOK2iwDj1SzNPCtLlqYyOTOD8pNKrJnoaLsMpBq7JxdcusF+u6Vuc0wQsoQYSJP9MjUrSj+XV08Yr0Hf1iKt1SpAZak6STPtLR3EcB4HQxSj6/8U/bwfvxDullMTPJpazaSXTuwaYNiRE2f3D06YoFWs6dmvxMPSJGt0a/IBuCKsaeG0YB7QKXckZ7geNKA3AMPBgLPnZq0tw8I+vMLI0nDN5amh81xA35VDKihUNvp3cd2STJ9PJswR7EYHG/dMd8jXABhWY5UEbb9qQkGg5Y1MgLOjBkNT5eTwzgtW+m9lMEbu7hUh4B9gbhbMAlOxnda8Y1CNVrAdCJD/eUkmtq7jblJFNFa8IYNpGPIouHTwH6NOQc7olszsGi24xXf0X7uG03Z2xnEy/I5IYw5cW6uL1X0z5mWEEIMYNZYLCn6cGyCkH+KHTQIg3vST308AJtA7VE+WbxW0iy3gbTSnfsWTOE0SduITZ94r8FjFePKkCWn5P5VvlhXRf1yauurjQN1vSKwQPX7QRlkVP99RQLCx6R3COXvFS0CdXAj1x579wCpy9b+4MmY4UcVP5uODQM/yHnHxAc/QUpWQ8AC7570EVesWvvaFdgNqnC5rhi2JnCWKtnW1+8gHuddRyO862Ds/Jp2QAAAgAYVo8RyjvlHo/StZZ+vmXemtk1gzXhGR6HW57mVx8cxk0opa3c4SIvjmLBVGO0Yk/W/Ypsy8ikJivuRqebMokKLSecX/SAH6NjAYSafDzUIaublbMT+tctayY0drlWPrx7vaeR717z+VNw5kUeBlrDtUOfHHCJR1CYodUgR0OPz8uLq9A6aXK/PxE0QVvSFQDdCj6AwWswtkKhkT3u7lTaLAQeUUv9Z9Nl2JhMtOyEwYbpd9vqK9/1DKn3s8HfbwJcNr4/jSAjuXTIbKb02QVFrMZYw8PFfShFKVnFvqfmZd1I4J8HwUhcDVXeYzslLJZJP8iEzo8K1u8Jfnpt7xDJPN1km1d/a+iBlLhnJpMxofxR++kPcRSuKxOvueMIrmPZkEW2rYUUTAStU70bNIO7LHq8MorfcN4TplztDjJMRUbzbYlrxxpPmQojiyMto2k+qgvfqZKtlFqIDPXCWThMSIyDd8JeMOVBTgKWiYehk1wBLtgEQmRrKJTEg29EoXYRASHfeTCWAJTh5V0lU8GfoOMVoV+B2/KtcHx7pDc0S6O8weFjpNb+4wXfQ5LnVBilOgIlzqJmz+Q36WzjfWz1nF3jwNM88/pEcEbUW7v4kHxLfSNcYs0r1OXiC4D6nklfcpwXjwjGkdK+mCfPIwXJ3s4VNBSXiU+9j+I/m1VgLg==',
            'tstarling@fenari':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDTDmIgbftdeyF3wvKYbqbo9ktgS134XNt9LCfryDohCClsujY83seA0BE9FyO3cJDYwt75frBf3m0JZcI0x9NXwuK73pVp3PJuzUk7nQ77BP4hbSWGbDYNDjYdZp0IZSRBYs/A+y8NKhYiDoyAep+JrM9FvVVGEh+gB/BPizYNv1ru+IXXL7FcVRMc1AUTDf30zZhEyj+/MoYs4m5YMMOW7Qg5FEyVFAOeTg95HZHAtAOwMeycbrueqf9qlIm0kNC5NWHMthWklCY7R2gVRcbYdoYuTJYLSVBs3Vbhygk+M+KqeNEx5+GJX45PAWb+qfRHE5GbsNuo4RjhyTcSBOWt6mx8VyOiSHhHRA/AFDOHzR6VqlM4buHXGARFgbTM7ypv5eiXyIWhYhohyQHJg9IuyPvL3LtHcixgay+0aytot+/9Dp8JQ5OtuzRzYo8AwwfnihF4uQ96u2TKAkkINsVQpc1haERbR3JmQHEwujg/iAj8q9CoUYtvdINfMTg7n1IjzdPFXS6lCv8WeDnQPhcmivz9Psjyrs3nCGlHmox45bAD4Snonp0xQ0Nbd6Qw2DDQh7YTt5sutay00V0FYGVyGLJdlY/CEFHsauQJIILwzxw3PTEYWHEakFnGEaJWdWPMSlNJ1i1OGA1ulg1FJj4RAQyK/mlHMMFTiEE29of6HQ==',
            'home':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAMa+T44Jat4ZubaZtanOlvq+7vj2Vn2vdOoAeafH3EBiXRc3FWxbL7MUInttfVMAQ+kKpMFrMfyZLCr+xfe2266zL9NuRN+0NK0unHnUJxKFg1xhlwM/miLuVIRPNYjx0hb5bnEqEdaHWhzDAac2Th8t4l3Bkx6irtLkEbG5X7rbAAAAFQDPx0nvVb7kjyGUtRpUSQgWqwO8BwAAAIB6ywz35DCRnX1wb6d+rjxR2bzzpI0EBe0XFs+EhWGcphAmc01gVOQj/cgM8X9lWzbzcepN/VLJLNYZDmhT7BCQx1bI+3mYMdHin5aTA1yLo0sNbTu5ECbe4cPywdWkRbUVXFFtxG9+xXd6l7TLUV0ZweFiV3hmeB+hKoisV0L/GQAAAIAF76e/8Nf7K67DM2DlYmjrfJYG0fC8WwbARKIldylkiVrADY8DFdc+dEXbUFlqvSMX0wyWS19zlC0XbkA+6EwIMfbEfukJoo84ygOhcdiqySn3JGxyQpuBQfiHK06oLxqNxpxs2R26/beqzkIzzIx8wXDN+UmjZUDuIVvYlWUWsA==',
            'tim@morisset':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAgBiM8cXr8iIufFuuivuFQU77SWPnzdSmAk5eiPmkv/g5Vx35VyportZd3pjXKJMmI5biZkZeFdzLyFdhv8PPafoVjUl6iNEIQNA2HGf4N0F+I1EW2AKjJVG4sy4x8xlqVnza1v93Q4ffjSGLNAusXXbSx4SVRhZmNZ3QoKP5LJqZHrwpQpQTNinoLsX8FWVzaiWNUqoaVb6T1HgvMUbMiayHlvmFZijA5ps4U59Yf423jMPzS1snNZ8E/zVrPAN4fBbIAk17hcdAMJm9eCFwmKDiSnX1lU2ylHy9tPgsOFGTTZkWaEkcQ6/9DuA59NckO+bsVtj85QtCog7X60FHppRNA+0+8fUPX9MCZJp7oPAH1J0V0k3zSrLXA2SerrhyrwyYBQIlusK85Op6OfS9OOgUwf8FJXwAa+6tAc4HUAJbNpuR4UD/jZg1jJygPtY9YzCKH6WS7eWXTHKtaNEnBT5l68QainJ5zH8Mnt76STMwzD46rrmD+TtnZEqF+Ejd0Mmi5XiyuC/aI0/5Eyv/6cVq7cZ0yU7dWBcvutpwtWW1DApOkT6q6QmaxEGFfuEIgPaZPCzLSn3dztYO2qRk06VQ/B8W4MlHxZNef9tMr3nASmKNiMqiLtbAPpbZjV+XPOTCpy3/7Yt9Bh8/Bdh07mGMQ9/nIJo0UhInNU5OsXsUw==',
            'tim@colchester':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAQEAj/IGK5iSyu9wKUTpAtrJBYl+epUbJMaGZ8KWJnNMTHisYqJv8qHivTbNKx8heBt/6d63V2V7GNjwz1MUdJnN3Qw1opxFSzgWoz9CYepYyMcwY0Z1Tz+aR3SEzvuA3s4ot081TO9muDH1XdjNFwCXxpwrf69jL6pqtScjaGec6WFVD6gfA//+ol1dCbgpohqNwmhQyQB0wiKixpsqS5WF4jPvBWHcyDuUKxDshyVzTPRH8pRMIGKX/lrkk9s/rZkNG+Pw5/Klevz0YsoIz+fzVgkONJemDhjYggLBXQUI9tOcrvfU26QM18F0/TYKg53IjXEa/M7P1xCrWZ+KNl9TAw==',
            'tstarling@sshproxy':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDaXB5sG7i3ZfNyaWZTFYk3qxHeLa7MLcVBWnvNwBE3/DYSh7xannzxAMbhwnGqmM9La8Q9TC4lg4RtgcXPWQb8m59wDUxVrGFHyP4+BBa2p089AtWbaSPQOcp0uy4oHMRKjT19qUAc3GtpMHZPJMwDK87jn3+LjELQHP3596dRhZVe2EecoFlbxy4XpB8pQGlCr3y4WuCshGBbr5aoyoHYTFGyIAFB3mzNWuAOhbokbFu3MDT4YkHFMFux70zqktJxInBJiYYoyCt6bd/ej0OLz6ukTFV/4pE+8p/HngQVClL8bZe2h3BFbxMJDlZD2O3rvAU/9Kskk+/tkd3azfFYWdvU3h+rhITGk0//hNHYm4ozo9epHhw84SD8aPyWq8BlPM8F8Cuv78Fdy5vz6ZIeMe+zzesvBC/TXcfVr7JEZZAqm+pCrr2QVFKSmXuDH1pHG60NUqFDiGpfKpIW7+KCbq1Gx+8gLegU0qYZZr9WrEEt1cobe3YP0GBcoR9vRAOk0u0kmWmdXqnphTjEVMC7S186jw3F7mgqLmf440N7bznr4ue3nBcoSN6VSv48yJxy3WVOc8leZoc6p+MU68asyFGJMCsbX2322tUr23shuac3VfwJ5hKhOGZXeAPB1Dt7pllJlRQh3FT5/T/4Fjo1rNvq/JP9njeyZSiHVEpE6w==',
            }
        }
    }

    class catrope inherits baseaccount {
        $username = 'catrope'
        $realname = 'Roan Kattouw'
        $uid      = '546'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            # older key
            ssh_authorized_key {
            'catrope@scratch':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAIEAg8ogPqDDyhMBfXdV6Z8UKv3esRE4I0EAkrxnCCXuBfBnJ1A0dNsV8hKBsdRs4UCEitIA1a6bSCbq+kV7Xvq0yMihAFe3AG+26OISi5NZP+gNtx/aIBLGAgDXoC3M4Nb27F+pEDSfhT5OC6N/uO3o1UK4RSfgWNsmNW/lk5Ir57U=',
            'catrope@fenari':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDt0lR5k9MsCt1TnefSX/AiNsVAurjqgl5w0l6xgRmZWeuJUJ0X+0svKjgJPnTVFLjfBzMy7ACkk3R5U9UnW4JNY4R3PlgaSKUe+u4/iFP9MVC0UsS6My6uVW3xgEFTksEQucmWsj0SJVjLcS5hGIu0Tl9SLkSBT5gQLwXRhrXopCK+Aco7ACSuMNjKe7Vtslmh6l3qYT8L9nfYJ/dZ/2Oryzw7rMb1SgQQhXqUIUzTu0lSBaTSjPbe5fre2RvGLnIUQbrt0PQd3AKGBI65LaW53fEMhWHXTdw/p46PkJLfQ1X3i+N8o4ZGRr4aVP/6Cn5ANOyu3JnSoxmI6Pjoyurj',
            'catrope@fenari-2':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDAZea7fnmc4gDHyupnZA+Cx8SFG59oJnKMFNi/fKLyqJyBI/kfWnqDaCJ2bCFEwMZ883zPOZegb4VF/D6aO5LM0eo8KVvCZHWssC9Le8Og31L/Njg03fAh7P5mLY+vKYC7WtY0IZQNLb5BuW48C+lnjwZ+Q9t0up36vn5U4aqgvo+OosAd4qcYcYsYF20KeeQCtuYMv/rhJw1tD7HuPIrXjBevPEDW9n0DyZDTKjfGxuYkfnO+qpiFuKba+/ns7pSgRgSwrAfVzyM2eo4sP9b1/1KoEL0E5mhGn/BGV/yIWVz/S8oBb8mMjr3OOTfSu97//6fJw/TDKguRzhqU6P4l',
            'catrope@catrope-Lenovo-IdeaPad-U300s':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDNnm5p7ShbI9suKmhOzmYfYScifGDJ3oS9KtwlEtuuVXThsdms0pF5KrLsVnnZWGyLsOjAARYdvNmwipelXebpQm9nMNvBreHCGAmqKFW2UFi2yMnezhANUhvdtJL0j1jjkhh5liRsesvw1Xrv2GvgKnfCwGvUcYvrwcLNTTGSka2hAGfQRalgomSdrb0diTzqA6Ijm33BeiZlpmbgiQ6LzeZRMLrs+Nm+EtZIRLgb08DCZfebIoPH6hh1Hz38ljpkQm6menjpxbcrVvjBmXClwANPssSaTxNEprrZpeS9/2eB0un3G8aLmORohgJ15w1w2KZaFXokYxQ7/ky5kYID',
            }
        }
    }

    class pdhanda inherits baseaccount {
        $username = 'pdhanda'
        $realname = 'Priyanka Dhanda'
        $uid      = '547'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'pdhanda':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA3HbBUW7PKFdkYaPkzvPJlXywNtiu2+9w0nZyfqnC2cM1oEh8E1R8q5gWiUnaeNr65XYceMl/bja+g2g9QZkBAHtQArOZ+DePoejPUyfR1UUczARRywTFVTCS6vSZ5gAnujPuEcrOU5UTVgB+jicX7tqMh3AyJ9HBSDa0FCgK6PP68w4zDgIIFp5wRVBhzfPUNXHUkRBMuUaN7oGtq7VYaDITGLvyIFDIQ5FHLXiuy4OAAPvnf9/4pC30d0C1BVMPJEEIrj+KzlNSdUfy9WOxeNYn6vfsc0CR+soie0um5juwfyQWiDVmw2/lJcB47GoEqZ9dp3zXc91tsVEom7TADQ=='
            }
        }
    }

    class zak inherits baseaccount {
        $username = 'zak'
        $realname = 'Zak Greant'
        $uid      = '551'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'zak':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAwu/7oKLKRTpxp0fLluRb09aJQ0LzFkN9mT1R5AhJHJ85x/UimXayTdZ67oJ72pteDEbLuGFGtJ3KsCs7a+L1e+YmRXKETap4Wy0ALsPQs7Dwvlp0AnOBcLXiWYtrdnAp21SKOSjIdw4Gd3RlcHAvWCAMKBodXLwInrSH7YLgD3JHwFyCBjqSqamfz5MPeoaFd8dEAPwTQUOHZfCHny9ljqTDrznIQTMKslM4TImw4WBYIfFtgokgBNTsZdRkJDqy4C8FztzphdVbPuRVvOPALWES12At2KlauofjM3wNMYB64jn5luqa8LcMMwdyz5MlXLfVV7MBpN3F6rlVdxob0w=='
            }
        }
    }

    class awjrichards inherits baseaccount {
        $username = 'awjrichards'
        $realname = 'Richards'
        $uid      = '552'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'awjrichards':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAqlaOugpX6Kz8NC2/5FdwvYlBE4ve9eTRHjD3/myj4cKzCkeKlDZT3DLxU+T4Eb7jmT/g+BeTohmafLoadg8d2YPu76HU5or7Ix6Pr2ZprDgNrLEnxdzhKeRZXT0IbXekKXWflmiRaB8LUH1MO9kTtm/QxlsqXRV90dExoJGNTlRiL3tEFro5zeiZ74qXFYXSAvofOAxueS/ZjIYmO6qHKuUUybo0/G/rN90wfG0tzzclhHv9dkUUgDqxj/DzXx37u9HxkaVFEDX9yQxVwQ1odq9oaIQvZslOMZZhaXoNkBlWjnT2+a99up60TOYbjy5tUNP5UJVzvtfyO/UPe6iZPQ=='
            }
        }
    }

    class rcole inherits baseaccount {
        $username = 'rcole'
        $realname = 'Richard Cole'
        $enabled  = false
        $uid      = '554'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }

        if $enabled == true and $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'rcole':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAugxekmKIaoXPi5P3DXSG7CQM8tvDsaXjE9SEdAhQ0G/elNvjpaVUO1qp1OatsvcMkehlKsRC0/7+SsQVXJAANe0TD7gnYJPfQXq8aY9+Q/Jw+/qNWdTzlJpdyY5ZY3OuBXn2oDgmxk1RmEzCGYfjGN/+/tuQiYUoX+tJu/EbxMnZQjs9CTf3YmzKOI1Sghy2wHw7e9yYnnevA1zUgWBd0hy5CImxDquzgiW38Bmx1HyUJnaTmxeSoYG7/o4Mxqpx2HULPZNyrDuvDxpO3pUPqANgTIHalH1PrSlbpORm/mKlH16q8qvV+ea5wOTtev8/Hso9+Qh67emczngQ3K2LUw=='
            }
        }
    }

    class rfaulk inherits baseaccount {
        $username = 'rfaulk'
        $realname = 'Ryan Faulkner'
        $uid      = '555'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key {
            'rfaulk':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA1WerRcJULxj26JimklCkoFUO6XKBjwTbPH54/hUv5c3lvyuUol6AF86rWziHgwIAy4+jPlm9mTS3IzWoRf0sSMgSrjkmykVaD4Zc+7QnXXGtnehHfryKTyB30TI39/JB5CoS1pGQQoMg67kF0nl2RKP47r0HY07m3rl1m5MWMTKByZ9p6/oVAuJ7XNxLjfN1N+Li7HhyueQonkw8Na4CxSz/Uj6zDgxB1Odw9LgHErgOe99Nza4yOsvpa9iq30eLJjXYKJ+9s8aPI68H+nBh8/CaBaPJkuTcYfwXhE6EG9JTtUrf43y88J+SDeN0lRF8w0SMluheIzkv/3TNyDdr1w==',
            'rfaulk2':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDFlxYVmNcVsP33eEHhNc+nHZ1HJcuAZNGNfoNhiHRTisyqPm1jFvt0WQ3r+AS1rErCD3594rkApGAzO20if86OAChUwq2C3k7xB28eOXOGB/EMNswpdoDXraSxgshptbFloy1ekLX/lxWUVKU3omc3jaA4anF9FQD4EGpNbL6lJaO0oloOHdKwyjUlvp8gvWOX2/LH10ALh5/KcA1nC3zlyrLyDfHTwnkDCsvVKe8rQB3pM4b7mVOLstj+dcCqxaVbjyZap8dV4W4QbhqUFVhe9ZL1Crop0TemhWBSw9oh2vQhGj6LWQIwIAfSe6zHIJ2exfq/53nVsHeC98gWr4QZ',
            }
        }
    }

    class laner inherits baseaccount {
        $username = 'laner'
        $realname = 'Ryan Lane'
        $uid      = '553'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key {
            'laner':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA5i6EW2Qwvv8bEEVOM9UQnSU9i+83pz0tmJ9zU37jimdMNmuxUb/2hi1mzmJlDRYDiZ08dIIO02MhkkQROQ629kWU+Dyx2RkxAtHF+vDmShpsp/PNSsPs6+3qDJs89Af7SRvAQJ3jVmQqJ1TzqniiLu1Ab87TDJoFNE2WjqlPlUWDLZa88023CO65dL8e907QR7OHYPLxbpiJMLYFvdJ1nByquo9t+iV3Iu8/WQS1JOPsGriN282qyc3EErir03et75kS7h+1Zhr+Z6BB0MO2cd6SJDl1cChcIrlHzs4zpufUzWXq9ELBmIaxYBH5iUYYM4ezSyA+qEbDnEpweJiW5w==',
            'laner@Free-Public-Wifi.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDRsK78adkRJfbYrsZznpbwldoSpQyyQXrXG6WzrJEBAVIAKz5gPSM8zmJ/kj89QygYRaKRPWAcuF5GZhSho15dwDXm5M0ZTva4/m/Hu4H3j7oxx3PKjZKBiygP7mSu/32TJs7FynPGAFVl/B766Snn9Ll/xwrx4lg3v9ZNEpNMJZ0DQTFZ1xXD2Ns08JvxW1csAEoNrpqH6tTdXdHmhurXdKQq1G/JmKR3/KVWbB1MNvUwCY0mQbN1icuy+JsOXbvXEftumigXRV16reLvX3q4sNmYSFfOGOMMW7K9d+nDc4TRNrUjm8R0AEZ6BxTJsvpahDi1gCOfZnGmpGKUEWgZ',
            }
        }
    }

    class demon inherits baseaccount {
        $username = 'demon'
        $realname = 'Chad Horohoe'
        $uid      = '1145'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'chad@wmf':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQD74a9VKRGqzCmiWZZUkZoy1XnPgd9nlFTsPrBn8Nnf9mMBbzEArMupuolHOSFhczk5lC9y7KSRKiWJ6sypvVjfGZypr98SA1SEe5AxvBN+8DbWEpxxwbOGCMhHo+GPVucILa5cjzZn2iKlCli39oMa0Dxwzd7v+SuswNtfqjp47RlrJoG5hTZMYcbICjEVGNDvSxSXBX2E17Kxdw3CiPnvZun+twTRYEuTo0GshGjO/2fQaTnyYHfPKOyFYC8HDsaaSaOWzXPXb7ey8s4lY+vEt5Imj5OqHhNOuG+thH/5dxuSv6Jkfi1Ygl2t3j1aYdo5g/0IRQ1lIqhRQuFqxe7j',
            }
        }
    }

    class file_mover inherits baseaccount {
        $username = 'file_mover'
        $realname = 'file_mover'
        $uid      = '30001'

        include groups::file_mover
        unixaccount { $realname: username => $username, uid => $uid, gid => 'file_mover', require => Class['groups::file_mover'] }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'file_mover@locke':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA7c29cQHB7hbBwvp1aAqnzkfjJpkpiLo3gwpv73DAZ2FVhDR4PBCoksA4GvUwoG8s7tVn2Xahj4p/jRF67XLudceY92xUTjisSHWYrqCqHrrlcbBFjhqAul09Zwi4rojckTyreABBywq76eVj5yWIenJ6p/gV+vmRRNY3iJjWkddmWbwhfWag53M/gCv05iceKK8E7DjMWGznWFa1Q8IUvfI3kq1XC4EY6REL53U3SkRaCW/HFU0raalJEwNZPoGUaT7RZQsaKI6ec8i2EqTmDwqiN4oq/LDmnCxrO9vMknBSOJG2gCBoA/DngU276zYLg2wsElTPumN8/jVjTnjgtw==',
            }
        }
    }

    class py inherits baseaccount {
        $username = 'py'
        $realname = 'Peter Youngmeister'
        $uid      = '559'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key {
            'py@odin':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDXGX1nI4wyGR2JjZ6+TZ4Ip2fueE0zlpR8Tr0Pt6A733UWKw7PUv0fCIjkOMbYXzbSdnmDRwckqlOSV5MK3ibNvshA/TzxDRLUkHdiTjmJXT8SHmo6RfGp/LLihZq0q6QSnslIGKRPvSejnpn4Y2DvYKsYi4Oto0qkhmbnetrg2vi2WNeUONbtgLA+xlvs/3Ql9iaoYLvbUVrMgd/2PVKRTJsuFplGeIRk5Ff/a++lKH+EerS9x52ooPLCMvPc1ptBWG7/tZlmOryAcWuvqvjZufeEGQ+TrXJ0XRZS9jAgovGJgUPLGl3Qpp5dqXjwXfqhH+xz72Dah+59bmgz6mx4dVDWTlQi1CjFEYUWfw2/4L/bGKabMZ14RObmoGWgZxziZ1Q1g0A66KIAqyQk2v9pI3Os5ngczjKwEMAJgCveBf+tDluURMzwg2S9nfr2t4cOXSp3S7tFwGZrmZVqjQv9AkpcPdXuWg/5AU7NrknCVS37+8N0DqDw0UVJ8EwDHKlC5+ZoldX4WZP394m3O6WqjcqFaCn7SGoiR/sbrNWAtKFd4MsUuXm7NF57TofWr6JJjr284ZTg09874xO9fIkngIyJzqjdzEd+awKErJBy0Ymfxn6qIQz6Nj1qjHLz6JCV1JT4EfZXxL5WTI6JYS/mQ3jdgk6TcBoaJhXKZCMnaQ==',
            'py@tarp':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDR6AzaHdH1o3fQopIaGGmZ0wT2VxUcb1tovmrIpuoWQofr8btP5ODPZ+r5hCmDp6YZNGHxUBgp2TVXyP+e3qC0g14igtFOhgD6MgoJpmoED8e6rm3r97L3NB5vvkWpZUEIo/aNNix8A4FouR4LqvF+1rHo5vI7q70JIKR00hbS6aOjC1pw5+bRVIl5LgSOH/U9UXSfKkTCKbVArvozVyJAZ1zv6lD6U2FYWCEDlc1Q7zR5CLy2I4wmzgjMRUFS3mwMf+KMNNdFxbpZS26i+YxMdFAHVMlF6Rty9Sw3TfgBnczXZ9qlix/vJdd/KBKw70EEMgJgfCaub4PJsOAX0dY5',
            }
        }
    }

    class neilk inherits baseaccount {
        $username = 'neilk'
        $realname = 'Neil Kandalgaonkar'
        $enabled  = false
        $uid      = '560'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'neilk@zilpha':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAyVfwM6IreX+fjXaGwuYMgva6acyUdOB9JDrDcIJLIvzD1Ii5ChWDsM5I0bj6/H9hfSZAXEB4o8w2hVQR1zRDbEPR14eg3FbpR/mP9oU8rdchGMZbn/vgVFKVcjYcNb3ADlRiMRv3Jrmov6ZESV9Y09S6vGwssg3dabfT07tBdjohOHfg4HwHTTwhj5O72OMxOk1zf1kMsOKJ2l3bT0O8NavAn4by/w1gcXek445NrGJBMrdMLh1+WCPWsxaGI3J/um0eNXjxLLbz7tngRBP17JepU8EpQfgVRFy1GsOIxYs13TS6pvWZYfuLhugr0MTmHcyrycrOXZOGBHDFG9pg7w==',
            }
        }
    }

    class asher inherits baseaccount {
        $username = 'asher'
        $realname = 'Asher Feldman'
        $enabled  = false
        $uid      = '561'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'afeldman@WMF263s-MacBook-Pro.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAMcz1/0w6tfUkS2RWeLS4voMnMcKf2Q3EVfAcBX818ssY/aGusB/CAl/NuUyPIzTHIE2gd62WYH0Krz+CGZ1qOzAxs+IoB3CjjbulXf0uIatcTu/OSrqoe0hXf6G1UidVl+7Ymomlwb7AMWScZeWKHmECbc5QQjLJ4h/Ply/65P7AAAAFQDJuUJ9zKoPn2GNx22da5s0WSS6gQAAAIAZr4we0xRJRk7pTLO+Ep+GOnccLycZlNctUMTZ5oDlGk9BJT3pjiYE3BXd1k8OwlDiLE37EiLP4oJXIsVXSm0EuN3o65Oi1opB7rV4rL7nbjZQdJUu+UN8ikQPe+3KQsiziupsP8nufgvufvbmQECNLHkYEiZsDdQjhCwHafdjUQAAAIAJX+wEMbR2dNlh/+sX3QTxYLSMuOKSGp9SzPwqyqX82GO4oD7iFKX6mBFYmFLq/JopGwKqxUQKhBhkBLYaCEN0K+DOnkxNz8oeGRx2YvQLfOiBISuHHL0QMy9RfTvGl7eE5JrwE6hkOzN3U2CeI2fHcsosdsL0poDmUz68GpOGTA==',
            }
        }
    }

    class ben inherits baseaccount {
        $username = 'ben'
        $realname = 'Ben Hartshorne'
        $uid      = '576'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key {
            'ben@WMF290.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDM17PSNhtrXqE8fBSBmv1I79kyBiwy4gNS1WjVqHraDDJ75TJGD9J673LkGgjHAerrG+u5nSjD0X+eJQXaWsZeh2ZZjnTcSyoFxge9t0n88F568h6OdYFMc0Obl9OHFANX4x5p1jsPqM/DBW7McW7QmG699eYdi0na8ubN97DSCSBw++V49x7QMx/2qYjAhJVJt9aCreBInGPa9FMGfXQKHdkS25Xh7PxIhk4XPYstey8FqUtOyIacdEGpQnAuMvKGxyTsvf/SQiMXMSvSvAOk9x83aj9cwcJgfrAJFbsraQ57oaP8/rpvWWW2PZ6xokgTtbdZ6lEK3bp2LVX0Pugd',
            'ben@JDoe-LinuxBookAir-3.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAJhFwtno+J3dlFvOeA8qX71RVX9kFvD7zJepLBXOEM2uxkGkiPgipAr/sKriud0nccQkWx0TZ1SxF7lrSjrH0TzzYa27JlkltOXIPskVPdNyLhqesIt/XlbuWrRLRiO+qhGJDhFqxE1owSBfbc+hKFhDCw5RHx/FCCHztIglMs2PAAAAFQDD2AFU6Z1JBs0ZGWrLxNnxWHRcDQAAAIB2pCYum0XaVIwwtUTGfOQeoknEYJADtweZJsz/8rHJTvuNXsl/DUUN406bzQ3Pfkz9eFLplD2I0aFOD3ChPLEQ2DFQ84RUmaqtW137Rxe/uvLne9bNTQDEIqgLfXbpQL/eSTzjAiTWTVBb1dLbnUech4j5U4tiizu7dVxVzk3RgQAAAIEAhPjJoFSvY48+8Nbek8fyePz+TMwgZW+SR/ZwEms+rsmMSHFi0IyUdm+Qg3y5PHWnY7UZkgDIlIza+A7B66G5XEs1ovTHVO4XheqULYHnBV2WClo0clEaiK7N/pJDWfIJIqItZKWIDOCzbSNFD9XQn7qNvzEtKool8oRTMcvu4jY=',
            }
        }
    }

    class gmaxwell inherits baseaccount {
        $username = 'gmaxwell'
        $realname = 'Gregory Maxwell'
        $uid      = '1109'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'gmaxwell@gmaxlpt':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAP3J4fO4aWz5PA+fHzGKU/ZsqwItFRyH3hU3ahRtGWdAxWvwn/yyOyNs56VsPpmibLmugHqfrHIQFhv6wIiX6/U7Q03VV4WUd8fuXTYBrVPRAnIhQruQT8pGIljhWKSstYAdk2XvCzkIXrhrkzzxCQhdoPcqwPMvWpTWQvlQw7EVAAAAFQDrqUv2zfyMmx0KUy+kRphPx4JD+QAAAIAYeDr+bVOhJgrr7zcUpVdMMln+fZPwZZ+SIySzI2LbAcIchjJsvT5d9HMlFgFDJ5mYkydRosWdBQRSgJ6GcEeLjrhkNtG7HOTR/bR7zZuwQkr3qUqW+hi5Rm37ZB5S3uLUNl3OLNtdn4FT1lAkQWSuVBsPeTpDs90QNxSVfH1zzQAAAIAcRLEllDpoHzfTbeYbWsiQnb9CX2XNuhyilyqOo56lrEAca1sjXfgef4vECZpleznRU5OCMyrJvJiJyYr9K8AZ7q2x0NDdXImYaZ62luYHgqMccWHG9HIGiM0iDiyl1p9S5ceOk0wBLt2vHm/MzAFoUsH+OzjZ+vb6bMcbn831uQ==',
            }
        }
    }

    class preilly inherits baseaccount {
        $username = 'preilly'
        $realname = 'Patrick Reilly'
        $uid      = '570'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'preilly@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBANqUhyPERX9/5QZhAfj+4m8DqHGbnk56qMHGqTwKTfP1EoYq7tATVHx93CI2LkURbq8bVUcFFdfZfBwpKVGoFBiZBCW1lppDQFO+MD6lWABCjeWg5foC2X9yNoTMc7BEBgOWZcPSwj2EyYS9VeWko+GxvM1JAG3C5U5paWAGj0mrAAAAFQDt4i/pu61OEdyg685hHBqWkpvvYwAAAIBkUqw656A3EOSf4qjv6Ph9AlTzpLhglqzdwYbOZ0CdITnfSuZ0/lBmJjMg1Kyb28eGXCA8FSF/liz3dG0eDFKVPxsNFr2CiZs3IjVPVaZPwjnxvEMPRECj8bb8w2GqX+q3fXyPt9h+Y2Q+I/4ZjeGTnta+PIeSp8Vy58Xw+hN+6gAAAIB7hoyYs0F9vhMmydoXIFjxo8edMe33Sdx9uKWcycDvNiDuk5oQb1K0v8UNVvwNIV6jH2F4yXFVkV79Jk8FUqhzRs1gPGJQeR8Ve/qWFtJJqUyDYPWyRJTLG6ZY+KrIbSFec2T1V5NTy/jWz3TZobhd9PdxhWN3QIKFqX0kpxvnvQ==',
            }
        }
    }

    ##### BEGIN ANALYTICS INTERNS #####

    class shawn inherits baseaccount {
        $username = 'shawn'
        $realname = 'Shawn Walker'
        $uid      = '563'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'shawn@Eeyore.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAgEAuA2p4U/s9OEU6xnv8VO+SAYOu9A/udnQCFGRAKbJ+oNtBhlxEbQe18zJ657UdKm3gRcJ2gW/9MVkqasj3PagTYpw6ffrT39s6vneUYu8+IQP1RfWCaMIHOPa1BP/eF11bHUUSHsxFSISiTiC+0Wzg1ot/8K1Xz6C53NJj1dSt+ILZCI8e3St01tQ6AXGaG8QnYzRS9kDrB4AK+abTCYd3UJYaUnGsjceGRN0/R0z1cYpDSvXSvdJT4UVk92t4H4MhUvpQ18raxj4RuebxJIUkIJpNVCheAYlHp88F89Flo67iSscZZryOmXkgMRjkxkE9D8iKX5Wc8/w9ELXmWNGakQff/uN4ExhzlWudKAIywPFIEP9TyGVxxyPSkrQUc7R3EHDFYokqZrJ2YH/Nd+WsyOjXD1J+6nqM1CDxEICmIYDSI1lu3KyKasT3Z/HgB6svokazKw5MrEu4gwD+NwkM1OiLbz9a6k/IiIp11Q2syhKDRN7G1asvXgK1gwFJ+tNeoLMbjbdHd2TTBSKsvd6lqJbhIveqCAbUPlK3zZbvEKxPDuDFhQ+qSF+2vbtuS9LCX9QrdW8T6/VpSop6uyvGJkA1bQ0/tdMpP2eUVnML72BttT1VYdwLiUZk2/TrRtQ/6Ciw5DwrjVxg33D8pm9K/2jm7uESjIE1I9iALQTKhU=',
            }
        }
    }

    class halfak inherits baseaccount {
        $username = 'halfak'
        $realname = 'Aaron Halfaker'
        $uid      = '2041'
        $enabled  = true

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}
            ssh_authorized_key {
      #  these first two keys have been removed.
            'halfak':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAuTdhPxqwEA5HR+HSH7LlPpKdducUsHg5YfIAd2pISraE5vNSYmvMGQHTLdq01JIxZHwCsKZ3UjdE5mL8/IANXR3Azk6v/Uoz9N5pBvH07/o5ZzDfTI+ZzaJw3ejv2C7lUXfbCPP7J+6BITV/q1UluFwmSOnwtSQ91s9/iXGLb6LrKkfXOBUz1P/hY+kF/Iw3zykBCpVkqIlqo3wBJo7i2qwL/zOxrRTuqzUyfCy+x87qSp5e7KUP26b/xVc/9km8FWO9twDGU6BotoyxHWZIXRaIrHgz96CCtDFFn3+TCGy5LlHn24+UtBFZXPfH0VsM+L7ZF8k+HMWxR57M7IBwtw==',
            'halfak@graphite':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCqjDvky8+pqKrACjc1eZ3nLuAOa9pmwHBEk7EFqRVMSSy9IsaP7Q2RbblrcMFUJP0dCj+rDDu5Q4YKDYhN/x0Wr0vPdjQqrU2Ujx65EEeeYJQ4/InG1MgABoFOcm8TdCjkOFdvwD/JFzaNJ3YxMilv+xepqyGOTfTf+ThsXtGX6qGGWMZwfBmt7Z7oC/R/juaH49xHcFihzbh3DFdZLB2/VpyzIn55kvtqXFcw6SBppegu7bknnLMaXFi4edG/Jm1BjuFBnpHRVO1V91ou5tNNrMhTDGLGGyKgqmz/xYS70yPdy3nW8V3ygOdZWDmOCeWYMVGQE4pfSNA1vdsuV33r',
            # These are Aaron's key's now.
            # See:
            # - https://rt.wikimedia.org/Ticket/Display.html?id=5004
            # - https://rt.wikimedia.org/Ticket/Display.html?id=5026
            # - https://office.wikimedia.org/wiki/User:Ahalfaker
            'halfak@graphite2':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDI6xBPpUqjfZl0AkSgS4sMLqaLdaVIUzZdCmNvzw+TbITw6PWOtMAOnP5A8HOn7aqnSH0ZYYWN/AzMz+9zT6+5JvxOfY43pCmT6qJv3e6mtCkkdy79kCH+b8S9NtrhttxMt9iem2RP1sbJiXLfcinOHuezd2Q05BoY97Aoo8z2/tRRvkPnHA2QU3fxAMS/PBle1ZytN2XJtz565AS7vzrts0su/jTej1ikLNZtMITZIrgB4o9KVcF5FHsmTIBehVwOEQRNYc6AwK+GWDQ1ZDS9m07/VmSIAO8krFPJ8y1M/EvMSP/VR78ABXOYTNlgzTCSuLFjocFMARBOnpA5Nfg5',
            'halfak@halfak@tako-umh':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDUTJ/rlBnGfXU0Ybp1gjJNizb66gaRFPzq33ptdnCLSP8hWymFgpzmuNyUaBClWJwl9qxXIw0xZjHXyTcK7Dv8ajqatgeiY0ow1LoVfzFDtN3Y0dxFNKC5/bC6lk+VmBl7fmNk8+fx5Y2FF8LMPy+QceZU2CJOvJzEkjd1lJJTFnSSonRrMBzK2xhT1qG2PhlThWWhVklrEvO+wIdi9M2B+m4cjgzaLaK/UgeqhFWsTQd655tLb2trhNHj3I6Nn38l/b+TFKsYT1+x1QWt9IxrSgKcDc2oAj+HSrcHIaKIXLbMMDaFIzRpHGMxnSXpJvCDvSq9aKyfw9dsoqxuFLF9',
            'halfak@carbon':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCjS8cth/18dmTr37h0A+K1g82iVqfrQ5c98iLrtl/ejvkMNDvVSo1Kyho6sXhwCx7HsF5hF6Y+fVB5FaxugI6o3CeAt8PQBeOjOWOdCZCUudywwnNWQgLH1XejaAxV95VRZTeuzhTLMymZRojOm2Kbb2f89C3CDCPohlOqVKMRsa7vMA6mgHgJtOXjqdrn+Toj/oe3+ZLvTpFsD8ROTsppKo+ie8AvRRzaCobgHF31OrihlAxQlovAPH/3eH67NRlmwwJhkuGAIra7+ZCfJzNR/9RVoc6mZgRANDXASTsBuI7ZdUQjgRIHbdd+VkXlzR+jLQy940ukLT1IK5hH9IZd',
            }
        }
    }

    class dartar inherits baseaccount {
        $username = 'dartar'
        $realname = 'Dario Tarborelli'
        $uid      = '2117'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'dartar':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBALJJr2K8ifFwcRrJglPqJLClim5DL6zuGFST2rE4+PAEq5AuONZVznVgmBj9ve06h+86NjFy4WBaa6ncVXMblbAwlfEEIl1NxrNFXA9s5+Y/qtlnTqH4VylLiz1Fafqjt+YsTi5oUXJ9mR413PvANQ6hykwPEaAiUzHleTcsXXJZAAAAFQCbAsJaAgW2tf36oCgp4ysZ4FWHIQAAAIAQ0v4ATMrm9mfCe06tyQW/JJKiEVAjrpA9LujBx9HJIR+z55Ofa7ogmaFqRJcPZw6u9U4CnO6ch0iKJvhKo84TVIZnQ7wj+H6AfrXOYAKWUDqCpqswhMt8qOKekkTzZ2TPDoGdOuERzOXHqhcN2b2MUw3RyIKmvwP/h92SBWrVywAAAIAKN7Oyuu9a9cADbY1u62f1Lefxjbi7HJdxUrduI/ewUWjW9KIjQCPOuWBYLF7VtES+agvuo3A+OCHAJFluZp46L2Uv0UsdBxrOUeVu1xVP9iziUBjKqU8Sw3gWWu1Nl1qEQBCP9gTTrdMekgrmPCm4NHMYIItsbVZ/jrsret234w==',
            }
        }
    }

    class diederik inherits baseaccount {
        $username = 'diederik'
        $realname = 'Diederik van Liere'
        $uid      = '1293'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'diederik@Diederik-Van-Lieres-MacBook-Pro.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAgEAtpE5YKnKPgHmFG5a8x/1lfgRUIFhv8Vug/57XCMeuQMG8NNUuQAno1OWYT1ukla7DO/3KF+iWAkyLlUq3z+rO9WB8/BuxLOsNBd0dBF44yoVsjKkTCdkuhh/3a47uIGAKhGG5Cj+c1ggAnKGLMgfoaF2H5vifhSp0hJbRGMXxzC+OoVq0X34GnkEZK7YZAg2oYVOyLRbOYNDlXLdIUoQ0579/T8/ey8mZzbxuONZy7UuRiFxwOB3O88s5SBhGwKHR/3iJ63PE5KZ+OCBg6nTPM+4rYfQHIy8lwvna2OAgweoqQRmn1NFpZisqhWcAAABKTyJ6MYQu1J/6SdGI4QehWEinsPud/ZJ7EbrAWotLTnDaeQnPwdQnSNVTTm6FWKjkKAbzcIRpWqw32L5fMU/hwmJ9K2GQSYHxdiGIdlgXsI+Pel4dyhtbl/UT3Zj+BWg71rGF4SY7lHCfAm+3FbbBa4wHSQExa6k6cFUAv2mPnUuBeLKBPZnZc4kRBehiVV16ddiyYgDwhjO3s1CLcPLz4napVDviMj4QSC1Em1NsqKPNIwITC9rqFuxhjoT9Gz7FpA4OWkQaqECkO/L2NjP6vTlxfpof3tD9+aagCfI11JNNG06oFMjc+GhvObQmUA1ZtV4xNhYhFJDhvSmxNwF8Bux2dpPwaaemBZtgfUEszs=',
            }
        }
    }

    class declerambaul inherits baseaccount {
        $username = 'declerambaul'
        $realname = 'Fabian Kaelin'
        $uid      = '566'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'declerambaul_wiki':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA3aScUQs0HeQEp/pnMuJ6JKWTwEa8IPVKa7Gkrx2DJ3z1qUtA5wzxSG6m//MJBokIntwBAGuqRazAqs5cB3m4GVqViA1fabxZy55l1/GB+962/d8goVEbtkj/MO47vuUBosVSy5GGjGOs3hWtKId9q6+AU0OCNZwC3j12tXGIX3ztcf4Ef2pdBoCfJMgrvlnIpdFDBftrua9kVvYRQj6tVr5rTbFlEioNgNcdQXhvDP0sU81i1NG/nAeOZMDYOzUscDHa6JcCts3nRyqrqgaMixxGjF7WG42tqS+AEqKi9IOqFnaiHtwipZrnJJ8IxtDOve3HHA3VctBsh03qB4RZ6w==',
            }
        }
    }

    class whym inherits baseaccount {
        $username = 'whym'
        $realname = 'Yusuke Matsubara'
        $uid      = '567'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'whym-mediawiki':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAIEA1LYOpxAxnuIgjkZMkdimojSVWGRJtqbuxaiR4eHZhYOEJSz/UbDaDjb9ni7MIbyLMPdj4TfPzq3mJuSxPWVG0FNFi076zgEDKh7tOohFz3aFTq27/WZXZ7IZkmECA+SxdTOOxq9/sffKmzh4UiavWJLBUTznXufeo7P2LcH6BS8=',
            }
        }
    }

    class giovanni inherits baseaccount {
        $username = 'giovanni'
        $realname = 'Giovanni Luca Ciampaglia'
        $uid      = '568'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'giovanni@titanus.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAs/+a5RVrxt3LPd4+zr/xtMAQfm+HpYk6lOAhfG6JZB6NusRKOR6HFbzTKFQ7v9S676bLZXdD8Cu2tuVspegMdx+RGw4uNlISrxpyp5FXBiXpC10oRVlk5cMthhWp94JDuBFsVstuXR9FotRF3aScM1Hdv5cRFyXDvJTgprESXwFm0uH9MDi7xdJpTKYAV/8Q83IFKwz/6IUKEQ8cnBKfLY9wVIgoQd6I1eQ/4pVuoLcCUQIh/zreFMbfhyehArKVPeyOtgR4gRKZJxlQcVuvbzZFLexyHf9VZrO87IXf+LaSwvWVlBPGDD//8g0Kl7yVCgQHlLzbctB9fBZIk3FS8Q=='
            }
        }
    }

    class akhanna inherits baseaccount {
        $username = 'akhanna'
        $realname = 'Ayush Khanna'
        $uid      = '594'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'akhanna@administrators-MacBook-Pro-4.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAIfkh5UXiOWGbS5eKsLnedffXz7hyjqHqlkSoxy/f/7tCaZLWvK0zTVZBfBWBPR+8hxkTWGqm5R4Vs4DLpAzb6bXdkm1dJNq/eJmclKrFzbU3Vc9nl+XizgkpadsKbUGF+F9HywBebebBS3KZ4StTzXWMnR8a94F90R7SssntibrAAAAFQDbcWx2byNwngsa35OTUppudr3BCQAAAIBPpv7V0jd4V19fNx8zbKtvAAGFtVGtXhun/5Gk7SLThF+eSAA7zZ21rf1drlfBeW1k1dpGFdTzOaZETcpuhKjQhEZt3bs7wrb0VuSU03bCmEDklIbhj6N4zU41eF4mu8433RpAtk5Fzdh8IWl6BEN+LDSytF19DOwblm4h52+KEAAAAIAm/D3q7wcQUTnRbWZgwwFArkMaE/1IMh+5d2NwuFRNLj1lxnec8lUGX8V9c+gIxqCPMy/PQFFklmLLEec+47pIHtSxht3Gps72Y2WYCN+cR9EJpLoW+uFcjbWp7ljC/naTbwOXvMccaByT0baKMb+Ihgx0fStt5JYyw3TqaXHviQ==',
            }
        }
    }

    ##### END ANALYTICS INTERNS #####

    class jgreen inherits baseaccount {
        $username = 'jgreen'
        $realname = 'Jeff Green'
        $uid      = '2074'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key {
            'jgreen@thwibbith':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCjkTnfRGIhs0of/3Z9GhOEEavkzFFg87n9D5BqNJAKtRSy5uh87p3DEHWnYcA5Ak7TD66hWae/V2tyQTHVBcDfZhoSFKsIMmhC/ooDtN8iewl37Dbss+a7m4GT0BmILkgUC2IJnFDFz2Eb6RVsnD11ajfbO4buNfokJC7jMjxQ2btpR5FojWNX7xffw5yg4aGg+k9x+32bM8ZTEzyYUGpxUZxV9jmbK1uzTBfZSlgmfok3Hn+scki52DM7EPIU0pxf8cyPHPIc7WX/wR56GsILoFNMBkePP86O/ZDuhOSdsFMJaBmOHM+9qCMW6JPKOtogvEaglbgCRrTZ0VkJx2HX',
            'jgreen@spork':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAIEA0065bEe76amow8pXj+cS7rMHajCMfBCrUxOlijTgUv5o6e1v04hm7iEwxadcUbPrauGgsZOoeuoLzz3J/oS7qb1pliNKgdvcMw/sA+sqZoh2iIKjwLkEu49CJJ6Wxiolg+p3Y8yQHOUTc7sozkREkXsDyZZsNbmOcwtDlCe5SJc=',
            }
        }
    }
    class khorn inherits baseaccount {
        $username = 'khorn'
        $realname = 'Katie Horn'
        $uid = '2049'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'khorn@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCo0sPfXSU/XsJzevSa8p9rODZabOwVbv2zx0htASdEB++TaMk5k7s3rTznNjTzD8mgia9h9+Dl/9lUBnLeiWeEPDLYO+KiITs4pZ+akL/4ilWl+CJ+59C8Wm0apsezQwaMEuPGzdx+3MVrqwhRdl7Fg9DOMYIz1n5O2Jrr2QnD9TamWFw+yYhmZBkl/Ci9rbU/T72A1cL+D2UVFk08B+FH1d48XDMoaUppLbV29/fc0Fz4f0gZkLYBKmOo+xpZ8SXkVieP443a0uGyfy2FSljnqF42dP21XO2tqaAtf9q2i2sq8fnB072C7oIYleVKLfLvxk6C7mYvzTN8A3m4RCLJ',
            }
        }
    }

    class kaldari inherits baseaccount {
        $username = 'kaldari'
        $realname = 'Ryan Kaldari'
        $uid      = '1271'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'kaldari@Kaldaris-MacBook-Pro.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAnmxqe0czLnD+blnxcDNRsOF2MDhydEMtUqWwHytxJeU84YmUDRuqxsEhKCNRSxiZvSf8RrPfiO+OiF/nF7ECdFTvtihDEfV89J7oemACClmrjOD+r41CNYCFhpI+fZIUzNuenf2h5cMx2Oqg57i+uV5PPSNX0U2VOU4HUgKl4ymjRW2QGpvtNmtQflwhXPD/9ih7VqlcO1DEbEPj5+jN1LvY86roaW8JDz9dvV+zmoe6yNcHn68W5bG13qOkfW5BCnVxuofIwN0REvINFAOliHF7gErXjgBqJiDr8O1xopc67+9bHLaqBKa7ji3aJSmrOcVvRlr2o73M1hC+NoJ2MQ==',
            }
        }
    }

    class zexley inherits baseaccount {
        $username = 'zexley'
        $realname = 'Zack Exley'
        $uid      = '2045'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'zexley@mb.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAnxY39MUzzNTIfKkR20U/qTl3+ayt5RM3CwoQQKdFMLw6waL3GC7F7XjbY8EOFnm52eDyGWsfdoHfZSOYJADc+Qs/e8T2aqXHcKTYSo2Y8JZRw6qmzthvGJUIGfG/A7BrK3oj1nSwyp75EkU+qSCtnIUfYyg2hwiqNc+IHdRPxp/hJyl2oqrXTLk2+XpOrdWjPMhTPwjzj1i1ZV3HGM4xBTye1W1ZFTH/2SETlSTLRhoczahCKt9g0TdCxMBqNHVSRTmzZ8IcF//LEdQRYxfjyPQpjmcEotXvmB2dXoimq375IM4D/Ml50dCiH2a79vPee/BG2NV9FTlRfCvqOmQuDQ==',
            }
        }
    }

    class mhernandez inherits baseaccount {
        $username = 'mhernandez'
        $realname = 'Megan Hernandez'
        $uid      = '4990'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'mhernandez@Megan-Hernandezs-MacBook-Pro.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAxSYJETDFuNBcU0oB+FaZ3scf2rIe1WSm/LGXhjKeMMcSKCW6mLj6+TwtuX+35YF7mauso8XgbyVwAmD2xvbG4/sJo2i/5SErcgs8hk9VVjZTLOQR3gIHpZONzL1We+Gn1dEceQ7oT6NiEw5dR4w0rx8U3IsGETNnMI83xjpX/8pJcUnQZxjbFEeeAI9xY7+apnV1TPlAN7cHxzmL5J3ajfDPOZ45WWUTrmZS/B/Zd06t0t+hI6tnNJSmekWugh05BFJpmhd9e5j2sw7pv8yNZjTks2CnG86O8JaEY9ZlDEBXXCzx3mN19/r579LhvieHN6IhYOWwe17mj8hNwxcLPQ==',
            }
        }
    }

    class sara inherits baseaccount {
        $username = 'sara'
        $realname = 'Sara Smollett'
        $uid      = '584'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'sara@Sara-Smolletts-MacBook.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAJzkjaqCp+VxgB4f1TH8vwYAM5OMKH6LFH8wdW3byMQkAqVYjh3ynSEs/DIqtuHMLKqFxFmOAmBusWeBQ9p2dmbWPN39THRwtIiXRr1ELyxML6oY3NWDm7wWD4hWz0ZdsUT/6X6yzhrVbBStGlORdjBWiA/8gSiOrZHP1UJ2frPjAAAAFQD67sNxyBwcvH/EZKI2Wz2O/hcEfwAAAIEAiaDIoJnkKBMVmxJBqY/r6ko4fnSqqAlkam/41aiEs9OwmX5LPH1kkneUge+bfkX3pp86pKG5xWBw59qJsL4FRwQWtX8wsP6l9xJj7qr2Z7hCJnvrv3rM0mYpL7o/8BDhwauJJ68ObcK2t/2UMqnZ87jUHZBb/l1t3jInrLSJKYgAAACAZKIh1AGbUxixY/V9RdJnQ0/oWbF5PEa149sceIyB8q7LSixUkPi8cfVvOHKNqMwV4InBz2GZyANWRtHbk75UUuuJDklPyQsif58vokJIsVw733Msx49EVSEUVSl3ZQ7c9oLmsXp4UsGW6C9Hh/OwqZA3VrMT0zsZqZYJ6mmZ29M=',
            }
        }
    }

    class faidon inherits baseaccount {
        $username = 'faidon'
        $realname = 'Faidon Liambotis'
        $uid      = '2186'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'faidon@wmf':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC/m5mZhy2bpvmBNzaLLhlqhjLuuGd5vNGgAtRKmvfa+nbHi7upm8d/e1RoSGVueXSVdjcVYfqqfNnJQ9GIC9flhgVhTwz1zezCEWREqMQ3XuauqAr+Tb/031BtgLCHfTmUjdsDKTigwTMPOnRG+DNo+ZHyxfpTCP5Oy6TChcK6+Om247eiXEhHZNL8Sk0idSy2mSJxavzs25F/lsGjsl4YyVV3jNqgVqoz3Evl1VO0E3xlbOOeWeJnROq+g2JJqZfoCtdAYidtg8oJ6yBKJHoxynqI6EhBJtnwulIXGTZmdY2cMJwT2YpkqljQFBwtWIy/T+WNkZnLuJXT4DRlBb1F',
            }
        }
    }

    class andrew inherits baseaccount {
        $username = 'andrew'
        $realname = 'Andrew Bogott'
        $uid      = '2093'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'andrew@AndrewMacbook-5.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAvx17BMqWpcnI5aAl3tVAJ3WI8+geWfF0jTh+/U+kr8ls91tBk94sEJ7xI1T73JepuRlqsNRzzpZxxn0kipVnj7jxW3nbqIGmpXAfb/2W9Fnp65P2u+CKWd5tMwYU7Q/z9zEk4FLoLEVK7Ce1ia0xkbG7oeM7La7sATNl4mx3BZNPUiDCQvEOrePYFUdxP+wS4wsJbZ38RGil01lPFeLuF/3aG+j3xgttwO+WjJYGEAyddUSuK9aw6rBpLOFaMBZqU2U2hK2iIDN6EfiSOpdk7zeNNKOqHfcH5N/rRGBx1niHV3K71WsiAhYApZ8MBiK7iU56+/lahsarstDJ3GKZAQ==',
            'andrew@AndrewMacbook-6.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAo94dwMdsdm0Q39cGgGu+9Vq1ROf43/dym/0kWyzX5tT9SaPM3RjuHukiXRFgVtSW6SNyPTFxjU2dUoWeGrolNLZudHlCPLFTU1d5BIzLnDJmjcqgm76D2na4KrhnH8JZ24PM2iur08SnDr33AU/xETCVoG/7DcTXzeWxBnnMBUa9Lo55NALEN9v/rJbFa4/1ah4PzFUSxO+IWHl7bxFFWRBd2vErbVgYBbdmt9p8WePxZWHczkZ3oSM4s+/C1ydoXcpdV35f8/XcINsC28WLIqnyeZUCzgBli13/R6dB3Kk3xVqnFFQqATNYrs3MIj/vt2JBV7kZcKkmVm2d36KnHw==',
            }
        }
    }

    class raindrift inherits baseaccount {
        $username = 'raindrift'
        $realname = 'Ian Baker'
        $uid      = '593'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'ian@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAM3ttq0+aY9x/2rcqLwIVWo95Iy/4JD7c+GSsqtTlISCtkIkkv7HNzYUiwQqKBVn9DDTO7abdtqeyBmX5e0I938F2c/4mUUYYl/+q8dIiVUKgFIZ5v5T97TQHgUbNQ1N8E8G5Aw3308BCjD1NHzRSFD1VpekpvPMA3DHGrMlwZcRAAAAFQC0LNBLhS9UzgnCkZpw08m5Wm3OVQAAAIA0+93B5D6ShSg33pmTjKbheso7pm8dI5v99crl26QTR0H220tT8ytnJ8n0/xz23nCtelAGO3adI7+3nZS8iKq2d8QpwSqJZa2je47rJuZbxOAL6E+/65GHzXAPEhrhiWmj8mlE22nRRqX4EIspctUi3rNdtrIjMWkyKcF9C9/qaQAAAIB07g9z4M9/cJmFsOoXpvVTEd1XUFN66Eruqz5cMYg2Fpqi7MjkE6mB7IqVVcuxk+m62QpNWNHPPzGJRZg0TsYHIf5X/brv2QejfxFmPFppYfOfdv3d0NMBFEUiX8K/Fakxyfz8jerzLEIM95zQZExKoaJ6ZWMaxo62+YgmrwZXDg==',
            }
        }
    }

    class bsitu inherits baseaccount {
        $username = 'bsitu'
        $realname = 'Benny Situ'
        $uid      = '2100'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'bsitu@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAPwC55vAiGT1i/GtaqbDjrDv7eBRL85Zzl08k1ywpxwaJrmgfWuZvm7yjfP77jnMFETlo3FNzVPXklX/W7XZOay4wGEmoJxGZ3Xuz4PLDf9MOCxPb7WbkfDaBn11H6llT+nIGER9cmR4GUElFC/omTs5OQXxm2f0pbk1USFYBkD/AAAAFQC+VpAVk5vUqjcjkur5OzNjkMPRAQAAAIBTx1epSxl9tg94Gu4UGeTrzzPOr8ga+CJX+KGi0AjPzpnhUhKuW4hJYhABwItltAvLAT8JL1+jq27++1XggLgAm9uX71zgrv3AUbxIMAMqnBNyub2mNidWzRWtjQ3S/HPeYjIViswGIudxxnA4rvZ/gJjfGdCAjjB1IW5rZuF0HgAAAIBiZffGKUU/TE04J0QjYuCrPQojyvHniicVFVUgRmZedL8b76lkTPgLwQr2hOH6+CqXF5/lvAtuF45+MLVPIKxCax7n6UzeOecIaFHBvfHWXb3ghIL+jf+csDp3rsrD12VxCyK/K5eNr/6xlQPlWoB41z465doAYqkY37K+2We23w==',
            }
        }
    }

    class mmullie {
        # purge user mmullie, rename homedir to /home/mlitn
        user { 'mmullie':
            ensure => 'absent',
        }
        exec { '/bin/mv /home/mmullie /home/mlitn':
            onlyif => '/usr/bin/test -d /home/mmullie'
        }
    }

    class mlitn inherits baseaccount {
        $username = 'mlitn'
        $realname = 'Matthias Mullie'
        $uid      = '2269'

        # purge mmullie account so we can recreate as mlitn at same uid
        require accounts::mmullie

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'matthias@mullie.eu':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDEq/VIh0GiXv6PIUq45Lbk9jgOmkH9FRN53VGMJmaxyJV8fRpUpdB1rmdqqe9gs5heSyObP9Ci5fEL+8PbXsEygK7g+ZhoRP+XDJDMe1yjMOMgjNaN4pM5FJnqkFgXFPmhOvRizrT3SWenUDlGBhxufekTUVsl/zOF0R2g5jTWbFWPoa4P0c2aXeJgJH3s65Zd+NoWolVrPG8Q1LT2l7xwJdRaS3t4Mt8iusPx1e+Fvdvd5LuO56/zDPQl37ocMeax0lVMbKPbKymhezxotD29sez3sljrHiB8W4Q/oNC9d5jEyCegMYV5Wh+eUkqMIAZ21knjGmWrkB5xGRhsrOVl',
            }
        }
    }

    class maxsem inherits baseaccount {
        $username = 'maxsem'
        $realname = 'Max Semenik'
        $uid      = '1220'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'Max@NUXXUBB':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEApYlzRyFB5UNUnmCbN6sKPe53ZRd+P3NW64KmCj8MdcTsdBsOxhd00DBL7h1r3VUCYfkqnJuBgBfbqF0xFyv/Wx2fEUtZvneQEZUGIPciSkEwkh12VvNYeuTxWqW05B3eZYSnYzKwcziecf6/uFwRfMv4E5eTT91U22YYUzsgzVLVCDqtZWAESHqcZgfq5zxKoeO+PHIBUYYXNLz64Cs9UJNki8sbDX3sJMnRCebztEUjckUssN9K63KNXaQcXJ2GQJmqMG522+VkGMzbUV5yT4tjY8SCPNsPa3ij8af52HJNAz8IMfOvLak9ILxeDDugZJmSdBTEK2R6uCV2fo+vCw==',
            'maxsem-new':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA1G/hUlOQ7CwPRGYyTWSW9tK/jR0axw64JrRvdJnIZ+JTIpat3TyNPiPNIp5Ak+NfogruPJIwp//+f/Iu+DJW2iAcQhASl5WJPpSqdUUhX/LfaHB3Xr0f75Irn/7C2twvxKojyS4MkiBTo9HWSdh0zP3zgnwOlycwaUHujMVt6G35lkUzPgBx+QVKExK2A6c+CILjIG4GmeWPsqGJRJXbvrJjVK1og+i/x16boMdrO8UInNqH/iLroKT6tzLzJsWhk4NOqK2CX+MmcKJLbc2I0IQ8fJe9J2eaPiaE+CmdX0dc1+GP7IlI/CStk6LldVOgDBP/7Vr8DVd0OQuadhJJhw==',
            'maxsem@MacBook':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDSDnaVfOv5P06dwt53avUjqt1qN6XNZWkmCmEdOxnmE/l2HgsGe2r8SMZ0e6145/Ypqq7eUkAvoL0TvBS6Z0pXEdeOn7UC2X3EVaUnrcOMt9+J6HwnRnNaSLSSaxFAsmDoQiNwnkgtiXqgpvD6BBZ1C+0gSFwQii4hlL6TXLUmc4kMGjvM/BPiugzGuUA0oAxpJGB+GDj2qgtRePrtK4kpiBWOZNVuzGQUPFu4u9y3/P2twN4Kacvd2HlbHIiccUC/s+Ym5QhXErfZKFFNRmx/8H6maWpriImPbyKAm3rcKdLK3pZoGE4NzLSmOVtXJTSA74w3qR8m3l5XPDq8+0Hn',
            }
        }
    }

    class darrell inherits baseaccount {
        $username = 'darrell'
        $realname = 'Darrell Bishop (SwiftStack)'
        $uid      = '598'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'darrell@localhost':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAM82rXO0k53/D9xQs8e2keb8Gpyag2MsOMDFmwWJFevguUNYKsNp3n3GfWlUNax83H9mrfpUcWKD1NeZcly6g9EuYn1BxReSSUEegzIZ8+RNZBhs6mxvR2BFdYVQ5M0oD3WC3xQHtwzxkTq5e6gqHXrq7e2ybi2LHQ1ngspds/JVAAAAFQDDi/hw+MoP8Z7xiARtSBCuZW+l+wAAAIEAs5SZSr7ozKTP+CRW8pokc43HgBStPjhGgtYaGFHx61O0ACD4OnJMzeomtAImTNT3duYmqmeFVramta2cPqj9ET/d/Pk9po6X/SokV/klqUeB7UHJaU7DCs0n0N/ub832uUlY2LJ5rbMKMen/JD03ABYWklkOHuv5dEouAkPB9G0AAACBAKi0C6nho7YvcKQcDV0RANCnoFOLQCB7xUrRZ6hJtVg8AaBz2yGnafceb3dkbqR2h7xomjbjJjgFjug1S7VtiiiLbBKu5ikTUzaNAJqufumJu7IPAhD4V6BWl0oZ90pf9lNgYoQpYPPmwh0/MSQzxkwWvc9KA3eg8FnY1LOIW0aK',
            }
        }
    }

    class orion inherits baseaccount {
        $username = 'orion'
        $realname = 'Alpha Ori (SwiftStack)'
        $uid      = '599'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'orion.auld@gmail.com':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA6Yx97JRhDTfvqqPkdUu4V/ZR3HV/G/p2oZlcpqBcBennofWqVvvpNOBi1FLbLSuMeBipn33TdQDqijCN/G61oTzk6JwtkGiBTf7x76AqMIa64GqznopsbRYPHjDu9u0cF9EUdY13/gaXJ8whW4KgL34hXRoY9StZdxbot6DLsKWbIrM3hF4bLQEMltFgJe5Pdq+B9eFtdHkZbdjtYmhfAmHp5r74P/bfCkziiNZ5GNLbuOcqUnJgKEzqewDViQmJ9WYDcYaPVWqD8fR7ueFW3m4UqT9KZ1IJGBGlPdTLNvUyHF9T64H5uicI/J13jedlYo8+fM6hixcP7SSsb3cDdQ==',
            }
        }
    }

    class smerritt inherits baseaccount {
        $username = 'smerritt'
        $realname = 'Samuel Merritt (SwiftStack)'
        $uid      = '600'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'sam@torgobook':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQC9uJEKclnZ5I4Ghnms5jJmDDbwYFt3tMA5kBD1vXElvk1CGp8zKYBSGSURRH/Gi3JJG+tMh8HlrSOCJksAeqBpwz8eGK0CO0wf7S9r3oIvwuhWKjk19lA+2YakHKoVg0kIoD29AbJItEjxreRtWc253Zax+nGXT59e9+hCSwOEwxMPb90WES4VB0NzWGeO4J8wII5KGLeIlVPEtorbZMKVbDx1EchZyHayFAJNBl1e0jieFxjaKapAttyO4HNb5F/2J36dVhCANtMCCnA3+94YeHvIwAadDRJ2g4GsMTGZkHX/B+oneDfQ99bru6H+e0ETKcOq4Gx65AiWLdEn5rR1FvcpecADREORbnEu37k9hnMCUO9RXiUwygdy7LMSe7ivu5lW5Ld5ozYNMw9eCDQZmCTbHPRE2d5oVGZeubZ5uImd3G7kblqY301lH54zNOD4o+91YxqUzl06cfo/W6mfhEJGRsAKBFrp7hWiUm+3SQsEhYtDSZWbh4IeYqs9+wzLqC/KbYiufj674qZM10DBbBCA9rpV5IfiqtNrwxnA++MvlMhUtAczeNrqq/xLI3rBtuFk4XawtzQuXzcpeKX/NU/RplwUV/zSc72bLCLcCMQujFE1VHP1EfCUbXNv7m04/P4W8ZpWb4EoniASDkRf8sTbxu98waHgV+OS3+1qMQ==',
            }
        }
    }

    class jmorgan inherits baseaccount {
        $username = 'jmorgan'
        $realname = 'Jonathan Morgan'
        $uid      = '2402'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'jmorgan@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBANmrKxA/ZR4cjUHMn5FAHjN7cwq6fofqiDt4rgkJjORxYlTt2oBUKojbIMtJJsqzekzZMjU3tkvSOOZ/RUUH5zyZDf/pEprnqiHrrfA5qOl/+1xGSTDkHuGNgvVNdqe1NxyEimxc6eZHBuzmUiF7GX2pOUkgUlTeEhsWnhlv/6qLAAAAFQD7pdZrxClfQt0pV/qgmuHPepZf6wAAAIEAhQDoc0cOqXqwNuvkvOO4FnwlLdiAntMqfP7+GuBaTmXphLmMnynBHGu2+iTAMVs9QyejlBVZX7YshD6HY6c+HErOol36oa4e6y/RZpYDaBeHWq+8y0Wob6czYoY22ycDPEgLFZrYpKJlqiG69t4LuuB3SrKr9n7L+m/ktcJ8+pgAAACABI/xfnabsoHbsIwuynu7VwU4PGcMR6SqCYrQma9F9oJtA89P487HDPM42cAzff0xPzjN5NhBNAF4mibDz1KI+elW5ruYU2nEvtEmrL9xl5vGOjjeXM6ecOo4BbIxa1rUU64LCYUS+UvoNNxGu6Xs4oWIltti9+IXLTNHj4hSztI=',
            }
        }
    }

    class erosen inherits baseaccount {
        $username = 'erosen'
        $realname = 'Evan Rosen'
        $uid      = '602'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'erosen@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDGV+SyDPodS8lRJBv/JndZJ7pbM3mlqMN2bbE8ABUj5P5YYOiJDoLjPr8hczeYt1qMhbepp89nLSqUD8BgoJVNoiUokmi4lKK0PnPhqGVN+RFnamlHCibAPjbEBWaBWEl0u/9EtU4S0r7uQaKEnNJwcr7/8lu4KzDznViUVACGDdGpyRLZ388Phu93HOK2KPXtyxZPlwjW6wKIN3nyhew0X7LxzYF8rINl3Nf4lUF1fnK2NbfEq3S0bQfVcyWwRrgMUMA+w0plJQpHdLr+agvZo/SdtFrNFugQrMk1d+FNzEFnoDshwHfcmwjSaU+M8ZdbS+jq97X8HoL22yXFyD/B',
            }
        }
    }

    class john inherits baseaccount {
        $username = 'john'
        $realname = 'John Dickinson (SwiftStack)'
        $uid      = '2400'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'john@triton.local':
                    ensure => 'present',
                    user   => $username,
                    type   => 'ssh-rsa',
                    key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCwhOmG/MCs3r7qQs+rDWDOiOnk81zyGKQayfhRIrL2e+WKg5emGblBKMhAao992PK8DTImhKD/6RR4FAOYjjFhl5j/KOWPleExE1cjX+2GhUWRQSPBlwn2bHHjCD6BsmdJANxBIB70NV3r0rj7+rC5AX+EgKLO78rsgWMBYoKXBkSgssmJOZRGKrYzDqxMrP5q6hnaqD9J9aODX4JbrC4UAFwi0LcksGe6AU7kpDrgpuw4Bd/4f6PRGgUHSmo1SXtZwSzIIyMH6thhdWd/uxTfvktB/LzwaaJAGbW5L/oADeSOMHF/1xiqQX8qfoYA5wmnVFhUnTM265xr4Si7g3xf',
            }
        }
    }


    # Disabled as part of rename to 'ori'.
    class olivneh inherits baseaccount {
        $username    = 'olivneh'
        $realname    = 'Ori Livneh (disabled)'
        $uid         = '604'
        $enabled     = false
        $manage_home = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }
        ssh_authorized_key { 'ori@wmf.prod':
            ensure  => 'absent',
            user    => $username,
            type    => 'ssh-rsa',
            key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCxJRZZM8H1g9SfP0pvE3SJZN3zSV4ULDMHr4sEKTYTsIeOZObG99EcauqaaDi8XBBYhvEuAkhL9xTtrG/dWTPXINEAxXl4dmHn4AEg5ycdSj0kvJHK1tbDzCbHNVzJw+3GFcoYKlzRo4qwNHXe6j0pmuX21uh+MRMiCBlrZv6ir3U/guv37Fy3Ng7AOBSC+NSSb3O8Umhb5XVGHr4wh1C28pPx9+CDhwt54ZGwTRbL4UIQ1IPYhiNbI+niK8etXKNXPS2Um6j17SNrAI903+lb2tM2CTWwj3877FvyxZFOfvZovp9uR3kIwIMM5/PyDSy9YvnHMH/O9SWEqEI/aQjR',
            require => Unixaccount[$realname],
        }
    }

    class mwalker inherits baseaccount {
        $username = 'mwalker'
        $realname = 'Matt Walker'
        $uid      = '2454'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'mwalker@mwalker-t420s':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDs1a/cRZMNw1DerltODiEFOWoCM1YJpPcdYDFnEIEvl9dz3X68nBnfHMfAWbQcOxD3f8tCTjrQ4i4M079kawGkm+jEc7priWm5Ww6TFeyA7B2jTuPqRHWfJ6AsPvXnrvJF/RMuG6NwdOluunipbb0sbHpPreBMYwu6KifvEnQNLYDp6Y0c31PYC22Nr7jZTcCkr7P72t0yhxpuDUV4p7vhEsTKAI59wHSdM17ViJRU4DwDIs43ZBKulCwjuiwJ47oc903c4iVeA37D2jV6nrNbao4huJRyrApfpTYm6RwCnKkOOCBNSB4MndZikSpYXGjNgUHWJxj7vquumje4AsGb',
            }
        }
    }

    class haithams inherits baseaccount {
        $username = 'haithams'
        $realname = 'Haitham Shammaa'
        $uid      = '5001'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key  {
            'haitham':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAIEAzIL4+oaq/jC6cUsF/Pd9xwOJQLOXLrhPs825Z5sdlK8jM3rfkKNGiVhvDu8sv2FEjDnOFcaTUrPnsA7QFUM+QkO9U3XfIxnn/CHgXUwUCAvX1/GOuM2bMGKNrzNa+R5qOYYAYE1I0MalQCH2jfdsbe9hEKxS3IygzzmQEsbvMvE=',
            'hshammaa@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCxKhgMrYubz2ciXFpB6F8jRVl9ChDPjXF0kISApj9DGvISJHPSm9vKTNxylGGf22dTPjBoBn9l9UzetJagP0qHcG3BbdjIl3xSpnq6grQ/HOqqHUqrqSJDD+aYHLlgMy3P6GeoOlW2oclRBaLpwONNzW+yDL6lnBA1LkyZ1+tq/Y9PEhrRQTdgZvQ0U+oz2M0me0UIfOJa+R2xTnlwFr8qez4ZCSWJtLyPKcZhRDZLTayRta5nh13bJaeCClf1ssXK9duAVSIMZ4+AF4/zt8OD0EpQikzOed3sXBlN0bV7ZcxAyCxcSSmFJ5zmROCZ7eazNZd5jUw45y5gcSWWpdEL',
            }
        }
    }

    class spage inherits baseaccount {
        $username = 'spage'
        $realname = 'S Page'
        $uid      = '2479'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'spage@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQColhx7+65SMkm4j4iPu2WmHoeO3TpC5Iabvr5neBmqQbSQB0PE7AImy1p3+Sd5e8Seqdi0QIPyu2Jw3NqlOibn81snUExcRBaV8cKvN+c6oBJWVL/OILopKNS1MZynNPVOSjVzmpLNID5U3slEpopyS3aNMhI0BD93QAq0xE3/5kaFf19mkOEjJbaUcEevWTwI95NQKVovJ3y1R5v8e+GaFk86F+EJ4i99GZ+TzmN3VFMy5HfnjMOVGcR+WYyZ87Oa2CTdF1lbV6W9EwZD3eTbuDPZH1VW215Spw8MpFPQznJSkDLhwrg6GH14XuDOA9edf+npYsnYgnWUWF/k1syDlZgQvK3xp9or9Ld4fumAw7a2lQijbrP1SBn14H6tSBK4XGN5ciKPbfj9c9z3C0WVjXZsaQn1hmF1kWu4Kdnx7uYh3RlFnImpvGSRESHN/xuqhdF6o8/KiF7ByDion6ac5VKX40PplUFindsDiJ5GPnsbQWZ+0FbRcMCjE37t5P5NRR/Vfhr0X6fJHqlw1DXGciURVsCXF1E645ZqGZ2jC3PjgxgEVnGgSoaYWoWcX3vpwBIz5syglOgq7k1VDA3F0zitcIkem5uRFlwWgDo/y9DdIW4HNb9cVgMN2dZYQRlNnvKudLni3mjk+R8nie5C13lNHfgz7HMFwufrcxaMkQ==',
            }
        }
    }

    class maryana inherits baseaccount {
        $username = 'maryana'
        $realname = 'Maryana Pinchuk'
        $uid      = '2515'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'mpinchuk@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCzAIOjRumh6RQKFOkab+4Yjw7Vr4fFyKoufw1h5grtjsq0ruuqgf7IiBlFA1eJ/DXVYax1YVGGJw5LhyZ1XABxXU9LaBfTb7zYC/XUM8rrAyu3N6MoycjY011yhesNa7s8PF0EkN+tOVBSG27cFoOATv6qM/vPEdc69gLb8HlVZyPB6TQuzJLJzRNBNe7UscIIw8eTwd9DDUuaTsColByNPzUaDdd8BS4Lr+vQlg0CzNGeTShkgcK3iRLYfKD0Cd+k3PN25pI3tYzybfrwDCi4WEQHHOO7TvWudkdywMu9GN3QylRT/E5JpYl37r9gS7mC5p5Hzi7II0ujDHFyfmIl',
            }
        }
    }


    # Dan Andreescu's user 'dandreescu' user has been disabled
    # in favor of his 'milimetric' user.  He is milimetric in LDAP,
    # so this will simplify many things.
    class dandreescu inherits baseaccount {
        $username = 'dandreescu'
        $realname = 'Dan Andreescu (disabled)'
        $uid      = '610'
        $enabled  = false

        # I don't want dandreescu's home directory to be deleted.
        # Setting $manage_home to false manually and also manually
        # ensuring that the ssh key is absent for the dandreescu user.
        $manage_home = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }

        ssh_authorized_key { 'dan@DAndreescu-ThinkPad-T420s (disabled)':
                ensure  => 'absent',
                user    => $username,
                type    => 'ssh-rsa',
                key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDAOgZWjHAoVJF6hJCrDUjVuiZiNeW1GudEfkFJS4ORo+WpVaMjwrILGThrriIYZNEIQNEf4l+7ht2l7/9g7e0j56NxXX3NJftJWRKOk1d7s57CKZAdvcbQ4G+L/Tyed+qZj9JurHdMstcVo50nd6S/UvbvDAdieXHemhZLtFcqPBQj66XDJkGzm0U9eW49lB1qCzcQnsNQbxRbV39RsSgIU9YHeGWMsglI227nZX6Lvd6/Vvz2VsFR5xtdPBHQ170XqbRylZQaBaR1lmRz9Aa7dSKSbNgGYAUNkzijILhBccJK1Iulmh/yDFPm6ZVWFaezinbCspXnvCIdJfG9EoLx',
                require => Unixaccount[$realname],
        }
    }

    class howief inherits baseaccount {
        $username = 'howief'
        $realname = 'Howie Fung'
        $uid      = '611'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'howiefung@Macintosh.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC6xDAibCed4gMnNdknhU3v+f/82vyi+UcUL8fgsLqs9ADyVP5tjB86kKS5HV1RbA7A7RbE+DBJY/Y/hpjmtrnoYjxAXG1u75PMYiiEO5cNoXu45HBqKKnlEeqOTDhKkN65WtSeBzBQu092vXpMyTMMfKrtp0cnLxZz3Z9nNCmYv8pETaDEVVnJqAgfxn3XORowtiYgBCjskDV0oqUbqXwnxHeua1a2OLQk78QySWxJhFN+lvbqtnH8RWIH/YZJolrGHaLS1PEAhsc8rS1giJVcXsSccGbrMNAoCHNDJOXWNjjLAeHomX55vqkxxjmoiuEy3B0ykUmFO4objzNibUa9',
            }
        }
    }

    class spetrea inherits baseaccount {
        $username = 'spetrea'
        $realname = 'Stefan Petrea'
        $uid      = '612'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'user@garage':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCle8Z4m/zR8MFkJ+4agjsWp/gFGXcvsweraTxrZwUxqU2q6NPcP3PzPUgUnOG6hF/KqfLt0eFor8DEHhoiaxrylKBQNx4cQkHRoCj2V9X5IOsLWV3jEIaaN+C4a9xT5WH10wiGSxDq8BvNWBEPESkC68TSjdfGtsdrvrtignbDM/GWhYFPYYYNbNJg3xAKWq/kdQuIvjDVBe9LVmPPl5VoeyahhEGdRzP46d7fpVXwXOCUlObxGW5lLqhS95acBVfIF5sIvHJms3rn8IQRnOm++l65EY+qMmpSqCzwUQDOoZ5pmpMU9O38sGz6Hw4+2p74cP0Vd9EJ6MmX8EA+yNxj',
            'user@user-Inspiron-3520':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCrncifKm+V2aAJz01GND6wJJ2nUaGy7Z+uV6yVT+QNqf2KaoANs93RL/e9YQce3WuMakOiJNBtV55bgZg96hdtLvnEtiNB/fpF2Ft8pspwozL0nNVG6GT/S461Xh1Uwbe8Q+6yBW2zdaG17rj0AvHB07AmLe/od8wd1qA1wlTU44400e6wgQ2W9BqVl70VI5n03xKZstsy1IlPEP/uxQQos7bhaU+VQKNrkO5oRWTSu7WX8d2L7dbL2SWmzIMOYbhLux55Cf70uwR4fvlGlDi9QenqiDce2Fzq2nklo5L8Maz7kCWHqGF4ux1XMlenIyVdDzS+hXvISMTHDvChqVLJ',
            'stefan.petrea@gmail.com':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAAIAQC6GBl+1b22N0OB1e6R3SHPX5CgmMgZOQga++d0Gp6QUkoZpJGjFaDoVW7UPjLDXaJzLNWq+L2AzPaD+gbgxjrRvQT3U+0DP2m4HOX6ku0nLvx3j3cz1seK9hiCBZe/EI3bwH/UMpJjK1tuqSP7Nzs1okEHbLtSzv6fpLtN5Hofhk6z0fZcQyHr530y4CSmiro+UFI6VSPn1bdLHyRSuGaUp0QiZifIc/zb+Xi7hIBMNFFMeap2jSPsEpzc1Yx7xKm5NCKXBdgAqMgTZQnJ/zKGE109Ji/0AaJKkJdRKuhiPbpPWLB6jX54T+sTKh9oHQr7QrzHrdPx57/3EQrAA7ifGYcPK3CN8Hs9WZuu9c6ULU8zz9bnzv31bGz2mloNCdfX0ZDtaNrV+gUJslmc6C0+8UC+Zq1lqJy0XgIDWc7bmeXidVJnBG/JQ6kvEiCMks6tPsLQGUxjEeLEH3ydhoDQSEviOKfHGduVaPg0B2IATsdZi/VdvoPT7KPXBPoMm05I3O7o5IzYW3LqDXgGSZmWgM2qgvvobI7U9iOOS7Cz3bKCrWJn1FrIPF3uxauGbIQv+g+39EOBZyHJxlTrmHJLtoZDNm5nEYRB8ntWAdEf60xcHTle6yMdY9MPWGh7qnhPQRaVE8DZ+taGpJxfWWTDoOtpSx8Js+CaueIMt/TcANwVdtG/FQAJK7BiOhSOyUi+rErompZSMWLxr3deQNLqiGjnMQvzHQ0Il51qe8l95tpoQanfy0GUsNZ36zZg3xpRw7JE11qdrlPFvRo1TTx+E0ktqaBVe/Alc1JuLa2ZviF1vu1Pww5AXbyykN8kIDYsn5/O7Ek340PFHKM+0fkGmlalltvvca1nuKOUV41CGeM8YW7UJ9B1hkfvhV9InjRXiSB/rhr6uRqToce9WOsXlKN0Kn6UePP6kWMCdKteajCKjdbU+pdCyNAcJHYV708mrj6Vu+ujRH7D+ugl1CtmHIjS11TwrGSwc5Th0tOFFhNWahJYtyrKJ7X8yg+BLpWJQUnp2xY9B6R8BFG94USb5IzUWDjzg8bJGydymePonMCVauW7EZNU8I47iWdaSzgZeT5pVxaRS3SEr9Zxx3QWSAU8g4+8uzmr1HvxuDeiOJmoliuuuOeTpvRj7JaU1u9AqLg+uqQ/UuSPZZCuClIBjS9XzAlHo0JG12bCXG4Jspgd63o0msvqi440sqTnWJifHMtnI75BnDihND7dnn62bPKrX/FKuIVPEsJTpQTU8DYTAr87erbHsnzqtSWKzg8G3TQd/E6/Mgw02FxWEFTxEM9WrGYdIvkDanhn541hGdZv2jRX0RBhRZwYu32Qrp791wBNzSWljO2g2O+IEx5vsaWJix/tqPx7P6ByJQmq8s/oXqqFHqhq37gMmEU1IZ7j/EsrJXytDCcGPJOeH2OYJ2RNdygqPzf3O9+6D5HiSwFhUn5wlYCl3Vt0vyuxTlrH18Dm/BC4s3RIhjgYIiZuSD2lyTriM6AzdM1ioQ+jwXGf5vpS8Ngmacx7OsgOWE6KwtXCUlxx3X248y6a52QPGvRaMXGuZtX9z0Pi5K94Yldpvnin0MH7eovrgvjnC3bxy3CrTH9N2tsP+y7TlVmqGwDZRa7kAkNeZKPs0A/ujUVh7z+Of/xhcMjyywQbBESt8qiGaJ2Q3+8FX6wimxknFQVuF7on2MBSccy0Mo1Dqv0Be9iwfZccLOwvsi/1c1kW7KRNYHfxA/Y6MB1rW6wVk59vqAMCUksV9rtlwnNpVlzL3GaVgNZxtFOTfdmFmsOMfSUWEs2eVHae98JRt44wLahqs8bq+xkY1dU5x4gdpC/YugmhdShp7We+3TMSLlO1Yetp6W5iaiK+A1FP0YfYhgoJRtRyMd7wqxlSPR9dtuc4ekQgFUBVps5pAp0XzD9jTHCp6XLPzWfkhnZAGcSUMct6klndmeUPUpqmEwMjUY3PEKTqtIGBGJ+3n+ANkffYDnAImRaPJAfudG819+MHCnpkXyzCq5LmOdWQRTgbEa1H26tP25WUJJ/2B7bqAiHKRtB1Sut6P0PgEBWg7HKa6QJ8kBYWs1Lh2o5V4Cj4GPCPv417eDOntzll2zQeDOE3NbUBlQLb+vjvO2rOCU7uBqlvh2G3Z+LRGEbbn1u62ulFreYhEtPYsX3U+C6Nmvk6kDnRW5g7y1xIjr9qJx69K9ovTw7xKW5ilR6eCqi44pmmgMw8nRyyai/M5pzkJhMX19H2RaseWaW675HnKTWu2k+OPLWjaKlRZNERBU6WRaIw/Vdc7dNKHCDlJifftaV+HIp2/UoJo6bpeJIrU4RBSSKdbjJuh3NV0jtOKFPpHM31Py6vOSV5CpntQl+P/8okmoI66zsMS5V8YfXcHgP21Khwf9UkI4cnE0H594XlC8G/NoC45l/RTyfpc+3yFZwcLpEuK3OVQL+CsUHDBuCAuVJ0fWJ6RA+SLRdxXeHCqKmdnqemhC5mhGq3a0BFHNjdNNJfh8ltH/+DUKCU50GBxvp4Xsj4tZFeZp/e88zYKIzuULMUN3Ikfw29HNQRtnZ8UIMcdQlnto6FmOHnGVFmTiR/LZmLMTHOtnwTrBv8HtPV1xLwOBRzZbt57XqHNh8ZpfpOgl+RNGBIkyPwKrgml1TZA1RFbpaBYXXzAkJi6qOqRTD6jbYiRL1iObQA9uBGfWjgv9sv/qKmntUoeY6MAbC/G+ukF4PSlONMJ6yQfw==',
            'stefan.petrea@gmail.com-new':
                ensure => 'absent', # removed pending post-contract NDA, see RT 7203
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDFVkcUBti1RKTP4stJzfOVsDAv8xYInFXZeue3cwVCgvh0s0dWcg1tmLiCGpQvtO9XuFw/I6UpIfrUCE3iwem/VhXbCrHyF4ZQ+WSb30qIo2mEaK2+mVwd6fIBmLx9ZCWB9Fer5/aEp6fpLgKp+dHA8W+zOEqsWXnDdssfI/fb0Rjmf3UIYuaSeSrltgfluJCTZBtIG9cSrl4uUdJUsiDGPsFMgdXS2UD4HjSD2YqRZp5NTxCCwwf1jG5r5jGjequagyKAM/01iL+TPAX4kTx+i0fX4e8W8Kpy/Dv23t9bF3RX9K1RjfzqXyHom3uQuR1IXlnt6KkmTHzMKmXqj3aHMIOypn7M0X0TTO80WeoJ7oW3kCX3P2f9L2lIvPi2hbuAdd0f77LFTERgFW8JNoc9y7lJDPF06CnU8a3BRRbL/9pNj/NdiW1Z8SXUOTEJstsI3tXf83q6mZ32ZlDfm3yn+INexOCMTG0n28wlovFpGYRoAQECqhw3y8P9FU6LpdcmJzgfdw8V4WXIQ6fCk9UzRCh+h3cey3W5wJz8upNWXP9ZSFtffjR6l8Q+gMJ6Acf9uYQkYMn8W3NdpLEJwcQAN28ODYb5p6iqw6T/Q+4FTl1TQR8pJofDYLnQ7fwlrTXD4o8oKqqnzAs0Xp2vo0XXujw6pgtUWUvN8q6VSRcn/w==',
            }
        }
    }

    class pcoombe inherits baseaccount {
        $username = 'pcoombe'
        $realname = 'Peter Coombe'
        $uid      = '3428'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'pcoombe@rsa-key-20121022':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAIB6yfQHRmMOTJUnS1mcS9VLCw+aLgT4z3eNx+tnj43+PtrS38s4S+7P7HcryL6dSh8yF+Nme4tb+57WaxnjPZbJBVrR72BOXfGv/Lje05ZV5if1JSk5PenuMSMpu9VmMl+HeJaqDmY/gW579n5eaLwQSTbThFu2dfCobWtRicFTaw==',
            }
        }
    }

    class awight inherits baseaccount {
        $username = 'awight'
        $realname = 'Adam Wight'
        $uid      = '4974'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'adamw@sting':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCTng4vgEtyrjtl3JDNv1Q6M1PVvHWIomE17fqODCvFx6eClupAmY1XExdj3x6sPBtZd2ZStwH0IopkKgF6172b+0fl/ReMUq9gOiywKMOc8/wf/fYuWTI2TSR8MfdYrkq6k4rkn/6WMUayHcHrYl610Wi77WJ5a6PF83QRo1D3VAy69Z8PA+P73tTur846iOgfuDBfKw8aTb6mvwnq3hELuuYFaj8cVkveqEi9m2TYDZF/TWvLRbNTQvh9MloTjpOYhtyNYqeWj4xxjVWlr++RPeFa92TeePzKag87O+k/g74tUSfTqrqjhGGK615JPHVWNWMmNUHeFcajltKAf67N',
            'adamw@lytho':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDCVYUIFsCWN5odLFNGGMUJ/dgC2BB/EJ14srHC61BIWouLlahZdCOT5F2Zeuhs+aTigaTWtaFrYAOIfiChcPNSffVEMI+RTbMSZ9gXJxY294aDVe3xdd+XAZUVY0VKyPwIQbrNgTHDyKRbi5w+YmA26H02FjtcPrbYYojYI3uxNoLc/6cVJRBaKu1L+ZHqbZn4JesNlFUeEDo5Urv5TEI9K7qlfXbCdT/CMg6j9GyKlolJbAReay8+nUL4WwUMDmocy+mT1rWc+O2E7VfJw41A6GxM+TUVK+WP7dvzlHXDlatXy4PR7RvoUlxtZKjb7phSPOXvJjv5Gt6mrl6/qrwH',
            }
        }
    }

    # RT 4106
    class abartov inherits baseaccount {
        $username = 'abartov'
        $realname = 'Asaf Bartov'
        $uid      = '2176'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'abartov@ABartov-XPS':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDBFQ01XCX+xrAU7eKmu9Lrc7g3Ut6zYJx+q2JT3ebkRENcRhRvwrhh95qaJl3TvDne0WZ5sFre9XPxyrLKnCOszvUNUcg1x3htVJvavtiD4DdFtm8P711Cm2B8BhW+fUMT/MyvgmA+4VD2HRhMn9EXajJkrud9xWGouAMqUtkhcTblzJEclkPn4oXWxT6a0pXpr8eNxreO71Vf0948MlWuCnIv82A5OBPmWBX84e6eD24ZYYCko4uutBm+UEj+H0F0m8bHXc2wpt2ksJHgZZKM23fhFw6Glz0hjNRVy4bWvfG9eRc6lnkZdZQZXAl73N3GvjBbViG6YK+NTBiKe4wF',
            }
        }
    }

    # RT 4106
    class ironholds inherits baseaccount {
        $username = 'ironholds'
        $realname = 'Oliver Keyes'
        $uid      = '5004'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'okeyes@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAIBqzD79g6nyNeJwvBGQdhC2mILwhaoJ9yaf/ysk9LOzrfjIvo3zSpWwr3JT/qLh9/5cDGNOFqXPlbUL4V0lyMlKhDRTrHtsJJLoMUrmvsUo5aLG0Aum5TJ25jJ3v/av5wSGX5tOtQJgemPh0K4pD5iR3PSGUcFEHUOdhFwdrWT38Q==',
            'ironholds@spektor':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQC0D2VQbDTHgWoH5NM/QpLjpm0JfxXobf1CjRJemla/Vik/SPwbaJntnL28C0yFiATX62tea3vnuOQk5ZHTK40199qMZhvEU2rGgONZFKTdPzk1uDMyuXgV6j8z22Xkxacr9kGozgQgb+ibGYuaho+KGW/Ed926PNWHDAsYBLzgS4gqNKLW+Jyt5Rh5ZgxsKvjHfopa37RifPznW0m92evRmsG5j++tYZublWcLs18ZGeqelsP3iyy6PS5K0zAlfsiTH+Q8htotUAr33tpmKH+DGw5fNXTKFvbZ9YIKOH2l///3hIVhVRvg1I4BhO1IHAHKr0RISuxEdQ3QiujrXvI3Ss8OvhBn1eKervysObbJuuUyFYel7IGIu75vVpYbzlwlQSfd4p42PWR5a5lFC72BI65k1VN2dDdXanJor6keU7562smwh2/9yAL12igmRLgTZ9DOvuHNc9qNezJXP0JY7Cye5ByLgopiD7cqYg9Rw1avcEbH9uEJgD3d/lT4KG/QpE+ejUMm8N5LH9PSxc6h9ywtliNXrnqWwej/9CBp4KoXQDV9hB0F2pYppn9p1oqhjQPzb+w8G3F0Liaikvw30+cWCknQXpfPQNvKg3Ejb66crkLc5br6GfDhnFl4CagMRIsaxxyKLQFko3egYPszu7dgdTfJcDFJkd1j20z+KQ==',
            }
        }
    }

    # RT 4106
    class jdlrobson inherits baseaccount {
        $username = 'jdlrobson'
        $realname = 'Jon Robson'
        $uid      = '2155'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'jdlrobson@gmail.com':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDD0Dxmydx5Ep7f892alwpB7YZ2684vWPBfRFubxwGjaG9gazYImKpAm2yeuCmB5lUcFqhLoVzqJfp3yx1GMK6XHPqCqYZ4FaJ2huAURDLYen/9/o1D+uZh4/033nbWBKbUoMPPLR/5dkCw1z1RKAecais0AtAcxhX9sZvoPf9Pu7DfAVgub/4AdpBYzKO3uwIwIdrxI2QyBKCHTG6yGG6D3lh5AGSrga3rmss2JhIp/TpdYrrzsAAaDsnaeu3q6OzE5OwGJzkdoZAcDT5rDsCXUUAwx3WyZtPNJzXaFpX6tvw6IK9cNCcy+oaIFRsz9XNHLvbke0MN0ctyZo2QQ4wh',
            }
        }
    }

    # RT 4106
    class jgonera inherits baseaccount {
        $username = 'jgonera'
        $realname = 'Juliusz Gonera'
        $uid      = '2688'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'jgonera@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC/W+LDuE1zEbrLhkADukE2jILZuecapTqBDBzcohlU9z01z8mFmc9bYck0prBL7I/cLdM65QVcDZIXekNV9A6h746DeYfNhgSNfIVlwauKpvr83gRLuFGfZsIuORGzD19NKbMYxuMJobCP5KP0Xzqvk//8IcersJTooYXXg/bbfOKHi6mpr+YKqJgyXuhF4weQu23ty4HBhOFpg9gZ5oXvAShdudWsB7aFGMPqg+B61n8+j33HxRV4Q4d/JdGNnaYt/G6klhhTHzX1vnGpGCWvDWXJXAM+Q9zdWxH1lAKL3sSR9fMKQ7z5yUK9Nc3QUb7yJuHkeUhuMIysL2HNWvFV',
            'WMF-work':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDT6QY2PcibrrwSCyrBI2TRSN9rwDCLt2uSVlpCRCAUVrHNdXEpLt1WgUotZx3HIWQdPrmpakg4+R8ltsrY01oe5jcjP44aAgj8isIjujjsqKwElKdAl4UxXUQ2udjaqzqr8Qe3sl13bkt/Kkt1yRTzenVek71k878f0TUBQtcTpPUOeRpcNAvHxs/sJMdylGBM3KfjDzD0Cps6NluWXbsrQJCHiMSIaAAYyYaLXBsGRvTYG+vL9nC7gvik+VFh+kyGAindGaCnjx7q+L67837UQloXGrJ/lKDRbaXW8xpepDewSBQ3ItVkXz+TNBWNVcIRo7SL3ZgREpW/WG4DyThj',
            }
        }
    }

    # RT 2440
    class cmcmahon inherits baseaccount {
        $username = 'cmcmahon'
        $realname = 'Chris McMahon'
        $uid      = '2152'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'cmcmahon@ubuntu':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCxI9s+xp5hVPgYCFoiA7fVZWHp+tpsk8zO+iv0xpoeC1HKu5plsyQ+IrJyZQ3AlXU8TdAregeCZ160scrVJcCLwaU+3JC9dgRKOVnvrOMieK3HFsNBAXgOpLTRqXwXi37OQElEw/+WmnUW6BPtE5laQXwiNZ9HmdKUnuSB7k469gtX8Zp67/NyypOJR4gEoBC5OU9xD99lkKhJMW2o/eDIX//vzjtInQVgVBpfSSp4iNjeB9Z1gx5E28Xc8y7DRe8ShyRL/wQkagZ+cexmo33JkoJ6+vwV3Md9JkKYFkj0WCUrLBfXRAM7zagcnY7vJyW3xu81+HVQxcQAONUxAAKB',
            }
        }
    }

    # RT 4387
    class ram inherits baseaccount {
        $username = 'ram'
        $realname = 'Munagala Ramanath'
        $uid      = '628'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'ram@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC1crxU3ORFVUydISpXqcTWzUrhnvdkim3rUppL+N9OYb+kIDobFKlzWlPUx9FHvu9Rl4zc7jmJIV36qxC9mDgvIya4XS5dLEVbZ8fR1r+NH0jJU9MDpdUaFTx2svl5WQqig5cnNqi2oL17NGxF1kl9vga6SZzuIngiKvHvfp+tgrXXMPyyaC7+6OJTJjropRifO72XtbcKlNmYtOn8FWeB6Ge1S3S73LZsuTG41LRiumT2ljQT5K2CnFAREwaeuYGNWq7SRbymb7m0kys2OQ7KMeRAPpIjwLekK5+QTAdM3+W3AOFXGX9idYk7iSDWG/+pXNcFRQpgH0WDzsBeKWLv',
            }
        }
    }

    # RT 4475
    class fschulenburg inherits baseaccount {
        $username = 'fschulenburg'
        $realname = 'Frank Schulenburg'
        $uid      = '629'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'fschulenburg@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDQ3FGGK/7KG8GJULGzcZ6A1X9TGWsJKgzrWIlnPMWtdPoXRq29Ypc5NyXCY7g7ruDSq0mDpxubsTi0WNqreY44eAsAbuXz9F8iXn6aJOqIf/fbWjSOnBjXAoVT848M5drts/nWCLAYJ5VGfdUEhBNW6czeut3enPfCUOAUoYgax8S/SFFzgmsmwo/rupySYRLoY5KbxxEL7vdgCwSGrxwFDzsfVsQsazStwKIMfja/u6Nx7QhMGx4U+tQNUXEXGJ14xb2IA2h9lJpLldOTLpYm+JAE7t2Vvi5STvQUxfTGTmQSBE6GMibFxvWf2IbTPK7wVvZg2mWPvdI9P2dfBE0J',
            }
        }
    }

    # RT 4519
    class yuvipanda inherits baseaccount {
        $username = 'yuvipanda'
        $realname = 'Yuvi Panda'
        $uid      = '2029'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'yuvipanda@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCV5f/HfkCTtWhZnZVwYs+jN6yy+Ru/eBGih+K6HvCI2DDXM0OOZVfVOVCDLPCvYIZD1m//ghibiM3jl5DFrLlAUkuyzuQsjv5AOfo28/kOcsN+o6T8wmQ27oJBbCy2YWqi5r8eypTvh/VTSt1BfEKwyg5KEtPqSKOy3G6dtjYOebSCM2EEGqfDcU/+9KKCsXTeTRgBU3pOHgymQ1zXbxrLazQGGAAUyp1e1T4chg3RtOU0cXe5i9+yQuP8ZlPApLG9/7xN/OIKX7EBrSQn6J2BZMSOw2Uwe38ROjCbFljt+mQF01p4QLZQ2Vm4UjdZiY+ZsMULeDntkqgjalmOvWCj',
            'ypanda@Yuvi-Panda.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDrR80D68OpttnWGCY49ImSHPvzdCah1NckZv2U/y3Trmjp2EEeIohL8IG3iSjEnB1JirkPe1/0mHkbm0bfxqp17fHWy1g94Teb118woWt69A6pDJvnzp20faFRxOIl7UJjZ+n/Q4HSg7YToYW4hIM/I5KRKnEzi102aFHgV0cGGbxONPn0MiiEXkovlQ59gcNPWO/Wqe7gAcMIjoMvAcaumemUC5nXz8CIiFJLEfVVJ251c4q6C8TUJsxfbxkeN69AT/YqOiAO10eCbXgh0BNDactXy9oVx6u38E271KshW+ScJ671VuBQdTvv2DhrdFj2GsdzqlVYHQI9ny2JgtMX',
            }
        }
    }

    class sahar inherits baseaccount {
        $username = 'sahar'
        $realname = 'Sahar Massachi'
        $enabled  = false
        $uid      = '632'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'work@Sahars-MacBook-Pro-2.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDXuzDLw04SadzPLoGx5jLK5+iRgq9T2TsCIQ/A81N7yhCDYOaD2tgtBSyOj1vwLy8YXY2R77z9ENKQwCuXXwfKgV7W9XPK+MFupwe9ZzOvy23J1Wp8ekyzok//oiF1R8Ofdopw+OgoaXbnNzr21OaaySAJT9MucAmG9NVQzJtO0IrGwGAJVTG77oEJKpmWSHV65lpsqZ8VjCfu3Ic9GSKFaNTQJNa5tKFQWn4eeOOlsGIb4BfLncdl/0rSv3PO07e0ddZkKfibHqeqKM+FojkQLNE10Zc3zNGqrryVPRqrdKOPmxrrCd8wLQg5V3ZeRm0/MIBeuYrX754+cPwzLegV',
            }
        }
    }

    # RT 4726
    class handrade inherits baseaccount {
        $username = 'handrade'
        $realname = 'Henrique Andrade'
        $uid      = '633'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'handrade@administrator-Dell-System-XPS-L322X':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQChbQJJVbZV7Nh+wq0VKfMaWfrIhmpbpHe6xKbJDJtbz1QOcEJJJzz5mSBkf0yEVypvlQgRs0YPbY7TBaXQ0DK2qjJvRjYQz6AFEqAxhjjtB6YcCqGb1XrVqhmVpRW8E4zpYzdCrFAKhEZrShFvTh19tx2tqJyh2AWV/KqJOx2/VTXz4+fhqZYzuLEdnQIxw4dkUHfHmiJi1gPRatv+chFP5snAAjs0ArZZXkVVyWhCS6kv4hC2objC5vKNFYsAEvsv4QCIRnZHkvdNpa8nsVKCg4iq5bhVkt+98nybQAFVfsN9eOU1a8nYzuDrzdze2CcBOTy483KMyomUZepxBjjf',
            }
        }
    }

    class marc inherits baseaccount {
        $username = 'marc'
        $realname = 'Marc-Andre Pelletier'
        $uid      = '2138'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'marc@mordor_prod':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAACBAIhfgD+1iRANjpwfBQbWD383oiDHcrzj2urFBKC62o1h7cgK2NplOfxCU5eHtGh5ftzp6JU4deNWw2s3/IRJFVfQnNiHV89/Rl1uqMjLhhvLb07GDonbs+KExCsYsZFHKUH+t2dkVg0NlR1Tpz+h6huYEkaCKWxg/ozvUswHroRtAAAAFQCPGGHMiPuztPl4yFm3cHp+QSZODwAAAIAc9/psvWDUBTSnsIzTwe801NHz/1mqBZHGTmk6IhFb2KTwdu6Sf70JkWQH47h5MmTsld2rzvBopbBMubRfBu6KCWXJM03pfxRdgUuhwovAKgU1hddYdonhkiq24qn+U7tnYHjHfu5jB7dnjEEqoOggUXmVUwS7QaGJqKUnA4B0+gAAAIEAhoDEpBOFA5NsgurAjntLMZiTpkQFyE+c39lBqgd6B5bX7GEB5JkMPVSTjmzogd88+SwImCWgvb1I0PgY/rx8nd9wMkE3W5gBGUiDTNJa2v78nTK9wS+imFDRMbuwdYuN1wmKGrnvskvQ5oi1juLA8jn0At3L2/SYiC7i5z/z//8=',
            }
        }
    }

    class bblack inherits baseaccount {
        $username = 'bblack'
        $realname = 'Brandon Black'
        $uid      = '3015'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'bblack@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQCxNcPFGwSUYB24njYY0BX/vHm2AFXZSQtPcPGyJxP+fkkaTQOKX4pGST2oCudlV4hBnskTTDyd4r4YF1+HPAzxX7myCcCFh+9L8AOuVcdcH3g9dSiV3csAemlOsfPivrJEx2RG5sFiYqaLSfSMF65QjJUaX7thWIHRFH+sDoPfVBEJABbvO3yeA9uPBzqWPs+kII7n3WMEsiZPvbPRypsfFwa0yoZotnoOC0ZoiQOFZCm3v+Xnoxv5gRxGIZCrR86dstKoISJU0PmPaVZkYElAhtbLUxlBCsE/lSQi/phQduuI9u+pApaW+4FxpUOPD+i6NfdjchJRfNG5Lh/7PPgUo3LWXfQr3qKm5dOT0PbgY7Mif3fvkoI7CT5RG+TVau5YjU6zL8TWAx8nv7U2hgU/VuJT96FvBYbnvbySJwk7LMEl85UzZ4M3o9D74csj9lRGIc3VXoOL7T9peYzTxr6+0Uuo6mBWOdgnp5tn/ew145SXJmwL2Ly3k/KVn5lehL6F11QaUI74Yw/MuZ6eXmiR/ZBcbBHD2WnRyJOPjw/IOwUO848A4NoAcie0ESKSRk5RdmksMns5wYniUEYOCjuErk8NK3ClquQ0Wd6yOz0TTRUkPrUR4fIuEGraYlIARUvnidxK9kFj6q5KYc2MKPGw0m9scPGLGokEAnllrs+nEQ==',
            }
        }
    }

    # RT 4835
    class yurik inherits baseaccount {
        $username = 'yurik'
        $realname = 'Yuri Astrakhan'
        $uid      = '1011'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'yastrakhan@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAgEA4nAjWgQOlzel8gYe/Hsl3DpT7KF7ygNVl7mZBG7285YUakrr2Hj8fSn0YfYX8b4u+FTywah7adefxTCuG6x9PkEzKAYSnaWXRxz3C2bZclkxXaKcVR+IJUG/9WyqwLxVj/UeATsuydSEljcwoMkTkV0m1p5hFNShTwslOiKA6VIwVQPufMjFaduUMXl3H1MzA0ymO/xzkMsOmsqXLgOIE6GOE1r3kzQHSD7tvb0o9dwtApUEhRiwGPnWxlDaGpWhzNQ9hHXGZG2XvfDvhVZ6HNJ/wR+x0WI1xX6b27fPbDPYkQDxOrts6G3F4WjDqmPLMYJGcsBXwueh99X2LaaDX6rWU1vq37Hj8Q8ROEdsL/RX30t8WdOj7YRGBEMbZliaGJNhTyOK2nFOBLKRcLSYVXtCvjFa9iTSqG8ZHdwho+vYRcs26hxMa1bWdS+Sg/YUJlfCxZk+zi5xryF/pog0IJdyqgNDqPau0w6DZKphlo8/eXcLJB6KkuaJ2xE52iqLokGGHu+EyYyOSrBSCOLsvbHvOwe9ESqDiJs1TAxjXqoOzNfWZKrfeoZb0AqycDwwbvM3oQB4/N590Jsb6frozsDCo+y08AYfjhM+lIFY2SdZHOmEzmNTDwJYf2MQOc7Mi/5wl+tMMnkXU0OPz9Y5ItDyfTwIsyESumVa3FYSE2s=',
            }
        }
    }
    #access revoked per RT #6845
    class mgrover inherits baseaccount {
        $username = 'mgrover'
        $realname = 'Michelle Grover'
        $uid      = '637'
        $enabled  = false
        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'norbertgrover@Norberts-MacBook-Pro.local':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC9npOnzY3kpFadPdPnd1FenTwI50a50zB8+92LDqgaaJU8yYXTncKb24F54/OEtjjedTAYwyS3FsDqlkBU9N5h14UAZuv8Yp813duY1yIfpGBurHirbcPBr/zbtgWtk48Gay2Prup63+CHRLGYR2HDx6csRKfb0wOo1NFtZTuttVu+eCZ9yZ35DmK1fctNPJtbfFVxVa7cyqHY0Fvu/m98EynGReaMiD6yzgIede2mnTLF6S0+Hn9bCX2oXt2aTZY8Wjb3osXACCtK1kjorf65OrMvjgvLDYCASF1D7ckCNlWaTzdKsjNjUiUmuB3DI6G3OxC82OV2xsBXRDB9k3Ah',
            }
        }
    }

    # RT 5302
    class jforrester inherits baseaccount {
        $username = 'jforrester'
        $realname = 'James D. Forrester'
        $uid      = '2417'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'jforrester@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCsgEkgi7ceiRLCeBABExyA1qiFS7t0Lxs+vQndqRTukAooT16araiKSudavjr78qUAXeerSvuNm2dlQR2Bv6DZLumwPi2mFZA52LhlCm5Bj8GKSpwc9lVVWrrtjwCb8Qv+cZXquhvxMj3L0prfeMbXzkpbOBVK8J5bVIRSewVBsammz5nzd6myqeL0Z1BXiX6ihKeIjSyyiy6REWuIO5cBt3IJn6o/9IKei+Fm2UbXKegRFyOPPjXOiTItLG7iR0DI3PNT+FFAqjMXQKzQMbm8Lj0/hQIq8ViyA6xai6VDPtnFsmvKi+z8q6jZP/Omvf+5TKF5evttguYF9SrbmUrb',
            }
        }
    }

    # RT 4959
    class lwelling inherits baseaccount {
        $username = 'lwelling'
        $realname = 'Luke Welling'
        $uid      = '638'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'lwelling@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDmE/EXt17CN/+BMEuU2ecAnjfth/0Ooyy6NjHW1VSQNcoVwkr1axzSbrvJpuJCBJYRX45RPWPgm4Z1sT6PiFiohEA2uLCo9Mu5PCSPQJQ0vOGpnNUAFW6f/UCFU0wQufEd9zKpHWpXDYshqyhrLPGjE+x+l67cGubBgnERIzbFGkVXde1iSFu8CFqGbAeILC+k6mVOsTt3QhrY4l6dMHhuNOCTEfCnyd6TOWtQ7T7qEr/BFQ4e4YtrcF60NyQSyjqwZejPwP3lJVu32aNjxeCoNcH8/DVbsoNa3gHzvHmHxq/1pi3e9OT4PSaF+Pz5VMpYNaurT0rgzBwOibdvNwIV',
            }
        }
    }

    # Dan Andreescu was previously the 'dandreescu' user.
    # dandreescu has been removed for the milimetric user.
    # milimetric exists in LDAP, and using this account simplifies things.
    class milimetric inherits baseaccount {
        # include the disabled dandreescu user.
        # I do this here so that we don't have to maintain
        # inclusions of dandreescu elsewhere in order to
        # ensure that it is absent.
        include dandreescu

        $username = 'milimetric'
        $realname = 'Dan Andreescu'
        $uid      = '2543'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'dan@DAndreescu-ThinkPad-T420s':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDAOgZWjHAoVJF6hJCrDUjVuiZiNeW1GudEfkFJS4ORo+WpVaMjwrILGThrriIYZNEIQNEf4l+7ht2l7/9g7e0j56NxXX3NJftJWRKOk1d7s57CKZAdvcbQ4G+L/Tyed+qZj9JurHdMstcVo50nd6S/UvbvDAdieXHemhZLtFcqPBQj66XDJkGzm0U9eW49lB1qCzcQnsNQbxRbV39RsSgIU9YHeGWMsglI227nZX6Lvd6/Vvz2VsFR5xtdPBHQ170XqbRylZQaBaR1lmRz9Aa7dSKSbNgGYAUNkzijILhBccJK1Iulmh/yDFPm6ZVWFaezinbCspXnvCIdJfG9EoLx',
            'dandreescu@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC5BDWG/6bvsz87yKBkFf1ryKSbF2/CNzxTJn1Ux135/ALq6xcr5/+zS4KA6g7D/P80hfvTq9+oaPVVLVX+ANGomCv/kqvyClDvEnU8r4TEAPkZBrOWHAaexn/6oJkY7xoWbm+ElTPTDJfedWFYPKJx82dWt5CBtij5jpZ5CE2/Lt+i4gTH1G8n3Mo9gCnA8AlhMDTr18XssfqAS0aylmCwd24TJQJE3d/2NYdoytKfTebg87lJ0hbFJcxHVsS1/ivT5+in2wSfLXOIQiJPI/ykagoD9z2FSVOiMcdnrL44Xb373QaS7bEAxpjBJrCUQzeJfEvS4nbPpOpJfSN1+7Kp',
            }
        }
    }

    # RT 5274
    class manybubbles inherits baseaccount {
        $username = 'manybubbles'
        $realname = 'Nik Everett'
        $uid      = '3304'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'manybubbles@manybubbles-laptop':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCvG6VYTnUwHQyLYFUv0g1EUfp+OByn2agzc6Y3oSj9JhjYT2zbzpfquCB5aL8mLv4A1J8iKVwWHGeib44QY8uggX/66xdRrvEZ6QaM3GkVehDS4MpKl8m61rnVfITSxmPg0n83pBDhKfXPzE6vzchBA7ZhonccObwpcr4jvpUrvFcgWDrhjbC+YeJ1YKz5lm6IPW0yeY6Ni/0LRNbIUkv0Bj1epsFqBPORO9GoWc9ydV3rDLJJGJJ5YhOlbFSjc6nblUDMwBToxov+5icnT22wNdlHizGPUafluw6Wf790Bls3Znoje0qY5KgC7zOoQWWR+3k1kZVpuOIVQU6U3/uP',
            }
        }
    }

    class springle inherits baseaccount {
        $username = 'springle'
        $realname = 'Sean Pringle'
        $uid      = '3391'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'sean@mintaka':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDZ632eqrXOJ2vVKmxwode44lGL6UGEXUWG8muUP1ItqSCdYqmG11zaeH3uJNfsbqUu0jJbKpO7uiKSwolaYrHDPLDl5v5jNyRx7aQDzMgCjtVGAZIN3zQGGybl7v8ZQ635L9SAaATuYd7nOdDGa5TZ46YiAv1BA/+RGnUSz5h/ycb09V7o+RlQbHRTsTCIxjIMg45Rqnn3ukBeGNEZAU4IgaTRkg19PfPeSH9q6Ni6Wa1jz32ygmotT38vKuCvOXZxigrHJKwovS6xdfdxC67UBMV5J+KICpRPVAn1iIQMyiatdG4tBlPOUEecZcL6f7QaZufZwI/gU3wkC2zlVchF',
            }
        }
    }

    # RT 5403
    class qchris inherits baseaccount {
        $username = 'qchris'
        $realname = 'Christian Aistleitner'
        $uid      = '2153'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'christian@quelltextlich.at':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC/FKzYz14zzwGZBltEn/PKw90dTxGvvmMUK2no5qE9gHd+zGlYNoriQK0dRsiGyWEf0O0V0dEMhkM/LjSVMqxBK0nOoAY01sgJrAH2VTYgB6RnTqAG2gUWuPEfPMZ+5tJMVgr0hRkbrZQoEvBRAv45xfywXI9if0pBtbG710JrEbAryyLfU4tt6gRAPgaAZ5ch9ISnMXden2c+N+KmjC0IXwtN7DteaCbvsL4vQHZ1JyC2OjPbHaH/6gJwE/IRbZSxTUzkH9UL/+v9N/b4yFYFGKP/2yZgHtWQfOsDpClOUiooik0pK/w9oQA+kOcKdjm2oumss4FQwRswDYJhaKI/',
            }
        }
    }

    # RT 5391
    class tnegrin inherits baseaccount {
        $username = 'tnegrin'
        $realname = 'Toby Negrin'
        $uid      = '3558'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'tnegrin@Administrators-MacBook-Air.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDzsPbsUjMIWw5KMJQMlkjEHnlrknUJju/74vs47iVb1lW3oAgULPxww+MX3cswFx3zYY8vw6K6fLbTaUKnEGAnW7JX2+Lo5nDfov3D+Lbb4jn6HfutvFWWrvMblUmd4FCiCsYsCXFj7E5WSzNmIgIWHzbxSSeCUPiUiG9enyEEpJJj5GvtrBZbdcoTpfhJuwGpAb2PrSQOCfuqE4izwN9ZfWruVhFbv8JvKu1shrG2DtXro2HmIVUwwHVZ8YMoMOjBtQo7Ioe2bjNWM1Ev9lvamcToJHe5FsauMcxiNmf2NXolDO+9VaoCQak1w06lvEUMegsFb8XbssFbA3uF/pfT',
            }
        }
    }

    # RT 5512
    class ssastry inherits baseaccount {
        $username = 'ssastry'
        $realname = 'Subramanya Sastry'
        $uid      = '2316'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'subbu@earth':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDlpsA8yuweHpvf1MqoURe7npQV5PlqwVjIGSshN2BWUrqO4tzC9mvy4vfGyvKdfPMFUlsk8hs6BQgMbIY3Qr3cF1+62CH7jx6FWzRWTZpFfyckUhdJu22vaxwYxzZu0au2zIkeVaHqnV+QYPrhjnvcOrwosF4ArfW3guXH5gjBF9RsJWqlC0xejiaVVefsaEKan6cOLslLG+caQalJdNfJ7mBs4hPKLQWF6d8tbWld5/jJUL/hFe188/hkyLyfD/TSmRyWtoN0q4Ubcqx3LMDoX3EKYAl95i42a7TT+zg2GOOZXLk9rruFKk55hNfg4R3T+JxAffkJygKykyPvlfhp',
            }
        }
    }

    # RT 5520
    class kwang inherits baseaccount {
        $username = 'kwang'
        $realname = 'Kenan Wang'
        $uid      = '3468'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'kwang@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDj299MZhsLjbagT8eu7QMrmMWu0ROj1nJpGrod7sU40QXqE3JSDthmvt4YBx8EkWmYM5t5akLF8vtX+KdjxFs1m1tdSy7v4irPfVaNiswQx+GuOfEiZeb6a4oKD6PhJJ9ymkTUP0CFC2rr75jQK26vvn4aFLbridm2mzbsvTJG+88HsTz4DktEbVBFz4cSHBuQ2ckFh5I1JDdrQ/Wb9g8t4LnIdoNhjqVffzr+pGz1Fo0HH12EWpagYIikjG4iYAgpn0GQZJ1LLT4hmmnP67rH2LEKCcD92kRGO2MO4VzlF9Ij0nLbNNy9t16hQ9DT+wRGIBU51d+L/pUhXYWxIF4N',
            }
        }
    }

    # RT 5726
    class siebrand inherits baseaccount {
        $username = 'siebrand'
        $realname = 'Siebrand Mazeland'
        $uid      = '1091'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'smazeland@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABJQAAAQBkNzWQZaKeRyXt7jcsfsDHzR3foT6fJq3buJEqbMo/cyPimK1rfC9ZE0/Tk+5DHjD/Q6YudGakzHoCf5nj7IAQNPRsVeiPKPCyfr/mKCriVG0tsZrGpm2y0aCsteV9+Y0l4yVBbV/3WqEKSzDY/Yq/gYgnxRZGbt+WycDAAs4UeYHCSbSHszL1nLCgMJnSae9twYGkdE9etom+4acGWuFax+3DQF7R1QBItFMg4yGtc28LSkrsRpQbs29LJps1fNv1ueTxEiSf9Jyv5R7vg1Fi8ohA+0VvwbpgofqZuGdEF/nkT4Xn4ku9nq6eE0UtZ8cFj1I6XiQwM7wuf07ZcKOr',
            }
        }
    }

    # RT 5936
    class ori inherits baseaccount {
        $username = 'ori'
        $realname = 'Ori Livneh'
        $uid      = '2220'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'ori@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDU6nsR19aZ2Ck2HSkdJPdx9rmw8H6UrPlHIBvt1loL8Kku+5tggcE4uTlk/rc5+Fch6EF8un0kPKz55RQCDOhV/kFHrxstBCWf+PJQC1gL9vbqyzia0OyGpCsLzYO81v7NMxkg6gELtxLBtbqE8u7m4X+YkzMxNrlqPfHjIHrVqr4RbLkJiuPvI0VsesAoPCh2MEl0Gkzl+08GDpYplhsxFwPzo9xoFMUi/YCIMKTczOhdg6nPaBMxjUkz7EKPFI3MWZcfP/as3xNL1me7M5N1iJjveGz+rXDqMglub9gN1aDllytzhE0+6h8jEDzC9DtuxGXVB8M/9eCEWsOJlIur',
            }
        }
    }

    # RT 6013
    class gjg inherits baseaccount {
        $username = 'gjg'
        $realname = 'Greg Grossmeier'
        $uid      = '2890'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'greg@x200s':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDcwwxwZqCRMBQsMIutloeVS5Nx+nljUr914Yradb8YLeo2PbqLEjVKgC6+yKHe7binFNk3rlgiXhXOm2issytl7sWUZz8YpFqxp7fDqnfVVOTGTwMtAjBoZHugz9RaR1SVlz2dRk0N5qrovffz/Av3QQIS12jX3C/GCdqCMixgwi+ecYo2xA7WJyEGFnp+0Ah8hBIn2xabZAfHhZ8dF6VifEHsgp08Ot52sOZwb99+H0SjEWRwc9decwuPGNWX94BPvWcP6dQ2bzjqR3iRkwEIvKcgMvanYUXAvPb32382QCsW0r22HtvsUvA340ISlvcauRS1GGpyYmZYGSSfgHVH',
            }
        }
    }

    class mhoover inherits baseaccount {
        $username = 'mhoover'
        $realname = 'Mike Hoover'
        $uid      = '656'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'mhoover@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDHHt80fZmlmhzmFRgT+m0oIOs4h9ZDpqP9a4G79TZfZOA3eCuiq+kucyhdm51ge7GimzE/rhFgw3ZBVXvcdKpwTDyybArM5mOJsyg0GNp0Ns3hlJrvAudIXnxEjGlMuVF0ek3Vexi/hBzci5chqXSXxQJfUnfZnBOMiFyAGGM7KQM2W11SwTxyB9j+2McWm1ZR2rC3DjTsfbsus4BMlNYgaR7hE3ovMiCdke3NorFJ+NjZe2NjoMmSUNnGyTJvwwUncDXLELE4S2QQ4L6Vc71mMAC9VC/+qrpjTN6CEfae8nEcBvrgA1s/ahMI+3OdsWzRU0Gv3+jgqUR/641gXdkB',
            }
        }
    }

    # RT 6011
    class fflorin inherits baseaccount {
        $username = 'fflorin'
        $realname = 'Fabrice Florin'
        $uid      = '657'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'fab@Fab-Wikimedia-MacBoook-3.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC/j3DlDt7UtXeIRhTHPdB0uvPUAA9I3WkabDuFyPPgiF6uWnAR8YYOoOoSn80GOz18T7SQAqRr3a7lNUVhPwo6rku25cl0lt1SEHzfkRfhT7+ekf6KIaR9XH5gs3jnWi0QWoIBOoRLHoF/n/VfMo/1suQVvUTTUWHbt/QREhp0Co1OD3fnE7FpuhnJx+2aNApzwDaqh54CSY65pYGQmRAzUvNhtRqtf37AnZd5wAf2cDrgHoq1cT+jBIow2ElZaHx+msbNIwWaOFEL160rQWTsfWyKPv9XhCRDz+5/V+rDoRbaU/sDg+sph9TfDmW3yTEM9OkHGAmZmzlVfznBtlS9',
            }
        }
    }

    # RT 6491
    class gage inherits baseaccount {
        $username = 'gage'
        $realname = 'Jeff Gage'
        $uid      = '4177'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'jgerard@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCs/SColtnog9MyumWcau/7bfSvJhot5bSZWGnTPI9QjMupTQH0WCr1IWdD6NMvGsiDd81RzpfdNO0qCvyXQgAXFBs2O8ORea9kNOi/VElyGh9HJkqUERsMScrLFrhhmUyNVTw1gnk3sanRXASTC7zSXiZS5a5mqr9LfzPYhw04K57XCspFwERsg7kkIMYbl/yPMFmmPTUsLWTPMyF7xyn0TnrOTUx32RGIj4G/Kcsc8kcvSDGpiZSLvoC1QxuXEWOK0N7fd8PcL0YEYArLTPTdzM2CTvP7jEB0totPtxgWLFy+03aohdtX/cnWe1i1Udfh4dr5Z8/1x7BBSW1NX0JJ',
            }
        }
    }

    # RT 6506
    class msyed inherits baseaccount {
        $username = 'msyed'
        $realname = 'Moiz Syed'
        $uid      = '4206'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'msyed@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDDKH+F3be/hR2mp2CxoUGRo+MvdP/hsEqRZc7R/cUOJM6/kWJubxT5upjLiSt6JU8sIsAzqD5qprhYjdWl+y9HwZLpN7Jb1iUwStsCpFH3fq2/fKFoDpMF/10Hn24VUtaoE5NJoUThshJPF8zfysmbZElaCT58FvJt3KHKcIeAjeg6y5IvoDZtgVpbTYn0BxD0UyQ+qy6UmlPja6/oh5h4gTZNpZoP3SSMf99MO1jDC05EBqSYT/FeeylRqMUGYL9lyJxGkRyc7RQ654y6kFb3YmYgYxzYPghE3fvHToOByxoygsyJWWB3lXO7Lw0CLW68OrU94t4qR9IXjNt8Xv3d',
            }
        }
    }

    # RT 6525
    class nuria inherits baseaccount {
        $username = 'nuria'
        $realname = 'Nuria Ruiz'
        $uid      = '4193'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'nuria@wikimedia.org':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC5UHmmvoplLSsc7WH0xijDJiWzs5LaVkIoi+yWBfHta17lGUfRCsE8DTQCe30k959gKGDBP2sI1srmKtgSMNIfQTOG7rt2/qZCYkrU6xA3XSFVi73zUHOyIzG41XO5F36uF7HVNKnxhkoxWkUpZ1tv5f2PEUUhBznH0JQw9BRrWbBqah9m8o8MTFDkeJuK3HgMhUzwg25t0LZAajaK4Mc3Bocdv1uzs+RxswyOWgJqPxQY+75bG+/rZ+n0bETKkDoy6ZmCiVw4PSBCX0zGWHrZQ89FzoUdM59hKSu/xnkOV/PO92iT22Pzd6NKgbAxrwXDteuUh0+6cL5du4pwH5cr',
            'nuria@wikimedia.org-production':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDIUCvA8K9rgp4n0hCJxbFt66CSbo9JhkSvQwlMj4+mxj9Mypf5/TLoRVPNVEwF4htjKmMdtaXDzGDTJUJPh9SPWqi1wP0YGydxv7z8BAIgaRliCHycviGE3nHjcxkiG+U2zxBL7Bc/Jy7d5Ky2qC/5Nu7jhBRF+kq3haZ0zx0T0cSmTvvUDfKt27uuLWxBA8Z4z2kNYVCpVL4pvlGPkqhZO75wPIUsCAlPH3Tq+Cq8FIc7BoZgjFQ+g6okpUF2PZY4eVoMR2MS8WIwQlOXwe+AMh+JEgq7oH//LN03IDX7YJQCNbmJ6MR0YdB1TOQHF/RKFImGBdDEC0vx6/QeIVOr',
            }
        }
    }

    class aude inherits baseaccount {
        $username = 'aude'
        $realname = 'Katie Filbert'
        $uid      = '1185'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'aude.wiki@gmail.com':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC+OiQ1ptiP6VqmiP8IOp0sKET9pQHOJxscK6bAvAmAP72DL9MgLIBaWpaL9iWsb/DMXI2CQpEnu88VMVXCSgiqw+Gy6Q93pAquAQWAzkMnDD+QvxTm23oFCxP795IEP3JMHuONNg2x3NU3jYaOADOGZX41nRhbkO4yl32jQCTF9i670KS+CFDHxRzmOMzNhlytWJYyVPS6iqUGykaFcebFNThMtRtQF+pWJNreCFxZoXp1TyzkiJE1rX98tj2yhVQmET6mENuGXuAES/Atzpxp8zvsckHn06Mm1RZZmIExEqn/JdK6nHs1UoSNpsI195ltzkKSEWdFdYKRLZNFuRBL',
            }
        }
    }

    # RT 6568
    class ssmith inherits baseaccount {
        $username = 'ssmith'
        $realname = 'Sherah Smith'
        $uid      = '4170'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'ssmith@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDmJFv/VzIMGs+/e7pue7Jdz/btDh0NJtjvrfN2Wgsj+pb6L9EJcPCLpl8jKxzLKBN2yimVZgWm/+xkOuUdj/0iLtkLSDpWEbJA50WZO7ZTC3xzI6P+xpFr/UUNDrniGyxx7TLfV6g++9Rrj8/j0ycFjpEAgLBko+yF73bXLxIRJ/Z18pToU3+d8sAqHYTlxjWci67E0cXI+C+qOmkzGOXv5+2eC16L6+WiMx+IA0slMOAGVwFutKhgt34/8I1xDuNGpitCT/+JhDICtJh8XvtqXT2cOQ9ATyDrs24LsTNzBmeO6eRnJiREVBgxQYQByj+BNdwN8QtUvt/2tAmFr76H',
            }
        }
    }

    # Disabled in favor of 'gilles'
    class gdubuc inherits baseaccount {
        $username = 'gdubuc'
        $realname = 'Gilles Dubuc (disabled)'
        $uid      = '659'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }
    }

    # RT 6619
    class gilles inherits baseaccount {
        $username = 'gilles'
        $realname = 'Gilles Dubuc'
        $uid      = '4319'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'kouiskas@Ta-Mere.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDMDCMiDMjp3hY+P3DBJ1D2/IxS0xMHpS5MpKgxd1rU7aOHByncrRWL4tJ2isyi8/Q5H6XH81eWBat295U+3hqTq7YDuRiNoyPQPvwgT7guJPS3z8AbrlosUSIBc0B4YnrJXKeSTYEvHqQTGeozGDn1XaP2/xjeQR9wpKPpa0Mq7S3CMv8BEhvJLDVmwEP46AvGMeeZ2IgxlbH2GAAcZrGi8bvlq0eFcB0I/q51k/kITAMiBrTXo9sJ7FyXXvPnwmScfzIZFqO33lktMaYs5q2w7sad2Wtpz2tR+hMNm9Xoj0znPgKiZ1yFfGoKN7U62FDIJq23IrIRRUbinI/F220p',
            }
        }
    }

    # RT 6533
    class kartik inherits baseaccount {
        $username = 'kartik'
        $realname = 'Kartik Mistry'
        $uid      = '3033'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'kartikm@olive':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAwavUwjlUmLv0CJGAvtUfjuLkuukC1tNUi0BmMzOnmbtqJ1oY/RJ40HySJuV3RxFNCvFuMztqatX6icE82G+nBNUa5dzPKThWjsq9+rEyaT2KeEkJTXxBqzrWikV6GaIDCOYMVcw+0DMVfdhd/OxgcetYDgMADKolkcJ1YjPRI/HLKBtWDOS3X/tkl4xjYTKuARGH3lBTrmDZQm3XXKmlvnL5GXAcFu9C+rWhAGYefrIgWCGcQeNZa20A9dcIYRzERJ93szFdeEpJqGvQ2niCOmJfa4eyuc9jAvY9Xjp9XMXkCzRBfmhq9h1qRS4EpfRlm5cDs/RL+VRD2lVMLApE9Q==',
            }
        }
    }


    # RT 6664
    class csalvia inherits baseaccount {
        $username = 'csalvia'
        $realname = 'Charles Salvia'
        $uid      = '4415'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'charles@hailoo.com':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCjGSS/3k++mudvR5wrGYhLPYa/RQbtURNRhgjYA7lx9dPg6lKilQliaOMhKOxlwKDRCzNZNSz5CGG9Ype6dFrZf/c1nxF6D3YwD07eOITIy85qD7nGmFKTG2+olbwbvl0liC85AQv1Xi6C4QxL2za/t3iXb10XA7EJ0GXYKLp2nfFQ4FkR5+teFqgKpH+gd9SswiefW97HcTvuURc4n4YIC+WZJhD5majNV9Ben5QJe/qz+GnAfGSsKxMWlRRnevx7VP3KfFy9+6Lzj4Gspq+V+34UTlvY6VK4cL37UG/53dfBLgpMVgWQ0G7sooHw2xj//7fVMpAd+ipMQzDabEJ/',
            }
        }
    }

    # RT 6655
    class cscott inherits baseaccount {
        $username = 'cscott'
        $realname = 'C. Scott Ananian'
        $uid      = '2880'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'cananian@skiffserv':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCwkZUO+LKFVZwpsBS32b9AxTxW3N8kxbIc7Fo526Eorz+x85KmoivftU48OiC7+3SzLH7Vwxvu/VSu4i6eEKZps3WeC9ixhHexuqoTsqJ0FajaAf1LVKUbkSR+tpfq3+eFYqw10AoKO2m0NC4U2DPFtDsGgyWgDZI/of7HDdVB/CCcuvPyQY1Jv1vjOcpxZszWWVvrCeXIhu91wfEJ2LxcgfIIPCFIZQBJpcW51qBMbB/WDqwO4ormFvphfNiShNvB27g1UufWivXlgePXZf9kEHM05wqTlMjyUMM7ZG+roH2240ViwF8TwzK2uHanp5Vgi1U+kqk0Kx3Dxw2bxPvV',
            }
        }
    }

    # RT 6731
    class hoo inherits baseaccount {
        $username = 'hoo'
        $realname = 'Marius Hoch'
        $uid      = '2133'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'hoch_m@marius-notebook':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQCcNLT7ND174wiCEzvGm3xVNyhn/PiBURvMD5SofUN2sY505IY2+X2tayZl+ASp3fqRxMXRJS3UcT3Pi3bI2i3RNjCJCryx4YL09w/KcuhsJjGgRIdV9o+ZLjD3V0+B0xt/igTQwxq3UepQzzZIbGGkRf3iJVRFqjmdW8iwg49MMG0hsmu6dTvf3lGLgm2pihbXYIDDTCOAFhpDjGkLGeygp9tymAnxByUDyRW5sclu0Q9ftkCKlRwj79gFP4f9UeroOXG2UOqB+E0nc/9HyX5lGbGU54Q35iwAczWf0taw4lGXwxZfBWwsai9eGzt+4JlPwf/s/8gA7KWcz3LS/qKja8/xhcOcUgr+B/Lv3LgwutgCMYmORDtEQgzXhc8IDABZp6kb7wSYzxEQ/c2JhzPub257+l3r1WPIZKvi6DKHznHE+4lHsD8G0zzW9ZRyrchn4KXFiUzSSaqdvoT6rb1zV5UANIrlz6ndPSgLkra/dwinru1WzwJDZtBWMaP9GVCOSWxWWFwS0PEqo9FOj/exVgEU2NiqzhKZ3Zi4dbJOB5S6h/oTXf0zHtULclXgnd+S8Z86oXjcJmh61LmOVkETEc/ydZnw5P9AOs1Xq7FTDQtCzZziahjRgZcsPaJz0m026tR3qEI3AVulQ2kcuj5QVx1ZO5ogAjeCxvHLV4FQWw==',
            }
        }
    }

    # RT 6765
    class leila inherits baseaccount {
        $username = 'leila'
        $realname = 'Leila Zia'
        $uid      = '3963'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key {
            'leila@starfruit':
                ensure => 'absent',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCyDhTiTa+lUt+lM++HXAYchRyKX4GVMwb4zAAovcHbG9R7NHAP1vT7px+vwFG69TZay/MsuZ7oo5NyRUWNF00CXSSx0KMZz5FirW/dncrRG9/N+fxat8jyjVVrFiY1sngSUhmILQrLGV0Wa7EC8ZHv0qywO4UqbfgGxZMY5n2nu3hFvLn6LoKKoNDjaFTfEwio8QNjdMC0NZLYqUk1HMj5Zm4mrTFD+UcOXSbbOe4MytQKDYzZdEYd4XOE1ki/dRvAmPhAj0gAkezPCRseCCamaDmokd+PS8db3EHJ390+48FTkXLIO1uUhJJmF9MsWL2dj2gDk1RZjkOlfcAapypl',
            'leila@starfruit-2':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDDrQIRAiH2afKoaaIW2K6loEk1CoOD1IKCLMWcfAky+CwqsCQWepiQxlQOZKez+Y3D0hE/jVA8Rv4jktx5SIqOZbkYQXF1s54jp2ULqVujofqjRH8qnUa+b3s7ywCQILGR8gV1X5cHcXztonwKhrEGqjlw3kk1NeOkI0/akRbTdxGjL5QbhJKg9T3bkkBkfwBupVvH8nxzS1twa/1lGLv0GUF220gEo4c8yUhT9EFWwzJlpcmKBo7m6cXrhXeCVoipKlfq3NMupTT1AiYh4Dcdnk+VxWNkmkbOU7CN9dvwXT0gK0OjznntqNC2nadikJXe8tAOPL953S/9br2Q/OGN',
            }
        }
    }

    # RT 6785
    class phuedx inherits baseaccount {
        $username = 'phuedx'
        $realname = 'Sam Smith'
        $uid      = '3926'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'samsmith@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC9+TJfrksUVwMxt5Oj6NZxacj3UyKQNN+J48r7nF2SSVoH3hOLpXLB5Vep09X2bxyH+1AsqGQKGLW8a5DSTcEhLQ5Rc01GmaV461e51lxJoRRlDtCI6+sqBJRstZVWUrxYeAjAhaif0CWmepySMWytrFrLJuTQ08L+R4XH9uXxWfE+qY6KBjrrOGKS+98E13vYlxegxpctz729ZC0jDrikSNX47lu5us5OTMotaYPOu/lFYO8RUmqQnGNMjoKJjKQJclDZUp9fV3YWPW9XtJR6z1CACJIqng0501bWulMsjw/nWySoJLrh4H99KeLUVSiEWibupoTI6FKO2PC0vrzF',
            }
        }
    }

    # RT 6760
    class santhosh inherits baseaccount {
        $username = 'santhosh'
        $realname = 'Santhosh Thottingal'
        $uid      = '2024'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'santhosh@thottingal':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEArK3LPgIbkKgXNG0l5g6vRND236f3Bm6h9kiweycy4l+J14B1hY0o1baG8FNxgSpRxhZ1xeqdZceSii5fDfNEx4SnUEImCruH3PedumYb5pn5FIlZHEHvMOmjVobkSqES+ZZ5JrYLk8Xc4+elDULF80ERAx/8k6hwMHPJiYJwv26652GyE1nqmBj5KRMxmrpnGenirjLl8fnfRgFX3EqTliGTKqZ0B7vBVLNC3kM++EwFhLpwfQaB6/Jt6fdgksyIx6vB2f3mPQOWKetHw8Iu4VeAYNgt/KzXzvWNnS9Z9Uw8Ushn21BX2Oe7h4iICly8RDsQbVoT2PKmqLpNVAcOZQ==',
            }
        }
    }

    # RT 6760
    class aaharoni inherits baseaccount {
        $username = 'aaharoni'
        $realname = 'Amir Aharoni (disabled)'
        $uid      = '571'
        $enabled  = false

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }
    }

    # RT 6760
    class amire80 inherits baseaccount {
        $username = 'amire80'
        $realname = 'Amir Aharoni'
        $uid      = '2076'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'amire80@theodor':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC7njjWSs4MH87cSwBb7IreKEaftiWemChkpeI4bPODhFmziTwvv1PPpsdGHbew5OM/8Oj9YlKSpiHG2tRaOK3kObolwKXX9vC7cFa9wQ6UU2ZN9RZNb73H8ZmFNwEzIqAKoFuF2V7d1x68Oxf2fQXzCHzhG3Zx3qEowRkQY+8MFpSHlDfO7ZcYr01W2pD92xyH6HVt4fr1mFOpqRSp0aMR5mifgC2ugf6kFkWkNEoYHuTsyK3qWaLjnd9FfegEX6wEhS4RwPWg1gqUY+1wJcKnSqUBV04swqhGOz6YzM/HTekboC0kJtMj8D35lepak9Z9I4MHTQpeBxnqaUq9c2cB',
            }
        }
    }

    # RT 6861->6929
    class mglaser inherits baseaccount {
        $username = 'mglaser'
        $realname = 'Markus Glaser'
        $uid      = '1229'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'hwsvn@84-16-252-165.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAlpNpOKH1JJu3qBsBwYJFO2DVnE9tzkPuMTe7qZLTpnSDo5AtlzByJ9t+g82PA/NKp6XivRCaEeVxxDQkUOKKl3rg5DVFUkka5BwoymTIiXEpw8abnaiYrCNTN2SDCUKcS8wdbK9nCMvaueYEEvi3HZ3jZZRV9TunSXpJAlb6Y4U/EMmlxTb6xSvFr6AWWt8OgtVISZZuJh4CPTQEQwW0j71vOtAEzBAtSrRVZJS29KXiue19D5mtYpdjWnORtfarowPwkO3UmE1NiBPg4jCClSOcJ/yvr4GM9dTdeXVt4fTrojI9uW/YkHDwZ+2DLpGWj22TO8nvj8KiJMCFwoi4+Q==',
            }
        }
    }

    # RT 6861->6930
    class mah inherits baseaccount {
        $username = 'mah'
        $realname = 'Mark Hershberger'
        $uid      = '1232'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'mah@local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-dss',
                key    => 'AAAAB3NzaC1kc3MAAAEBAN3UPFafraObEOzTDiqAIfwETAlVNaZser+uksj62kO5Z7iz05h2MbWCM74UWQ8kvJGFTaSaqQQMDwBu6xfGiZyYaY9o7mr4OqwM2KrfDqPDbNqdItjawLmOHP3JH6C8CC9V2C8EZ1aky/oMmWB8fcWxo/JtCkl+XKFn4EFXi+Rs7vBn+OxNj0MTtRM+kW+zcJbfyx2Gy3G83nRtiX7s4m4KH9o8lvJdTHALGbGwNiXx3/3zVW88Fr3lCufExiD0j7UkNOdyl0ZQcNOdv28qgS0vnflBndfNjK5eEFHG/qOaXncoXVJHiUMaO+LlYDEpwxx9QQvszmMBxPHIXro2jEMAAAAVAN34B6rWiOhdtHLzHTngjemp+EONAAABAQC7qPUEL5GreTTmOvKwZRoZPUhU/NOO6vUPJB7bGNnqE/nchk00lKH4iRRarLiv3fFG+pOv++Xs9Teh2FQGcEHalGtbpPkS2hbV54i9GvQyIFnGXIDyjHPaKnnsMsUad4JyJ/E43OLZT7RNHRX9kuoL0P25qJGMGeCLX9ngl+gvj6g3322heV4B5bXCKUUVndhb8WBqNo6ym1GTgouWQNddANTeGxDIiM0PYYjIJwtXy+ITXLxsuvAB7Lha00NYuWJZZYovIS2L7PeBhH47x30giRe6LYQBpiw4W9H+7WpOLM/kVifP12smuxy9cItcKkhQ3oKe8zxDbPDV9XKhscibAAABAEI5U/xp3WPp7AwP+slys3HTvzRTcpKjKXDyMcW9dH6NjJg50DyJfne0PZX27mQNEyN2BQxuTfMLMa+aNN9OAMEfr7wZm18kTpMbMj2u1+YxPVxmUTwS540w4Rp/LV4RF4MuABdjjx9Qfja3MzbSyz4QUAztWu49kBQ1G0ksLEtceTnX9IvMldEuyp9KkHu4VJiwgpZgTKTht59PSVda+H7870U1PttDMvvkoVNBzIH6BDh7CPqrgj5R3jndv1N8H9rmX/jcQ1Y/7omzBLfDTNVQsRDNAsTu2w6PFgYRYylorzJEJZPubFpKPjALYqLjMsV58rR1uPrax69glVKtQiM=',
            }
        }
    }

    # RT 6895
    class legoktm inherits baseaccount {
        $username = 'legoktm'
        $realname = 'Kunal Mehta'
        $uid      = '2552'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'legoktm@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC17bogEBqaICwvnLi3RHl89/qqmliaQLkKMsMEubghU7Y0ntnRA5C1edkzzXT6fdGCRsubhflfSogSZLErSp0x9gR6YmPGYKn1OGbLK/FIpEdcbNd/zGBBF1U/9KSkJLgNKACXDRfMcqyMpnAaGDcUDdUZaRJ7nOJ703VH5pp1ommdv3acRWTPQ9hF1WUwlXPAD2VjIqJKrVPVMqVafcbPNO9FVyV94dOKURUPRmIPVxGWruLB2Dp+a2sZqh5KBR1PkV5wpBRev0IBOAFGE3aG9fAB+Xbj7bppTd5ov8EILU8xw0Xj9eFxiSuBWZ4b+rWGzKBj6OPm9TNg+pSGZr55',
            }
        }
    }

    # RT 7004
    class rush inherits baseaccount {
        $username = 'rush'
        $realname = 'Chase Pettet'
        $uid      = '4610'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'cpettet@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC+IUUkFX0t/8UqTZJFRJ6JaDPvwIOTsGu2mIg7OGA0lDhJH8eRz2dCPSM7Z4IwKPh92mtct3+aZy8ziT6bb88TNESU9n92m4HdHogOLMz/ksJW07oY2fTjXs9DeaPZUP5Sf8uSrU0ip40wPn8fDuXIjEX2MhUgzafNk2nm0+VFqdU+p4vMf8PvTjtjDMqhq0r9mml0YH4T4kknibwAWlcJaM7O29FlRWoRsI2nIzde5fYASdvrstPN620EScBQo3vAlfbkQCvxvWpr/xO1DfkFDUcIOmrC5uWbOKrGCZRLfnOQTBaMCjHcKmEPJ5YzII692G3BTvbIZ+6AqnLSoA81',
            }
        }
    }

    # RT 7120
    class esanders inherits baseaccount {
        $username = 'esanders'
        $realname = 'Ed Sanders'
        $uid      = '2875'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'ed@ESanders-LinuxBookPro':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDPnesJV7Wrq1QxdtBPJbPturV/sVX5rUE3kL3n+hhYyxLcId95Abkvf/p1WC8Fulv99wS+lq7b+9Pw64mA/mnuE0xljoBvS/JXQEM9Gls/BTBffmomm84kidrmUxCeMHcRuFbL2aPc3lIm/6N7unB1VvOyAM5oY1I3Zk3XHHTOHmpqMFS4R7bWWrkTJZZ4dNZffhYqMQRQgiey1b+JD0/pIPy2PQwyECvAC/3Ms9QY1wc4O5k6cQMYhqHEJQ9/qruIRB7sTEhpXREwcJYTdXkhFU3yrmPw1KxpQqe5+44u4asR70AE7FevR7y1rR6W+kg7ityfXd/dzrpIYwsFhjKJ',
            }
        }
    }

    # RT 7169, 7167
    class oblivian inherits baseaccount {
        $username = 'oblivian'
        $realname = 'Giuseppe Lavagetto'
        $uid      = '4816'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'glavagetto@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDgvoqNH9PeT3G40RWDnlka98d5HYzkDqTTWkxRhkX5TtCgo3ZgNMmTWigMteXhXBZWjhTFctIhqOdkyGQrGoXeLs0TlNFlZ+w6Zr0kbkeQ74pkqKF7J+v0qDMtlSVfLcoiWqYBGrBuzm6CxIbBHbaOBUxvOPq+XQBHGRdsCP5Y129h0/3+eIo2fLZ5n6C/s5vr6l9tl0TgolEn9g2RVp59UsqBTffK4Rg+CECGsc7qmeIfZKmOZZ3lL1c5sS7hV1hbRV5lC8H04nxR1Jw1Y/WRWQ0hGvr6WHXrLUUgSR+/GuSihlAB5T4+PWnWlJ6LPsucK4WSuGaK9legJi1O4KncI5bjSw60KrVNulvK1fLOuUb6qz/CRFMMhX/NYDoS5Yc0ducZbFC//NMxtD+UsSFlL1VKQ1oEeDM+/4VqM2KK6mEr2X1MmBf9LNG1G1k+e5uEHOR3powwGUmp44tHrSilcGt1o8KAFb+Vy1fbVqngFaAm5SYwKvAJcujqUDyxARb8e/06XPCQ0V+wx3xBf/Dd3mWHU3OqN5itmEUqDtU/Y/P2/O6eI6rCMh/+4gclJM9QqPEGHhQPGrLb2g+KNolrsZ/7PyYbMtEf6Pzsohcsoz+nf3/LN1cyf3AzSKRPNy6pD5C6ZpVU2AZwqGwx8zemXhoyLWa0pINOaCP/FgVDpw==',
            }
        }
    }

    # RT 7243
    class filippo inherits baseaccount {
        $username = 'filippo'
        $realname = 'Filippo Giunchedi'
        $uid      = '4849'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'fgiunchedi@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDt7HkyaZeIe7L8CuWE1+N47+wDT/4cUmEcrPA1xgdA4By/jesf+1oOTvusbIyXFuCssvspgGmwwNMD+PzNF3xAEo+Yn2aqH4OBhRiF0U8jeaJL1EhzKnT8KKG4fOzzerbKFlE5K9LnYhMXp2i6MoAN9xB3Z350dBwqhspf0OKqZ8AGbsc9RdcEr2pBT7RPRlcKXRTrd47keV+PUazpDVSr2MCdmErknROpcBh5IS27DrKHpma3UcNUGIeMsvsV6nyt8Tz2+EMGkd+P+whij0YzlKDkqB2ppoD+gCPAki277wobiocea79fvPm1/Na+tpXJT7gU+YErld4VRvUclyR/',
            }
        }
    }


    # RT 7345
    class mhurd inherits baseaccount {
        $username = 'mhurd'
        $realname = 'Monte Hurd'
        $uid      = '3010'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'mhurd@Monte-Hurds-WMF-MacBook-Air.local':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDQBxj8NTkCNQZse19j6fqa7zFF3kETfX/59zjBeAu2sfbP4xOSzSlJjcIEmqDbruX2HGbX51amWOW5WGFtWw1T+zBnbaMXtTEm1U7EtEwGPF7wq5FAxCO8X1qtAXM0Rsz4+5ka6bcKBxD9mAqPeIDirfPjJR1L4BDY9H5aPOuVYj9lna8Ln6tmFdqk5W+czMfIZVR7fn71nL+3xllNpQY/8utviYo5+J5sihHZ9h4DeAGYOrZoAgf4LVBeKcmqtyaOTZar8ZOTCF9ttV7pZ2bNw5vCtQbN7WqyDgpYjXAPW+7T/JUMXdxRxGlpS9XyBzIqqBxytu3Kto45lhJgNTxp',
            }
        }
    }

    # RT 7399
    class dbrant inherits baseaccount {
        $username = 'dbrant'
        $realname = 'Dmitry Brant'
        $uid      = '4910'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'dbrant@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA4PobkGWos52aZE41QWS7nrTam3UQ1Fbyt3PoNoUKHneK1wNpBL0EfRtKW4lAX61ntxOIPCFVRxMok8TXnDb3ZbVa++Fqn89ts6iqfWlH34MxGYS5pxvdrdjExeREQ7d70gsEOv9RZlb/qchuamxHqLsptQSpiy2miPWTkRuNsbAJrFw8K5GiLqr60sBrsLlVbsEdbbtaz4itvWYLN3qAKgk5O24AT8lGeTsTAVpfMDcLR+omRoLs/eRNGifVfDslwp9F/rpNCvpSan4wfvF5Tsuc/lw3Wgc36LOiyw5o7C0NSWZzwmYCNj5vkPPF7IwoK3DhYYjPOf5WNCtPvN9utQ==',
            }
        }
    }

    # RT 7425
    class kleduc inherits baseaccount {
        $username = 'kleduc'
        $realname = 'Kevin Leduc'
        $uid      = '4906'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'kleduc@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDEN1wN2xn6tRzHBb0VrVMBE+ZQRvDFLyj2fPQpN2KQucMnXj8GlLzFJzXmW5Dwh0bAfhXUxAKudfAPLuRtnBz+gl/d17vmDRwgtqHIaMWWW8s9RFW3NmVj6wEA+KKV2A8MlHLaFUTL5egS7cAicK2EbEC4ej6+o4ONj/+Qo9h6niX8U0tMohTB/Ml6H08Oe9NJ6e3L8d/e9Acxmspc1id9bN8ek/MGwFGMYTC7WQHq8TVUgq5xpA6vbkct3sNON8ebHmaTR3ryPpr2Vpxz6h088eifDwRJMD5eSqFvLzt6iEdZEwNfqlbigGTwbbAUNBDNPNhzTZStDpa+T3OgIiOH',
            }
        }
    }

    # RT 7506
    class tgr inherits baseaccount {
        $username = 'tgr'
        $realname = 'Gergo Tisza'
        $uid      = '2355'

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname] }

            ssh_authorized_key { 'gtisza@wikimedia.org':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCpZLnfaAbbxvapFDFwIg2kYLn+6Xk8IvB9WXfY5TU+tgakaTynli0WgZYwNVY/cFYnXuBL+QoQZEgj3RUQ6an2URygck4Y88WcHT+9WzjZXhPWBxysfeClbjyjhNFnb8qfWep9xWfIDZp0r+K/hgKF9rAUSRcCUVzF6GRVZ0F52W9fTNxW5kT5L8mrSG+t8vV0IQT1P8IL43I3yiXJJhaAm4nnZJOALBl9rKLJD4wFPKp0P0yJ9tZgTEIzubDusW9cjfP/2niiCVItUyAqlU815AoFiyx7GkT0hWB6FxLHVA4ch06+zI2f2vUJR2w9P9jjYjbophu/fT/r7ov0PKnH',
            }
        }
    }

# / end regular (human) users

    # FIXME: not an admin. This is more like a system account.
    class l10nupdate inherits baseaccount {
        $username = 'l10nupdate'
        $realname = 'l10nupdate'
        $uid = '10002'
        $gid = '10002'
        include groups::l10nupdate

        unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

        if $manage_home {
            ssh_authorized_key { require => Unixaccount[$realname]}

            ssh_authorized_key { 'l10nupdate@fenari':
                ensure => 'present',
                user   => $username,
                type   => 'ssh-rsa',
                key    => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAzcA/wB0uoU+XgiYN/scGczrAGuN99O8L7m8TviqxgX9s+RexhPtn8FHss1GKi8oxVO1V+ssABVb2q0fGza4wqrHOlZadcFEGjQhZ4IIfUwKUo78mKhQsUyTd5RYMR0KlcjB4UyWSDX5tFHK6FE7/tySNTX7Tihau7KZ9R0Ax//KySCG0skKyI1BK4Ufb82S8wohrktBO6W7lag0O2urh9dKI0gM8EuP666DGnaNBFzycKLPqLaURCeCdB6IiogLHiR21dyeHIIAN0zD6SUyTGH2ZNlZkX05hcFUEWcsWE49+Ve/rdfu1wWTDnourH/Xm3IBkhVGqskB+yp3Jkz2D3Q==',
            }
        }
    }

}
