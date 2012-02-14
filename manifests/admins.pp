# admins.pp

# last used uid 587

# TODO: completely rewrite this file

# NOTE: To completely disable an account, you should
# 1) set variable $enabled = "false"
# 2) set all ssh authorized keys to ensure => absent

define unixaccount($username, $uid, $gid, $enabled="true") {
	if defined(Class["nfs::home"]) {
		$manage_home = "false"
	} else {
		$manage_home = "true"
	}
	
	if ($myshell) {
		$shell = $myshell
	} else {
		$shell = "/bin/bash"
	}	

	user { "${username}":
		name		=> $username,
		uid		=> $uid,
		gid		=> $gid,
		comment		=> $title,
		shell		=> $shell,
		ensure		=> $enabled ? {
					"false" => 'absent',
					default => 'present',
				},
		managehome	=> $manage_home,
		allowdupe	=> false,
		require		=> Group[$gid],
	}
}

define account_ssh_key($user, $type, $key, $enabled="true") {
	ssh_authorized_key { $title:
		user => $user,
		type => $type,
		key => $key,
	}
}

class groups {
	class search {
		group { "search":
			name		=> "search",
			gid		=> 538,
			alias		=> 538,
			ensure		=> present,
			allowdupe	=> false;
		}
	}

	class wikidev {
		group { "wikidevgroup":
			name		=> "wikidev",
			gid		=> 500,
			alias		=> 500,
			ensure		=> present,
			allowdupe	=> false,
		}
	}
	class l10nupdate {
		group { "l10nupdate":
			name		=> "l10nupdate",
			gid		=> 10002,
			alias		=> 10002,
			ensure		=> present,
			allowdupe	=> false,
		}
	}
}

class baseaccount {
	$enabled = "true"

        if !defined(Class["nfs::home"]) {
                $manage_home = "true"
        }	

	Ssh_authorized_key {
		ensure => $enabled ? {
			"false" => 'absent',
			 default => 'present',
			}
	}
}

class accounts {
	class aengels inherits baseaccount {
		$username = "aengels"
		$realname = "Andre Engels"
		$uid = 587

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"a_engels@i-000000ba":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAvmCrMfy+q3k/QCG3T72Q1+BhnsLFBSFzkDt2fMouweztuaFEAGA3KqYiJM5P4cm81ObjU2Nt8wac8vRWhGjmI6cOUl6Q3TD8/Cry9ZOQB9aQ80vYuDYCNReD+j0sQdGfb+T5OGsIVz0yB7H/COJ9mNcxqXIjChG17FxJcp4RfhOH0mWQiYQ61ZGMLn1MUOZC/tV6C    ypVFpnuTvVNtmqeBJQYWR9Q8+lLjEG14to/gyYR/3958RGFZgk0Byz0G8E0yYEg6PGZYSMEVTEOEqP6JNflqk4XK94pFmRfHt8rDs7cFTqa2Kn6etAiShvZ5/rQuEoveU6mQtnkaoVvARVgHQ==";
			}
		}
	}

	class aotto inherits baseaccount {
		$username = "aotto"
		$realname = "Andrew Otto"
		$uid = 586

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"otto@hundchen.local":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAw+oSU5aOOAxlmjTZvJnOEPbOAOchKKeTi5RO6KIVddIVXspHbBZKhuBmDLbppsB2x/kA5XYC0otA/FD1Ldr7v+OQp3XRTUlxchjGKci91ztPL4WbedCR33DUjjZW4ro2XlvoSLgH0vIZU8B3a7a49BgtXIPxtXw/evmzRmRfguNam/pvVfv6AE+1NGNQGadLNP2nHTjd8B2WEC1aVIblk3ZOsLsGvvFQQvuwLdMsDcK9/6Khy6rE4fYXJGd9ucVYIH0V/487Syg9tvk9xMEX46z4O38EV42CVhBm4ebpQ8roJJwwuD7MGIUeRicylvmVHHd+KxMqB6VkvGYIUXcasQ==";
			}
		}
	}

	class ashields inherits baseaccount {
		$username = "ashields"
		$realname = "Andrew Shields"
		$uid = 569
		$enabled = "false"

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"ashields@local":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-dss",
					key	=> "AAAAB3NzaC1kc3MAAACBAK2KMwlLfnArieW+Obz2e8V+7EgK+9tsX+eUOyRM6MDNHLlxnSLr9b0EVpS6dBtSaWt1LcfZtSBGAJvFBloROZBRDup+w+N+S27QTBdfxLtsnn4j16zHjaF/psameua+f9onQ8yK4lAPZfxpvY/6Fr0nt9skFTrC60V3kgdu18WJAAAAFQCHIvPCAB6Yg56Ha2ST7JT1iorrYQAAAIA4F6foFJB/PJ0wcySUVlXYI0KahgnZkQDnhsPebX/g2L/5/IVOCOxDH5EttA/w+IsmArO9Lrj7T8fAvs8bykaYOAhVNdP2kLq387T0LgBD8b9eexK0zdbhqoHDiyx2+Z80gaewKB/tOVzhE0QCN3Krr/ubdI2dM57fzjygDCp1GAAAAIEApbMDfrRfJZk0GL14ykKDj83bHUfjn/KrH+BULMctePytaIwfDjsKvy/ntj5mIglipX2Y2QL7H+/pEGkQbP8SdNNb8tEb2iDjq6jKKsKB5lFfUHX5rk9sUfViEOUNJ6JJCcSVMmj7hgVWKA2UdI0XQuaBoxEARVXtLnCp5LGcDbw=",
			}
		}
	}
	class austin inherits baseaccount {
		$username = "austin"
		$realname = "Austin Hair"
		$uid = 548

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname] }

                        ssh_authorized_key {
                                "austin@constantinople.local":
                                        ensure  => present,
                                        user    => $username,
                                        type    => "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEA7DUF4Y5YNJpMJsjuaXkJ3yQlamEWIahV9l0ASjcQJOmokjg78bThu5jqOMK7+ekqmlPRrURP7qskh4fi3KMwltJpWDunKKRSd9iwpB/19MNhB7KOQITPz6XgaSTQYLhxjzVgZVrIbbAdw60uv/BIaYCEae0FPVz6qxEx6Y0Az4rZ9kA1NODXOM42Bimg/VWetXPaBEEhcm6D9v4Ut0ZF7dE7FG9vUVAAwNwLyJWWAozxm2tVyOKTtSVKkzv7w3X8tH6nXC8blO94h37oIX+c+AHzMoswsuj9avdMEEQ7/7KC8DQAbkyrZtItqWCiRnBXcHls1kABaGGdobpeeKt0Aw==";
                        }
                }

	}
	class avar inherits baseaccount {
		$username = "avar"
		$realname = "Avar"
		$uid = 534

		unixaccount { "Avar": username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			if $svnkey {
				Ssh_authorized_key { require => Unixaccount[$realname] }

				ssh_authorized_key {
					"avar@Rancorwe":
						ensure => present,
						user => $username,
						type => "ssh-rsa",
						key => "AAAAB3NzaC1yc2EAAAABIwAAAIEAvRT1SgaE5Us4I7yMEQEOhT/A4dkOnar036SLOfnYZ4pSez/rYFwO7IRkkvx5PbC/1BAUztJESW6iVVpbGoYyYCI6qoLJ5/Bk3RM7HCfEe/1HIIPsaKNOKkUL+M552DKNKynUAtoBOQk5c7oSrdKQu0LZqR0Vh3zLfhiOpidL6GU=";
				}
			}
		}
	}

	class andrew inherits baseaccount {
		$username = "andrew"
		$realname = "Andrew Garrett"
		$uid = 540

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {				
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key {
				"andrew@voltaire":
					ensure		=> present,
					user		=> $username,
					type		=> "ssh-rsa",
					key		=> "AAAAB3NzaC1yc2EAAAABIwAAAQEA2Di7q/bc8OJ5HP4X2U19r8w/mIH6CDbZHkOv//5cNvE50udM7McwxRWSz5idIF2P2JyIU2tQhixM3vkWO2chcifIom60F2/vhKA+TuUr9l/IbnBv6CoCjeAxre0g3gVhcazHKKtjbpRMYRxMSrLs+SBzsQpTuB/MqJB/jy1rUDTLCwN8Dtz3nAR5vRtgM673kivDLvDsHrfgR1uScESawPe6c9iFLbnzptH4z86r98tj3s4U+3yVFaH9AG7YuovulyA6UEgXFL8swsrpp58s1+XIausfYAqjetIL0YS3vOwEeBw3Hg57c+bZ+dVODEV6wc+uOgtJFZs6zVHTFq5QoQ==";
				"andrew@zwinger":
					ensure          => present,
					user            => $username,
					type            => "ssh-rsa",
					key		=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAub5dQVlS7jvr0e3Df+5xDYXqEmROgb0vpEkjBlJwl7Ak+J7k5bfQL+YcHs0oPyjLEJ4ZxwN4JQw+AsB9Ifw2eFIFB+tlKmXj++d9I9PS/IY9hSKJHJ8Og8uqK4X08tqURnyfL8QvH3g+VuSuCTwQcyfIm0MVKpJ5/grpK+Zg3OYSU4JQJpa4TDcJpJrx+V6GCC5yNJshs2VSsXyUZYWHaa3r+MXHE+KRZDlVP1tkQhzdK1g+/vcp7s13+QaWioiUDbxkCN63pKxY5qQwOugT31EEacBOCgXsS2jY00mJ5KpVt0zJychsX7WTtNfk6Rt9u9xt/imghT80rCd97P63Hw==";
			}
		}
	}

	class ariel inherits baseaccount {
		$username = "ariel"
		$realname = "Ariel T. Glenn"
		$uid = 543

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key { 
				"ariel@ariel-desktop":
					ensure		=> present,
					user		=> $username,
					type		=> "ssh-rsa",
					key		=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAwaTYlLZ90/oQ5tDYDkhI2mHa1L6Vh+zcekCt8D08N7/CrFI5sUVteTwMWw2ytQlWnyT3HVgHb4IS1EPjpjyuqseRcNW0HYsqBk3E36PCBQIqjLZ0nDAeHQtm6T6pXiKC5qUppghwrvDxVYFpF3lFzAzfYMrF7iugk0xRPTHZWm8df7dqIB/6FfbxSD95yQVAlJefxoFWbo3Yn+exEZQvWv6lQYXnjV5DSwMf8tPGDkc2DRjrnR52ZrXPRZFCqc9JGkA/l8QsYtjmqJdnOgq5raOb56aRulJYdP2j//B4lRJJlglMuj8dSZE/j04zub+P2QhfdqeEHmeaTUqbwcnZZw==";
				"ariel@zwinger.wikimedia.org":
					ensure		=> present, 
					user		=> $username,
					type		=> "ssh-dss",
					key		=> "AAAAB3NzaC1kc3MAAAEBALcKsz9HL20xCAB/hWLUxE/26tdeZBQqLWlNiWUC1ilKlqYtHL99ffkrJIlwst+IN/1SOfBhs+5pZxfUyfIT/DaeVNVQXTBfyAXM8iImtY/RsQ9M+v0xhwTLVGs6jTXQX8bkOYAEIZd+x5eGFhSTyIVZmxkz38XpLsTuNyUjs2gFUWZtPGZIgOTToxnYK9mpvpM1gRsHuhLMYg9ZpgFpul41Im+znRcWnrmW6uPAYebvO4V3uNwqdPBh50mrrqyakRj7QlCiFs88zufyj3BmC5mwTNlHClAbVyLyOBY6GCgfof5wFkbvAnYA0iglGZBnk5qIIuPdO+6vxRztUIY3gI8AAAAVAODnUYfx53vWxQVx1GHkzuwSP5JJAAABAEUZuasCiK2tMhQyDIJuad0F8H3aW1CrVtG3ZJuZXjLxpsXQsaOrG/DcFLxKxV4YheQSAVYc098IoQmAiTBc4W++b5lqgu1lmEMwMxQd+o+V8/1ywla61DA7feAAc1H5+eiKUWJDGs9J4HnUiAJc//B//rflE32po1S4Al+8q5GnngOqGEc66u203V/CCtkEbFCOqBXcj36nlTEtxbkbHe633z/TMM/bAwH3vNDo/9Ia/SdTTnQ3XaOD+y2PYF2ley6ImedGrGM71RU2zUv8tmQW8s7/5SygoAWGkljjk3IZy+nYRH232fcWumwORmGvpiq9pPPHhC6zYXjF/5thXRcAAAEAC4uOPvwmzpdwWjJ0QzbcPknWtdc9pvjWC2OWGoJP3VxQckZnWwBEIi9TjxeneX1xU1ZZKQ7s5xcIBWE1qn8P8gNgpqGLVK7rmErN9EYHGcxPR/n0SfujHVo7qEHB0tRhCtABFEpYczl/K/xIfZ7+bCQmvWKuyYETP5QTwbAD5efJh88/kfFKqtI1qhhAenfG3afATU0SHya31HYjrghXZBbA8YvAmX2DfBkP+WYllFaeUmUlvMpnW6wx2+SW0cbMik8CFJIjcMO3NAWppsR3mgSwSGvWorlH6Tskei7MaEUBaYJH01aZbkJOkigGVQhna3tQ2JeKhe37GjednwoBGQ==";
			}
		}
	}

	class bastique inherits baseaccount {
		$username = "bastique"
		$realname = "Cary Bass"
		$uid = 539

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname] }

                        ssh_authorized_key {
                                "cbass@Cary-Bass":
                                        ensure  => present,
                                        user    => $username,
                                        type    => "ssh-rsa",
                                        key     => "AAAAB3NzaC1yc2EAAAABIwAAAQEA390DUZg46zDR+o7PdEMypqqtCzg6rOj+ZP2FXWi8pof3bsGJ0J/bhRqP5/CPwdoAKsqhfAumYj2RAu1m4ikaQ3Kx7bhyCTqYNYpiqvARd2FgACFLPPhht6cG9sgF3KeQk6I1B8/vfx/fjtANQSxT5oRMle+71n0TmRWptdEVflYOwtBA/huIcrqXWR6Fnb7S6HntsNlWboZq0vdget8eB8WhOIPffeX5kpE2AbmCk4RtxiWif5rFjWPtOHHiBugDGhP7y0ljzimeBCmVFcWQ9ySQcQQbBFYj4QLc8B1U357E6HYSL1xNyCgWzVdjpHUCaXBkk4xoziIRuLbugzfwhw==";
                        }
                }

	}

	class brion inherits baseaccount {
		$username = "brion"
		$realname = "Brion Vibber"
		$uid = 500
		$enabled = $svnkey ? {
			"true" => 'true',
			default => 'false'
			}

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }

		if $enabled == "true" and $manage_home {
			ssh_authorized_key {
				"brion@Verda-Majo.local.":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-dss",
					key	=> "AAAAB3NzaC1kc3MAAACBAM1lLHYwJW5sCLFGF70Kg8c7/Azrnlep68ufEZUPGrJkMfUHog0zLDlwVKTm5iRozUxwAidKS4wexcdmvbrz2SG35wsqjmEbd+jc8nJ2RLIz9y8EfzPLD8d0RyMsGYyQAm2mdyeLjMXsvSs8vq5DyBtvn87EUiAZoElmPTHsXQirAAAAFQDpigMj47QooCg5ql3YwfNLbHYP8wAAAIBWOJEimpUdjQF6FFEotuJc9G4FRHGC6Wpakx12KthAvywmWOCR+BHPlBVeufocCzkRxteCZeMddDi8EimXJJeN8CitsmYZCFFZYIkY2nntxWJLAKRI7LgsB/jjyw45HGO0piim5Phb0pqPjtJ04vaEc2k0xQq8a50IV5aolloM6gAAAIA7LQ8WRvWhj4gBgaCiHDc5TkqJksYd/lY1/hLY2prMSngkn/DLi0bepKmgBRQKFxqEBDl8kPFoVN7kb6qflwD+MBZumyIJmcw3mjgyNdnD/mlgGluAMBdrTKu3BtExyCqZsRvdlDYNFo/Dc4HZ6RuX4HM8MUHvrqmdyvLKHEk+QQ==";
				"brion@zwinger.wikimedia.org":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-dss",
					key	=> "AAAAB3NzaC1kc3MAAACBAJfPpdbExtg6TAGRhCIk0Q3hduv8O6YEPjhl1VnyH86rO8BBQyrT5+bsmcBP+jpNk8+/daN5C6vkPIEGSmBg9pbzAMcbemerZw+t7nFL7PCD9b+L7y1/UwqXwrqnnJYTnIqBb+oR95u1E+DEh/j6+N5VFuKmSRZ96K+g5OuDoAkrAAAAFQD0PDU8fmx7Km/7XvzaU1zHHGUSrwAAAIEAkfK8xRWF7OtdVc2+UqVyWf3pnAvGgpsPdoZvVu57O/YT1nbQLIBot6v/5GU+k1L16OlUYMmD5DYR67N7dqbY4tOer4591/qLFErMsb/o4n0/c1hquOZk4Kj53W8JD1eA+kQ+Cp84/oQ0p1+O1GgAzo0PqWOdKSu+WY4o3yDIrHwAAACAW8bxIKTVNZTReUWGHdvFrdDqDvLKkLTvntA64apMh8s0cG3L9PbaKwVibG+hORyiH2ETviy4x1NNKhniCigQFTKr6KhPv6+G/95s14tPo5CTFbrA7WKngbr1Y6qT4a4e5QhW0ciQQAW3cBraYIGGeERz+vAxnkadI1XhiBc+1yk=";
				"brion@smidge":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEArC590xpWpe26evaQ424SBC3AnfHy7yb5M84F/3Wa/Pwb2Uh1ujHYmVHHnYee0ChWfsNXc3lHDlH278v//hMDagxR/O2sCjCjq9loyQQnb/t+f2INvrtna/YPRNO8nxH7dMT1mi4+i0LFlIkxwjwvNWoqJpZQouwckXzV44Ssx61IWR7S1s6Q9jthUa4O9U8Ffc75IQ4NgsGMcZoKS7lpqn7xQoVcQQ+RsfNLcmekUZ4tSdh3qp8R//Me6dg0h62VWucvjey6uLie/TW9y2TgT2XRxxLGZKWyp0YqVzZF2r2AZLvB0yxlb30+/qxTKzs9g51dUg+d8M7w8gAURggjwQ==";
			}
		}
		
		if $svnkey {
			ssh_authorized_key { "brion@stormcloud":
				ensure => present,
				user => $username,
				type => "ssh-rsa",
				key => "AAAAB3NzaC1yc2EAAAABIwAAAQEAmi7DfRt6vSuT7oQLE8kBjXN6tZvskked8ZHkAhwB80d6yuSa317XqMzYrxzU2SqDnprNqZZTdK0i2l7G+X8jLodTADrTvxX3oANQy9ConVkXFrd6+qfZxUs6y8rTMX/FPNxCCK/G7iQSg1GjMGzyIwdOwHPOaxx/ASJFKNbCbAhxaf/lRUdz/rirPm11KcS/h5qplA/G/Kbcgd7oopBBXnmmEPLEyVI0agIBNb8E4r7GNXikycJqPON2Wxp3id1Fs84ALacStTs49ZPtynUuRhprslhN3z6G6uliighcc0PzHMRSR/H8zjBREfqcfvAgdqSgn8DSqIv2bzWDjcNtOw==";
			}
		}
	}
	
	class cmjohnson inherits baseaccount {
		$username = "cmjohnson"
		$realname = "Chris Johnson"
		$uid = 579

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname]}

			ssh_authorized_key {
				"chrisj@ubuntu":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAADAQABAAABAQDnDmdyh5Stw9bMTm7qL1kWuNpazc1m6HiaN0ZlaqwbUIhvtADWobHZcHvTHMwyauU/X6joE+a6pyvYgM2hr6+wRawjmgOuK8cak90weyp+i20HCiPb5GqOLE0uDmDizI8Hb50kxjiXLF6k+7cT7i0Lksa9EKhsYEwCjgnOiGor6wEvN1RlwRuwNBOZcI6OUvV39G/VP/pjpZBeUNoUZHWgpr9nbX+rlctjzK0s8sRbUamvCG3lyeB1pNIVCkY9YOwvf1D2UpRnhIm3XQspojphCFzC6HqRqZOyygweKc98fmvxkbkiyzh9XPtKyV5CtRS+9ECUmZjfmcWZpomCN2tp";
			}
		}
	}

	class jamesofur inherits baseaccount {
		$username = "jamesofur"
		$realname = "James Alexander"
		$uid = 580

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname] }

                        ssh_authorized_key {
                                "jalexander@wikimedia.org":
                                        ensure  => present,
                                        user    => $username,
                                        type    => "ssh-rsa",
                                        key     => "AAAAB3NzaC1yc2EAAAABJQAAAIBt7ePL3ps6MVHEAMGdNHVd/lO2L3Yc0szq/M5gSino+bNmn7yOmNMk7QxVHHwsPOBPbEuBhKEUj5LC/K5oxMT4jOW5lH/PTGntsHNK+42nLsrbkTV20MVZerf5JUw7y/IL12RYzrzk6/uvA5LqBLGucha2yi2llcrWCzbvlnxTUw==";
                        }
                }

	}

	class pgehres inherits baseaccount {
		$username = "pgehres"
		$realname = "Peter Gehres"
		$uid = 581

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname] }

                        ssh_authorized_key {
                                "pgehres@wikimedia.org":
                                        ensure  => present,
                                        user    => $username,
                                        type    => "ssh-rsa",
                                        key     => "AAAAB3NzaC1yc2EAAAADAQABAAABAQC8+5CuJlnFqzlYcs8QRu42ur5Y+9yM5g+uQIDYX+3SRA1UzOOOmj/Tqv0pzGhmvK15/y+Vz5LwE927fcI9VwAxBpCgfcV97r68aDF3YD4Zqo8ksV51GhRwk2QPNlwvCtf7+BMCLFt+ymLpAIsq3L1YReovJgfkDHvOQrujXH7LGd6tEXaUksqyn9L7TTbFEyHUZxTkrV33OOlaSxIJM1EZu1fsVSL0LppmXaLH1bi4/gPSbw3A4l8EAttWAqkvK0zrty022wn/1JRa868/OD3WWCoDNp4SSH0DisURdPlT4Jc+q+P6+P/RqeWJAx5IqEQhVg2GxW6BMIKQP5VigS5j";
                        }
                }

	}




	class dab inherits baseaccount {
		$username = "dab"
		$realname = "Daniel Bauer"
		$uid = 536
		$gid = 536	# group 'dab'

                group { "dab":
                        name            => $username,
                        gid             => $gid,
                        alias           => $gid,
                        ensure          => present,
                        allowdupe       => false;
                }

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }
	}

	class daniel inherits baseaccount {
		$username = "daniel"
		$realname = "Daniel Kinzler"
		$uid = 545

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			if $svnkey {
                        	Ssh_authorized_key { require => Unixaccount[$realname] }

				ssh_authorized_key { "siebrand@remote":
					ensure  => present,
					user    => $username,
					type    => "ssh-rsa",
					key => "AAAAB3NzaC1yc2EAAAABJQAAAIEAuH1eNAxPgzMG0GoCZBtNx/eTnneQRT0Z/IZvbj0uQusaNlSG7MlFrUEI/HWCwIcWZlAdMBCvp2Ywc7+flvgH+JuBzbjvXDhhkC9o0/9wxKEwGRnP8RDnNBlaouzk/ROP4m8L2FZahAahFzoqDqYxzBl7bQ/iw+N811rAo+R0AGU=";
				}
			}
		}
	}

	class dzahn inherits baseaccount {
		$username = "dzahn"
		$realname = "Daniel Zahn"
		$uid = 575

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key { "dz@ubuntu":
				ensure	=> present,
				user	=> $username,
				type	=> "ssh-rsa",
				key	=> "AAAAB3NzaC1yc2EAAAADAQABAAACAQDY3GzbCE2eOM7IxQClHag9FRVg0eryA6PVa7p80Yp4suPzW73KVv9BgbSDvkdGNv9NOsVqkZkp01oZe7+XVxh1jaxM60nkF02DGKI0jn2lbzzWR5YS6gabjjn9SaOnh0MAwC8Jpvdz/YKOyE9/PAIFXajNwTuE6alHU/nWnLHaR1FJQRlfZLDlP9deNRAPaXOyn/jbO+ODNQIFeKSV0TmvZAh994wUlLoDYa1UcuqTRc9tJBmpLALVPZs1U2FZvLr7fkuOnUhcOC/uqE/pDdalSy0k6bAh/pkILOMFzhCHtrsbUV0AT7cVBogE7qYRuTo3eBrpzj9Bbsi41Q4y29lridBoyBgEMH/fnEIMDivNLzec5nYLPJ/XIDSc0G2iFoWY/u7SaVT7A6rjlSuzS7owunNXEj1mhmNW7v/FIOqG2Zl3K7INBj8Y0rFL9GuwP5LIkZxlNZT7NEdUOA3i8L4sT3YJJgiaup4Ss66TpWCDQ/znZoz5Vi5ODhXjqMVVFbrHI/7eIYMChoR5HkcRdjaIShvFgSfWcKXlwHouIVUiXprnoZZGmAa9CTAx9GFrjgC7DixK654yx4Gb47q4dttSE2nZKY1njfDRHcbLRuZ1ESEpAcoxkos1agvShw5B4ysSYRcMHkF2yqi2srq7Us19JWCmLm2RW5z+4xPBAfEMcw=="
			}
		}
	}


	class jpostlethwaite inherits baseaccount {
		$username = "jpostlethwaite"
		$realname = "Jeremy Postlethwaite"
		$uid = 577

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key { "jpostlethwaite@WMF299s-MacBook-Pro.local":
				ensure	=> present,
				user	=> $username,
				type	=> "ssh-rsa",
				key	=> "AAAAB3NzaC1yc2EAAAADAQABAAABAQDnBJKG5HDdWCOK9Ow8xPZpjQCeFlkIY6nPKMIpcM47uJPfZC6V1OmRgbTpmcaC1QeMzkZEeP/JSInkgHcuGShaZRiGKd5dYVWVEl+SLuS1kru9VVbX1F8MTn9OFSuQRYVq8r9spvUDVWIJvkAsdq5WR2gJgrhhspGEXCIzP+Orcqboj71oNaq9TUUhhZS+ueY39Sx6h9nH6k180/BxIudmGS8TmUQXyI+x3NoGDXUoxWpug00vTZNdssKU0943c/8CsVtNNEbvCzGQ9+Hh8XlHrp70FJIfy3wQLNVIKF0EpZzhHLUTiul7zrmTc9nBMiN07gzWHVQlAeSjsZcvTD6z"
			}
		}
	}


	class sumanah inherits baseaccount {
		$username = "sumanah"
		$realname = "Sumana Harihareswara"
		$uid = 578

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key { "sumanah@sumana-ThinkPad-X220":
				ensure	=> present,
				user	=> $username,
				type	=> "ssh-rsa",
				key	=> "AAAAB3NzaC1yc2EAAAADAQABAAABAQDLxspOGfRjS0t6C7j2WVLFjxy5u0rdqt3gm8/RSZCkGGqpzdHNfRGIqWAd+BfKTAPwA1dk78p034bfAm6Rmyy8vsCX3+Rep9ZgwXuAguBZsMV91qumT4wG2gNMH1yuMFxL/TZzx7gZeb/Qb5VFpZ7qvmtWnwBqQBWoKg5qDGffwHJRS0CRxbrbB59mbJXKyEqij2FzFcTpLNIg+waBhAPIrjpzSBv5WHeGkLwx/1DS6McjuFifyNMl3FXLv2JBUYct0ja+N57aASXSHKBsQxdvMYM7FMgmB3+h/okX3NMrHcDLJs5kINepy4Mve7EcNZwUZb9m4f0zywFA16wzgukV"
			}
		}
	}


	class erik inherits baseaccount {
		$username = "erik"
		$realname = "Erik Moeller"
		$uid = 503

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			if $svnkey {
				Ssh_authorized_key { require => Unixaccount[$realname] }

				ssh_authorized_key {
					"moeller@peace":
						ensure => present,
						user => $username,
						type => "ssh-dss",
						key => "AAAAB3NzaC1kc3MAAACBAK+lRTWsGdEVTUMpERPE2pDREkNPXbNhFaHx+LZdfzCusOD6DRqv1yposhhjkMH4a1WpLxw2PM6Ew+YE5D8bJ1UCPYDDt7sjLXkVF/OtynNZchl+Eo2haanZzYzaRh/2+aZNoXfJ5OrpBCYAh7vt9a/aHKB3rKxgAR81rdjZ78gVAAAAFQCLF+CasSOhQIK1li8z5LIlpeUj4QAAAIB/QzV7a9w8xSjJbpfiUgPNeGBFTuZuizKUoygNPEgoPcKlaBT/0WuHfwshk5I6UKFwT0zkf3Ph8xdnwR3C+diM5F8ecJxVDIJjnSmNbX8FLYxkCqiawQMtlICIp7t3yHCJ7ziwG4yb3ayp0h5hfJ381xVoYyZe5XfLHUPziF8PKwAAAIA8LQPhqnGLa7TFW0Oc3exIHbEKGdH0I0D9BpgRNmGH5eOfxhYqm/DTsM9tN40XT/MIKb2dJuwIRXluCs5I2zThblTfVJzba71+uI88ou0s0iglfF4X+KdDyV+6ZR2N2rLqxi0QIJkobg2JUjUSmgzad7TtSPa6cc66AdMGjbhMhQ==";
					"erik@zwinger.wikimedia.org":
						ensure => present,
						user => $username,
						type => "ssh-rsa",
						key => "AAAAB3NzaC1yc2EAAAABIwAAAIEA2FOxgqYXUNKz/wcmyMY+dJyH9zStGNd4vM/RGjo5M3AI7J1qZpzVgJjphtrH1O8K8eJw2LAxIuqWt2MnHUzjCvOIT9zrMbZzsCGE81po88RTtZBYW9321/KnFpnuTrfAtQagRyge7KX/8TrRa8iE0CTuRB03sIH1BtF4U0OSTmc=";
				}
			}
		}
	}

	class ezachte inherits baseaccount {
		$username = "ezachte"
		$realname = "Erik Zachte"
		$uid = 523

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }
		
		if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname] }

                        ssh_authorized_key { "rsa-key-20040727":
                                ensure  => present,
                                user    => $username,
                                type    => "ssh-rsa",
                                key     => "AAAAB3NzaC1yc2EAAAABJQAAAIEA30NTewvOFOErJeFtgi+Bpf52+aGI3fmQtOgmsmBIIdnMXdJAdduKZU95OIvsCVCpGKdtT602Twp3R4tOoe001ObTDpF14i28zwYcXgk1VD+ErPpOqcO1S2Ojs1qAaOOGEMCo/yDYkfgT7qLiplX3q9JdVDLkSlVvm+NiWSmzqnU=",
                        }
                }

	}

	class fvassard inherits baseaccount {
		$username = "fvassard"
		$realname = "Fred Vassard"
		$myshell = "/usr/bin/zsh"
		$enabled = "false"

		$uid = 542

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }

		if $enabled == "true" and $manage_home {
			ssh_authorized_key { "fred@depthstar.polanet.net":
				ensure	=> absent,
				user	=> $username,
				type	=> "ssh-rsa",
				key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAudXr3BJ9jDtPIJhZhEjk9JLynjNR/jVknQvMpDWR5mwXJJ1aicsNthxP3tYWHDMSCQnQ6Jt6lYR0Ha/QWh9PANCeNc5TAAeXuE55Etbv34sCP5EkRAwRFkQrBasTT480fA5KRxQFsA8oterA8kI65+c6IlctCHpMaVyctZPIpjpZwZDfqxGn1k0pyVdHj/z7BtMZaviLsHYbBO/+/Z4zqYFqGSWBT3dpYZu69FqYzM0jLajqV+s+UjiMmyiEe93jFG2nN2HzqiSDpjAhk/kZBdZlPHtWZclsTJUDqI2xUrqElprr8FQEd37IMCXNLh7Qv7ZXLEjd8fx6NaalEU3F4Q==",
			}
		}
	}

	class hashar inherits baseaccount {
		$username = "hashar"
		$realname = "Ashar Voultoiz"
		$uid = 519
		$gid = 500

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key  {
				"hashar@bihash":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAIEAvt7LIRTvsztelZFaFB+3eovqapFo5Lur/SJoxcV+O5YxPAA6+BBXuhaORJIPgq022VcJAZagZ4CaOEDRVIMJnu3olP5DRwgjGbiLxtFaMglahp9aFUFDXQ8z7ChY3HE1YYPJVkSwchWBcELZEOoIm4423AleQb0ZOie24xH/l4M=";
			}

			ssh_authorized_key {
				"hashar@zwinger.wikimedia.org":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAIEAzNhpIeuPMLolSk17uv9edHPmPHrxSNEAT/TofxgFyDrebbiExixcT0+riF5kB1BKlpyIIpiIHA5FNgQI6v40QOJ8YA94n1KIxp9hXGNPBgEaoTs212LljrfH3Yx4/6FPGhiFCC29N5oHwwav1RGi6+YwaoW4lSDH+x6YVI21xQE=";
			}
		}
	}

	class hcatlin inherits baseaccount {
		$username = "hcatlin"
		$realname = "Hampton Catlin"
		$uid = 550
		$enabled = "false"

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key {
				"hcatlin@greed.local":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAoET83J1YKyC8C0su4RfGVWz9Lx69dwSgPamrAGue/BvQ4W7IDvCQZPi8pKMZuhY4N7OkjjhTjV7JqMqqjKICCwFVHZQSuMbFKYbaMtuYGGno0kGVRpGd7n9x4bHAep5K6H/FUpedPPjuhfXmvl7EYRIYHJrayMS2P79o5GcFFwQ6rYuBvc/vAMkOp1NFjfOktPLUmaU4PMroeIPf1XJ+n2Wr5hFw7fehHcYF7VmJft6jhPN+DVHyziJPRWEhFe5axfkqEC6wIk2O/d7OqnPATlk+7+vEh69yOzZu8Jh/FrNn9HzGHH8ZzvuksUvVoRyw8qlhFRxJKLbl/IPPZ5v7Dw==";
			}
		}
	}

        class jdavis inherits baseaccount {
                $username = "jdavis"
                $realname = "Jon Davis"
		$uid = 1004
		$enabled = "false"

                unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname] }
                        
			ssh_authorized_key { "jdavis@wikimedia.org":
                                        ensure  => absent,
                                        user    => $username,
                                        type    => "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABJQAAAQEAliYsMiUqipe/HtqzehVebaH8/kVl6RddesJC8fy/jV4TTTFpp+Ow9zpwqgS4lVgeYmrHnp3iDraTiqLlTzoB9e3hXwatzysUASn6sgep5zSTIqC7pb5xYHi6dsI+47L72vFoGfZdugXUYXqgml5JIRk++CK2KaH6udsxev/vW7iJWLxoPbXA9/dsX32/JHnHcNKWkYSjOvl+kvDsLqgnBO+smrLqLey5h1T6BObo7sM6hUUe+COpzNyJC5stP/GMUaYohHu2u9lwcIUFDB/5Wn7aY2ZyNgeoiGrS2angNoI2kNMucHw0eAtIFpXVYuuz7+ijDdGICeh0auIRfOg54Q==";
			}
		}
	}

	class jeluf inherits baseaccount {
		$username = "jeluf"
		$realname = "Jens Frank"
		$uid = 518
		$gid = 500

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key {
				"jf@htz1.mormo.org":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEA6oJQl5pStZupvWuqliV4iyRwEO5XPOG5SWVdctyf/DJA6FnSB3MLqfui+NJFeShIbrAyVMeHPk009wC4SCUsuxJz52/YlfMXLRfmYMOy2QvsLVlXATzU2koCafyqdmPETWPazCAobNtgH1eTfhtewOqBaL63gulYZHIrgGjUxqv02JEdMsaLB9KcmKbtbwiUnilCAx1agsjXVkxrBD/Pl+wcMWgJklfxnt80czndvBPPzxPKQOkJGvuqNp39JqHoKVZtJ9wFhEXM5greAu4JXhz18OcGZFtXUlBaCvHsVIpWwkg0DHMqTbtEaxlWuJXj5whOgc2xwao4Dvu1p5h5eQ==";
				"jf@nx7400":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABJQAAAIEAm0iSI9O2ThFVmGXGzdKCnhPHt/1+qWfanOu7gyhlTvNu4Mt7EtrjoiagsDkYSQMqkFion/u7l5r27nJ63elGfBuND1RrJEbgQqCjSZA2hFKRrwCD9N8pMiffxJiRB/tb3PTghdYCdzDrBYyHgi1WKtO/0eCsBpwD/zSwQobEHr8=";
				"jf@hpmini":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABJQAAAMEAqilgQkGZLiuyqSt3nvPTb68otGHrwB7yPm5BI0TcHML2eMqOifGwSBBjuPbXiNFtenWG5uZtBHLhTJyLTTQ1sJx0nz0qdOc0hWQzGAv3AIQl5casuiD7UQd4xtmJ81ZBxcsDtlllDN+ceQhiitP2iR9gIlda6SpgIiNxK3CvbEGE7Ep/LdTeNrb6/j3NLjvQtHBMYt45jz0WcWBy0zF33fNZGX43ActpYvO79L7vULPQk+eFAPiCoPUhIzh0O6nB";
				"jf@mormo":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-dss",
					key	=> "AAAAB3NzaC1kc3MAAACBAP+T1xnSHS4r8qwJw4np5syradidl7RYfpz2ZTn1yDdaKdfV7J9uMGswhILdTCnH/2RawgH0Y+q0AYY41qBZ/GLYrTdOy9MS+coK4j71l7jDPxQob+IazGwSvo/7A2WzOH0F/oaGAqDg2m66QVvtofbfUgmxBzA8zHkvzYFsUUeRAAAAFQCSLmm2GvN4tlLOL8addUUo8MDOxQAAAIA0qVhPLKA8k4oEzM1DE8C36xIMs7DU7ymDW2pbjq2VU8RjpZjhCH5ewaVEnN7CMmsVLaUsC9rFCMiT0N7z02Y5Zup4gzGuoxgdD5DtLFPdRMyVMEmPrOJIrYWL7cnd+KCZ6xmLrj7TSjzgEr6lGVwmLprBtHrx3Nvwm2f81kqXeQAAAIBj/ZLel34m5FItEK5LZiY/Ljg87iMsZW/AKcl2abKmF9Tuoi8y76BS+3WtaMD0X1ic90oSc3EacLDyDpwE1XzWk9rO3FhHXnsVZFYQIdK7LINy8+yGrccGVMpIR9OUMFpMCPC+td6VrXfRM/5DX7NZXSBbzCHJ/Co9ztHS8FIH4Q==";
				"jeluf@zwinger":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-dss",
					key	=> "AAAAB3NzaC1kc3MAAACBANooK6FcUTzatD5XDUFAN03FFvJ2mYkBy9vF/OtH/hnWxH43vtgtyf7N+/f2JEmRo3gcTEpfV4eIztE4gLNd2u6S5dSXuZDIy146AD3PHRwcYjEuEL/fNC0oKEIYOKYiLoQqpnB+/idQHP7uQaiGNHC6lhEy5oWpui+kTCZBTr9bAAAAFQDJ7lk/ddYc7Wo+/IhR0EOQ3mTpjQAAAIEAtagACraVrg8PtpbpK7tjNjqQkgK8IaQDjEMGbGyJdpASBZkyw+EZSLV/10pihQktIYcHJCmjEBOsFN9BEf0IlgoQkJO4IhhgoRXA8eZRRl106GpIv18QUmayjWNtvG321oibmSJdi4VwdfckH6x63bS5t3RQP2ExW/3KiBDa91cAAACAW2t7AgL3qI7NhXjIGeo4lPY45SVSy+KxHuyQKiGs7v753mtdrhSDD4xaawzQf53jOlYe1yBIlEbqICRJ8zhT+e5eS9ZiXWM+G0V5P6U1f6HeRDBLm1SPsvJUdYFPdoIlcg8e9ys5E3sHNy6xYF1zjzMe+EtCsiM1+mC5olBWl8I=";
			}
			if $svnkey {
				ssh_authorized_key { "jf@alster089.server4you.de":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-dss",
					key => "AAAAB3NzaC1kc3MAAAEBAIWL+yGT24UBP1leJnF7hkaG/AyyUWKP0uCFX4tJNdIlKj3sLb4V7AEtiRaX+h93Df1L5SPOr96iN1TOd51+ny5K/D3iOse8ACQTa0Zigll/mo6S30ceixBk218ud/k0q/hAIvMnZj2AxPIX/jYV3Akjp1sPaT9/Ed06SHGyj9LfdOTK8YlrkH6eO3lUJ6DBU5Qg3KurUXGgnfFx75Ij7nr+C6tekgj7eF+stg87lSt2Q0gi4fu/jBMd3HQyPY3kFBRpe5Ey3RfGRwA0Zre1gvyByliFRSx+zuBHLph2djyXRgS0GeyR/txxKS4dcE/7Qk4dQed3m91VyRCikbs6M/sAAAAVANahyQS99I9cKiiLig3L907M06fjAAABACphqj549n+hJk+PQNY8wiYjxUsH0JMybiVPmihnSa7P9Eys7YCn3onT+Qs12POzvo69sCM20HSulZe5UJu3cLNxlwrphkg+Rmm6PBULNJYNFA1Va+aotEuk3yeXhJUFcFgKYax2QsMbTUXSvGjwICGH+5g5Mv+be4NMhDG1iFALpIprVxRY0dvbRnh5PlAozjfrDL08XnEZWneOPp5AQtZrkwLIynM//z7DRE2VKN2yoxGkqQO6fBRqp9Dn3kzxDf1A8DGmzahZl7h8YMHLgR8CjKYzd/GGeOL5VnQtDj+/wVeXvBm5HSbnoAJJ1jqahPcIzT1faHZKliANxOuhbOIAAAEAPaef9bwlLj+nNqHhc9uT9DHQABMzclB5TFjO9XO4Tm0kqjlp//itY2Jqz9lUnKty6uymvIioIuGgqsTeznAqIDSv+74h96jXAL5GveXtHHFK4ItLd1tadbfCpGN19s6ONDCng162XHHeCdQlB711Ua38Sn2FZOdNkIXiDby4FzXOdC1G0SYdBa5uPfgA7ljLojvYgH5gNSGJXGj2e///433FRM5N9tn9WzilIuEcWloNTkabgdIwc2PWWv/bA0mZOlV44AR1u29P39IklQrBTmBYxMRv/XyP8CpNHiD9wnUinO8b78mZiIp78Cxbo3cyIPIusRzc+m7A9cKR13EWOw==";
				}
			}
		}
	}

	class kate inherits baseaccount {
		$username = "kate"
		$realname = "River Tarnell"
		$uid = 524

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key {
				"kate@zwinger.wikimedia.org":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAIEAtj96Qh5uNEsO6bgK+4Uj5dFQ6TAJlV3DAtB/FCNJNXmcV4eggnHxAcMVy7jbGYk/gRhPUNLBil59ZImrXcsRF7wP+/QYegeJQ5er/KqNKd4EtSnD7+mEaM90rSlm0suG93k5VDShMS/Yb74XWMEMwcFwrltaXve16P+9IpmTF2k=";
				"river@loreley":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAyszt9jTA88Dz4SjVVevwgCKHY1GfS5hla0XatqtAWNI+9O5eXasbybB7UfHo5Y6FB8Xu7Snu1NAj/xVGKLlQ69cNT6YMaj3TC1TLfhK2pmHxWHXDUqffU5ZOE/C4VSdING8FateJ5E7oOw9152UKNRoI12Fsu9yzzUZnKm0+43kFg/XfGioGqagm4jAUNhwylqRulRxFWCpZLjEjJOiRI+6pgVK8+wsq5kpuwVe36k0wmHEPWhbGabNY1Uw6dkVWIz3pI1PtaAmmb4FZ6KLYFh6kO4u3M+uhPfj94mtJb3Yr5jPkOb/9DKhCaZqYLVm3cs7pyQZtN3oRkitjzJC34Q==";
			}
		}
	}
	
	class lcarr inherits baseaccount {
		$username = "lcarr"
		$realname = "Leslie Carr"
		$uid = 582

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key { "lcarr@Administrators-MacBook-Air.local":
				ensure	=> present,
				user	=> $username,
				type	=> "ssh-rsa",
				key		=> "AAAAB3NzaC1yc2EAAAADAQABAAABAQC84js+fBru2S9Ty5loT2mWEoS2WcXDykJIUOKhT976JsANeP9sL0ox2/V+sAY4OPsAv1INxTbuPp5pl3B4yk8aSBZjZO5OwSZSfkICmVuqzKrzyZnvCwEr2dwZRW7Bf0sIlzMrg7gJKbKPn85zsZHSrRChouJxmeV6w5gIaA8asdsATNIgIU1BmRhbPQkMx5UkbqcbxK8mPpFPGZvEOBt7ZUxls/lT9CmUqInkrQ93usZYzo8RQk2KqTiv3gx/K4vkNSqaESQRvcg+JKrdN9QnB9IUzdeW0M16xTittN4ETWT2cAVZ1HNWmIvrxua5GDsrjI4psFEd8saWD8IJrfR3"
			}
		}
	}

	class mark inherits baseaccount {
		$username = "mark"
		$realname = "Mark Bergsma"
		$uid = 531

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key { "Mark's main public key":
				ensure	=> present,
				user	=> $username,
				type	=> "ssh-rsa",
				key	=> "AAAAB3NzaC1yc2EAAAABIwAAAIEAorTmQ0qlrxB3RL+GULLzex3k1Pg/c6tgLbKsl1A7Qo0B5XI4eNgfWwaAXUrKyQW3/9gwDH3YJ2eoOue0/BGhKX6voOTnNPeGE9ZbrufpPLT6DXDEbvpmXQd/qw8s0GxdftleHYl28av0nTZgKY+1/Oc+ZHNUN5YxmdGehWBvTXs=",
			}
		}
	}

	class midom inherits baseaccount {
		$username = "midom"
		$realname = "Domas Mituzas"
		$uid = 527

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key {
				"domas-wikimedia-200904":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-dss",
					key	=> "AAAAB3NzaC1kc3MAAACBAMOWDta08PH5U6hxvnHq7xT7lqIxWxMzP8wr20np4thUtlOqLsxmpJzHzdWJMlaEu0cLrJXxYq2Bm5jBpDb8Tmfo2TeIPgmFWmLgLpF9A4biXmMA6V9Dp5W/eyZgmlHjWlTLu6Y5WaK+Dr42rKzCMHeSxY8T/gvVIXvjZliNb7cvAAAAFQCLTv4hEekK6nLpqX2j/ac7Wj4eHQAAAIA3D0eTxabhSGD8a1IL/2i+Fb8YBLm6uJOXHmeIZNrpl78ml7lOcXxlQSlrQ8Gixc9eKz1a4vzuqKhxqdSFMFcA3wK0cGtXQuCtbiKGgFdKDsK1uBk/5d5mowqYNwZ62taA41NO4VGB7rYHga8Wg2ph5NZ5yuQgmOI8JqlbALH9oQAAAIAwDc1SQBOYJacBv/NeXhQIuDUO2x7gnqyr9Ud8hlnzy34GQldo+03AvL9vq2RSemCQBjnEqxXYUGhHqDshUvnHq5JxpeWjKRP+p5e0Xy7aepss3g9/IzUUrZ5m9HskczSfrlNBwDG5ybgaCJfyRX0MXnV1GCjaGlI2k0iymqGT+w==";
				"root@zwinger.wikimedia.org":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAIEAomwyIAuPEDxmRFl3O11IH1yH+n7th+meS4dmB9OzKxh5Sg/aURrfFPUV/rSh+2QqfR7M7kB59ganKpc/7tCXW9mxoIr/c1kQ9jBzpyc7VUox/VTlSTZOFJA9sH9PUVIDINVNPyPFLNy9RtvWkSfHwffo6LHNju+us9PaUlmAaE0=";
			}
			if $svnkey {
				ssh_authorized_key {
					"midom@flute.local":
						ensure => present,
						user => $username,
						type => "ssh-dss",
						key => "AAAAB3NzaC1kc3MAAACBAIRBscJUrqCDE7vK6YwlQdEXsGCBaW44dbPoG8QRtHU+bD8wZg/ViI5RX6hRCEJ7EWC8W+3xfocbo48UP94cAuvsQCquDvE+mwnVPihy3EtfbPFdPj0X8E/dGGD3YzRhq7ALMAnRPYlsgixd2YMDUrEYM7gsmeZbwfDrfgFYihTxAAAAFQCZv5NzAdGZSURVo/oAGr/27rxYswAAAIAlzeKOSWRBHV+01jPhESwbQpDhgVWd7KcowZ8JP/Ok2isperY9Yyi49udCy3PTNR63zyVqsrA8HHFbAmQvMXInAQxeqLxthWQL5MPYGKaZ7GeFiR5IhJjW1uK7flmdL8855BAbFbtdMGXgLVfH+Wa5o68e8hdNfP5jKkzTQRqkbAAAAIAhIqRn8sfBgd8vh0oZfzEJKaU8mOentbfN/tGXoFsPZF1kI4HTnYlktfzxo6wd9GGeXb8dJOa3r5OBvuw35zs/4ChPyONaMwyXCLRIDf6Iamhn6Vh81UFrGjuhng5awW5VLhQJcAr5zZ2tw0YWHQ8UExFnIYPnKuWnAs+qIFv0rA==";
					"root@flake.defau.lt":
						ensure => present,
						user => $username,
						type => "ssh-dss",
						key => "AAAAB3NzaC1kc3MAAACBAO+dLGWJQ2nu3jsNnRG2zsX7W9HK/XHOvWRRiezAf8e/d0n8vHOUL20MszrIRenM+F/WP4DPhIpDBpZ0DlIslY1IxX0hNeG5kgkq0dftRbO+qnf70nurWmggAlK5H+omCDgn9odR68f+ovfkcCz7edYz2Gq2vNHFpuK4wOJhQGZTAAAAFQCWwe8yW7iddPkBaViWTDpvLwBd4QAAAIEA5AYTGGVu8DAuL0OShVduean+IQd3j2xiU0HTCuALQZHTxMcN9BSxbgYY7Moh1TRAKpNwQUvtw6RVS2k58s69RAj8URpFzMSmnrgbTZt6CZ3AuRrnlz74S8FLTwDWMeHDyg5ey5ezOcQn0o34wuK3H0EFtkshykKQA53nd6aFmfYAAACAax/cZBm/Sjrb2+c3HE6WKfVSSi0dLLe/D1LidksSYEv/Kfcgx+/6ze7o+yHT3n+5cW813/2Iaa18cYD591o9tD6NM+WI/WtWrJIx/4sIwudow90N6P1JMkf+gr8hnIszaw52Zf0Xw5C7tLSkR6gMcI4WgwTQakQkram1DaJEIPk=";
					"midom@flare.local": 
						ensure => present,
						user => $username,
						type => "ssh-rsa",
						key => "AAAAB3NzaC1yc2EAAAABIwAAAQEAvIaIOXvgvLTMPmSIEg/ebFWQtwj9x8KGs4148oj/ytyhwtcBcx1qT+dy03YyZebxt1snVUr/o/xYnzQNksYJug61dmGZLmeG7ktTVkLeUJqoLDmgP450vR/Vlug+YX63kGCKZIaCO47AzINfSSBfaXJq+GF8OBWEThfxq8V5GoOp2BMqf7e3LPIQOe/p7/Yr0yGAjFXZ5ju+KLs3JFP5wDVKSKNjjs+x8a74DYyUYiKeFox549e/iOXq8cLSfGyLQ7asYRKS0+UjPLO5Pi3iW5bGLMibiSNui+sWLL8meEPVr7DtqtZ2/XptzDCb9KUaxldRtYNoYczls1dR0fXjmw==";
				}
			}
		}
	}

	class nikerabbit inherits baseaccount {
		$username = "nikerabbit"
		$realname = "Niklas Laxström"
		$uid = 583

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname] }

                        ssh_authorized_key {
                                "jadekukka":
                                        ensure  => present,
                                        user    => $username,
                                        type    => "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAgEAz5I9ctvMwZwehidz3oen7Teoj3pWi6M7+q0PnjXCWy6JuqkIv5vFtmi8NvCDSTCEaAdNdr7WPQHpGTSqUkbWsz0sswPlODZLDM97x9fzC8z4YhckJt9nlhGCYYqUi9hbchxTOGX2LL18/9IeU7yA5nb8qd3PPzhzjzgJkSjTgMnU5Ni+OBY3WiNJ4FFwYyitokYPVIF9ZFKkUWwuM0bSiNUjbNIUb4834i/tJ3g2plxX+9+7d5b6wFSWu7+e8wgN4avaTC46B3zKcYmfDUA2ebiZuhwUU2NdsP/z0Q3rOZ3LxRmVkOJFbK9vgmkQtTzSkhG3ZEgUiHc2QCjgccjkv+KFayn26WujtbmZZoIELC7/46lgwWGEZtb0QUbo2rY8yHaeetoVuVzZGtCrr0tEBx0w2AH9BfOYsQOnM7eOVzM/VSdW+3sTrQMCvfpd8HZsWT7d2dSyM4hsvRaETwxxoXQEiZZfik0oH/EJSH/AogfvXu4MTUiCekNtPRazJPa9nI5M8CVtMiSUb3mY7OJ1OLfn4nWBvVTxp2sP3nTSwLEYpop2lMUwEwy/O4POXUuKDZQOEqKb5yRxuW7bOSGSDKZKHaZn5X25BwVOT/oNX/vqSRGxf8OWGVj6Ic2RNuGnYWDmEf1Rp4BVn8xATzOO8/o3yDnElw3M2gBkQ3hDWFM=";
                        }
                }

	}

	class nimishg inherits baseaccount {
		$username = "nimishg"
		$realname = "Nimish Gautam"
		$uid = 549

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname] }

                        ssh_authorized_key {
                                "Nimish@Nimish-Laptop":
                                        ensure  => present,
                                        user    => $username,
                                        type    => "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAvxpHpaUUDrX95CkroBTDEDMpfUj/S/5mgd//+SiVZIuCkbnhT9a1WR/XtX8Z6uUBrv5nya+9MR+Xhw5h8dG4GRM3UP0IDVku3K0M9BBP/3rYMssiqb5oLDBoLh/m7mmYuvMbs9CegFFYj6M+c+eUvu0omrp/koIiWLOE2QXT2sVVooJazKLoCaeIxiw9A31b99gNfl0cCwZMOwY+eqL0TY3G7d0O0fgE0lODwtAyoh3SxvMmyWWatwhEcWb+/knQx+cDquNr+q4TDl5I1B4fzExV+4sVrvrgP2JwM12rmcmF4VRnJOGNpjC0DXMbaFnvaO6TPh5EmGY8GtDRYQtTyQ==";
                        }
                }

	}
	class rainman inherits baseaccount {
		require groups::search

		$username = "rainman"
		$realname = "Robert Stojnic"
		$uid = 538
		$gid = 538	# group 'search'

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			if $svnkey {
                        	Ssh_authorized_key { require => Unixaccount[$realname] }

				ssh_authorized_key { "rainman@localhost.localdomain":
                                        ensure  => present,
                                        user    => $username,
                                        type    => "ssh-dss",
					key => "AAAAB3NzaC1kc3MAAACBAPo8Dv0FDT2DYr+olg6k5iJFgBfaXn3wk+9vDv+DQe8Ys4WzVhQcQ++/kB155dlKczmCvzQWIT7r/af7tEjbB+C3I9qz6BN5htxvvrVCrzab9SQXL4fYy7TTg4mPprJm5GZScBgO1VLua403Kx6SXZ36HEgBHWK8tkblJq9cuazpAAAAFQCpS4v9SsjqXsDR1LALBw4BvfZQowAAAIEAiHxv/Wqj99FPYRcquxehZN6ZsBxBEqhtDiQPL6SQy4VyPZRNfj9sH/8BAbwOdNkaU/nXgH0xOTyW86k2CfDMNUf8etRBXy6MSGoPWIdugkY0mRKqorqkoVDMvZVPbTI03nWBpvb2CDb47/mJLqhn6s1xQ5OzuZ2u2R+cr+8yc7MAAACBAMenXuT9/kRpVcWHrkAxJNqf0FLpuRXAGwAfI3gGFntsa+PVNA/8tz4afEO1NnaWmGQ6MO7xXKMejU2WR7NpKkxbCEHeyy5yKdvK5tZ3xkt2r/QLtxdiTSvizB8Fl+25JP3oUR5o+laxrk0gbEfbMqI6rHj+LJ8ibrE5+EYe6dAH";
				}
			}
		}
	}

	class robh inherits baseaccount {
		$username = "robh"
		$realname = "Rob Halsell"
		$uid = 2007

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key { 
				"rob@laptop":
				ensure	=> present,
				user	=> $username,
				type	=> "ssh-rsa",
				key 	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAoDAuzkYEIeGVC10zh3i6WnyJjhWK/JpQbSFlWfb5t02kGPvmi8m+fdCPhvqiOpOCcQqTL1Knia6AeRNMx+dj3qxctsas/RnJtIUbACK5gH6aKg0OMmcG9LNiVLN5knx1UMHhQ7Ma6KSiDLeqsID009j7+Fj8qgGup7lKOQs7WYRpaXlAyR0hdKeyxcXWh+GPQEZAhl0DHrjFgdDcc5n2K8GBRESfdfCKm0SomHYGWPsTIpWrY13se0kUJzWXIafzr0U/czEdVDuSuil6P65d9cU7vypcUC3i5d2L4QiO4MBVNcXluFuFNZ8UY/QAlixz/5x/ARbgjcMvXwJQWjhh+w==",
			}

			if $svnkey {
				ssh_authorized_key {
					"rob@Navi.local":
						ensure	=> present,
						user	=> $username,
						type	=> "ssh-rsa",
						key => "AAAAB3NzaC1yc2EAAAABIwAAAQEAsyIODQk6BtkDVp8rHfMRZFcDJxdv7jLK6ga2U5oRUb/thKLoocECQ8fEzkAJBOmuyhv825W86NmiAmPj320gI72zQacCyu3Mj1FnLQV9P9z2G6POqs/OdnG+3wZV1aTRoWHFREalEon1FoBOSE2TOgr5UtNnL+X+pmFkqjIKmCx/97KOq27xwNlYLEzO6FJcSptDoWoYEChT+/MtUiKoh5ZwAxSH1j8iLLwsKhV7+RC5EKKor21teTRMzYj59oYR7wM9IuhKFJRewKRJwaZSFboS0H33QxMsEgZhbawOSBn1r3mepfNsa+AI4B8T/1EIdSe3H+NArq8Wm/oAR3hN2w==";
					"robh@zwinger":
						ensure	=> present,
						user	=> $username,
						type	=> "ssh-rsa",
						key => "AAAAB3NzaC1yc2EAAAABIwAAAQEA8SKRT6tT1G/qDHuSoZsR/qTEREN7Zk39P/Gptzr4Ttu2TdCRDLyStHrssqfVXVXwa9AJ7UG8FOnwkz6Ow1zjQEOce6dOAPnZI/hdrxChsUOULTzxK56KwHh9J51vu26+2xpuW6CG0w2ycohTjAXiNEQJbfGthQTXto0h26KdZsCGqTbAlKy1X/Gm/kJeOXzGNja9ezivWRfD8XsNX4igKz/2PHRlWhv6hWIzBVZmMJ1yYm9guhwWaya97uRTWhD9H0OL8/xKBwMrM5eXlVWX5BQhFwkqwvtArSioIWf5wD3e6a0OdOjfCHZEpBpUY/Rv1BW+9FXJ310nleoN4kfuvQ==";
				}
			}
		}
	}

	class robla inherits baseaccount {
		$username = "robla"
		$realname = "Rob Lanphier"
		$uid = 556

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key {
				"robla@wikimedia.org":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAu53QXIYXig1FTP4ve0MOMSXZXtMORld4y+f9cqmKA7OAStnT1VYw6F0eBSPJH0WUo541iMKcsigENytdn/kuSu8zmh1+nyHvhndB3LvP467IBo82LRBaZ6X0+0y5X+w1w56oX5H+t2zixWPHTQu0f9XQBPCsZzfV8DkVbJjwoHk9wcHI/lJSa7r5dI0xWPWYXXHM6BeAHbET1kcUAe3km1jWDsh2gBgKfwis7iIZx6ROSBOfHdYs9MU6miFq/9kk2/Z1vKOY6bj3adVe+wbd6JFF0UZdQzstIW3/15NfWJjJ8X6gx5U7wchtuPjnIyydUTU5u4UiS6uUS4e+MFsoOw==";
			}
		}
	}

        class samreed inherits baseaccount {
                $username = "samreed"
                $realname = "Sam Reed Old"
                $uid = 557

                unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname] }

                        ssh_authorized_key {
                                "reedy":
                                        ensure  => absent,
                                        user    => $username,
                                        type    => "ssh-rsa",
                                        key     => "AAAAB3NzaC1yc2EAAAABIwAAAQEA3k6XjeMEmIHonzsmRBbHCkeVhxS6oObibs3PPP4DAO3WYXPIGBye+OpPtCpSZUuVp4t/GwnqIHCM0MrlVoFKeFcC3tHtVwmxhIsTp/RQRPjjKNdH60Iz6RlDTZ3TJDaYkYOiW7spdCONLzkYpOgkiph973aMNQ3D0vS87jht1apUl06bkxYeC+Bziq4DSBVNqpGKa+NqSYOvtS1kapwCYTtRm6YASb0YeMXzTUyfClgvq86h9XLsbx7klWgjHfKbfi/yheAm5EY6jxicnYaVAmy2gq2ERO9e2dVbpJihHmhPTpdRba5Eln0CoPkWrLVX0jyiAVB4biRtYoTtxGDPww==";
                        }
                }
        }

        class reedy inherits baseaccount {
                $username = "reedy"
                $realname = "Sam Reed"
                $uid = 558

                unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname] }

                        ssh_authorized_key {
                                "reedy":
                                        ensure  => present,
                                        user    => $username,
                                        type    => "ssh-rsa",
                                        key     => "AAAAB3NzaC1yc2EAAAABIwAAAQEA3k6XjeMEmIHonzsmRBbHCkeVhxS6oObibs3PPP4DAO3WYXPIGBye+OpPtCpSZUuVp4t/GwnqIHCM0MrlVoFKeFcC3tHtVwmxhIsTp/RQRPjjKNdH60Iz6RlDTZ3TJDaYkYOiW7spdCONLzkYpOgkiph973aMNQ3D0vS87jht1apUl06bkxYeC+Bziq4DSBVNqpGKa+NqSYOvtS1kapwCYTtRm6YASb0YeMXzTUyfClgvq86h9XLsbx7klWgjHfKbfi/yheAm5EY6jxicnYaVAmy2gq2ERO9e2dVbpJihHmhPTpdRba5Eln0CoPkWrLVX0jyiAVB4biRtYoTtxGDPww==";
                        }
                }
        }

	class tfinc inherits baseaccount {
		$username = "tfinc"
		$realname = "Tomasz Finc"
		$uid = 2006

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key { "tomasz@scratch":
				ensure	=> present,
				user	=> $username,
				type	=> "ssh-dss",
				key	=> "AAAAB3NzaC1kc3MAAACBAME+XGr43e1N0iWu7qmC2Do/mGBoWEGrSObLXk6Fll9+WJ9nRNHvmQAkEUexWEQaolI+ItWFEAVU/j9pO10MvF4YcGQSGcUEbsQD50W91P3+T/ojnP6bhjI2/aX4HAg6bk0Sq2ckYNpu4owJdhDnTHNk3luptOSwVLnJ92Nm9S7JAAAAFQD7L3zwmi9owkB+HhHxzqgwWAB7LQAAAIAOTsZLkm8nfbqMF0QRWKCb4NU7spftTiFLgVNiq1nQcSA69krEzZPi17vOfJ1a1iMWJL1zKHZhIxbXimDxMAwKS45WU2RxfMbtZw70dAK4AW635yb5riIyuc94NwmhquRypPcGUQKN+/mhxB+NDs8AG32iQjVD5e7M+fczfLsRfAAAAIBoRL51kK9c36OMcrzOJVR8J9b6bkV/AclSQmlNzm2b3armXf9w2OlifqobOpoJL2PG8HWKd7QAqv7PvON20HErNDBMCYhfRmX/Bn4WcWgZzq5y5I66rGs86nqyycbWAFbz/Yd+zq6P1z/LpzXnGsy8j8CAJGQ8c2tXvNGhHToHtA=="
			}
			ssh_authorized_key { "tomasz@wmf-barry":
				ensure	=> present,
				user	=> $username,
				type	=> "ssh-rsa",
				key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAxk8Zks1Z1qsFhu7CmcYC8474ikLmDVXXLqeC2ekBznIsdX2/1IPaYIZp8w4G8M2X1InMOqQswCqTfvQFuMOFWxJvTQXxZOJUC8L2El1xB7t4O7mvDXw8uq1h20L7ODsLkFga3M7W7IIg3pU12HS1UAInYDQt0SCXtLaTbPQpgP8H0XNZhn/I3P/NVQnaUx00YzrS9ZojNbwEHB8cUpwp2N/gfv/byTTe48Xaq3wlAxw/QTow5G+r3atEOVJ0QKGztl+uScF/ZzP8QYficdMP7aNffg9aQhf/uER10hXu2F16UZQyoMx/sFkS2U8ZNVkCKLhI7MKti7+ZGz4/+fcCOw=="
			}
		}
	}

	class tparscal inherits baseaccount {
		$username = "tparscal"
		$realname = "Trevor Parscal"
		$uid = 541

		if $manage_home {
			if $svnkey {
                        	Ssh_authorized_key { require => Unixaccount[$realname] }

				ssh_authorized_key { "tparscal@Trevor-Parscals-MacBook-Air.local":
                                        ensure  => present,
                                        user    => $username,
                                        type    => "ssh-rsa",
					key => "AAAAB3NzaC1yc2EAAAADAQABAAABAQC7az/zEdHr8aB1y2uojbvCq/5qM9hSS6GV4TQwN1OojwyuSVipsliJ0ikuGXSHRfzhjfNTx4WRYCTG9TdoXgIRly/+QUA52/4dxaV32f1JakYhdRtnTDtuD8GCju3J6JFcd2FN6pipYV7jhzAHHbug8q2PlD99PZ35sBJ6/Of9aCGA9v1tG8nSQ3vXOg1kcSDtxUQLf8cGyNlBIKOjSmJHp8ym9/ADI2yXufqYccuunqdVgUxJ2XsqGAXtq8Y4AJdUyIoQVVFtXq/ek0RY9kIW22910V7aipFvLBahUUnnYsQ1T++A8yyGHVw+ApL+lT5SCtJwy6eHXdENhxrwgKTF";
				}
			}
		}
		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }
	}

	class aaron inherits baseaccount {
		$username = "aaron"
		$realname = "Aaron Schulz"
		$uid = 544

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key { "rsa-key-20101031":
				ensure 	=> present,
				user	=> $username,
				type	=> "ssh-rsa",
				key	=> "AAAAB3NzaC1yc2EAAAABJQAAAIBv9rklx9iBwtRUh9JB9ZwRGPX60KrS22X48XR4VjMIa56+IG2/yfQ9Z2nUl8Jt2gNHg/SG6JXelctU6kvmg5J9nU+fTYz88Yq4+DOkMwl88Q431IMXW8WKODKkj3dC4I5xHPZP4YH+eWuLoFphJtifiLNm4lbhKG7cxtNtowWj6Q=="
			}

			ssh_authorized_key { "aaron@scratch":
				ensure  => absent,
				user    => $username,
				type    => "ssh-rsa",
				key     => "AAAAB3NzaC1yc2EAAAABJQAAAIBwXVG0SwhtFVCJGfsOi+P5suGzST9RjFeyXIXMQJX6JrpcyCjwmA11eISlnwuOIpd4vyjJ+uJ4IVyizj9xWjLQH0Gl2+ptkyR5IvIyi8EosSpTLlYyZxVXqod4q0vnEGmFPcOMN6eQKOEX8VX4JpplodBlEVl+p1lyr+YAO3S3hw=="
			}

			if $svnkey {
				ssh_authorized_key { "rsa-key-20061225":
					ensure 	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key => "AAAAB3NzaC1yc2EAAAABJQAAAQEApNzNTrx3FjBamdXUIXzaI34JNbhaz0cYmU9UZiOsgRulBuDLV3V9tefWdg8AS4sH+Zl4nMXHqwQHt4+95u9j2LwoBGbfSRqowo/T0Y1WGuU+vRBFIzRPRwardRdkqw/dGaVFGTRkWG5sAS+tNmjgwPLp4gKEho35mw5J9pljwI9KS0+BUgTOGcbApjIWJLS+XYLb4zPKsb5SMl4ZDfEa1ULSQp24xrjOk8vSfgsxxplSOMsfeETmkIv9CD/OpRQWWpAOakMS2KrLSf8IRn/Wm3dbky5RKCW8Y6RRA7pV0Mi1/1JoFMTRAUrTrjxqqVid/qXGZo7GjKz6UbXmai6XOQ==";
				}
			}
		}
	}


	class tstarling inherits baseaccount {
		$username = "tstarling"
		$realname = "Tim Starling"
		$uid = 501

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key {
				"tstarling@zwinger.wikimedia.org":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-dss",
					key	=> "AAAAB3NzaC1kc3MAAAIBAIjSwE2k6G3cE1QPq9/6S027XqAdKDOCw3nEKxaGnPdoLCxaLic54URUyvrpqsZ24fp3iC7dlTXegvdVx3cLpHIopoyDvqVgU/gf5ZxivpfjVkygtygg721IG0YC3wtgIPey3ipQ0KbDUfSAOBmMEJ8+g47U5TOzeOsP7kNCKEbRLf1+e1uiz9D971o50haYjcNzDUZHQbuAwFo/tk4sPS0RKmI+FPupT5wXAqGy0CAV+MxDBIj98wvIXXu3qPOFocLXXFSCmjD9zjrKWrs8hvB64I9tGuErIEKn9sX7ZKugyA+tZ0eCUtOvKkCv9g6+gQ94CpyMIVHzosT0yE39qxnSBW7OeRLguoiX9w7AkhgRuWc6rHKj4IZ+lT15GW/oj4ZXcl4o+NlwgXAr1LT+S1jR/fJdCcCPp/+cDhfpfWSlns2+jnCmL4QxaHZjgqhUJIao74XxceCH0wKk9c3ZLb/6xQ2md4boL8nNcomik1Gi+iOF/nkx1Zw74r7MOXFil2oHvTPwUWym1gwBJhUONtcvb6y96JztP0gWLGAnG/EitQ7JidHYWXbR8Zg5Vo7bCYyVcPgTzbEHOoHXrLJqIq3nRf/aV6tktU5fUcMwhhzpfio8yhvya0zwC1lsc9SN/jWXQYOkqXPfwSxcdpS9DNAL7CiRT3/eM+VCovqXld5HAAAAFQDvsFdTtuyeTEj800ToW79X4qb+oQAAAgAWhCcL41TnRZuR10VpaWWZBFAn5STbSJ6/d4TOK2iwDj1SzNPCtLlqYyOTOD8pNKrJnoaLsMpBq7JxdcusF+u6Vuc0wQsoQYSJP9MjUrSj+XV08Yr0Hf1iKt1SpAZak6STPtLR3EcB4HQxSj6/8U/bwfvxDullMTPJpazaSXTuwaYNiRE2f3D06YoFWs6dmvxMPSJGt0a/IBuCKsaeG0YB7QKXckZ7geNKA3AMPBgLPnZq0tw8I+vMLI0nDN5amh81xA35VDKihUNvp3cd2STJ9PJswR7EYHG/dMd8jXABhWY5UEbb9qQkGg5Y1MgLOjBkNT5eTwzgtW+m9lMEbu7hUh4B9gbhbMAlOxnda8Y1CNVrAdCJD/eUkmtq7jblJFNFa8IYNpGPIouHTwH6NOQc7olszsGi24xXf0X7uG03Z2xnEy/I5IYw5cW6uL1X0z5mWEEIMYNZYLCn6cGyCkH+KHTQIg3vST308AJtA7VE+WbxW0iy3gbTSnfsWTOE0SduITZ94r8FjFePKkCWn5P5VvlhXRf1yauurjQN1vSKwQPX7QRlkVP99RQLCx6R3COXvFS0CdXAj1x579wCpy9b+4MmY4UcVP5uODQM/yHnHxAc/QUpWQ8AC7570EVesWvvaFdgNqnC5rhi2JnCWKtnW1+8gHuddRyO862Ds/Jp2QAAAgAYVo8RyjvlHo/StZZ+vmXemtk1gzXhGR6HW57mVx8cxk0opa3c4SIvjmLBVGO0Yk/W/Ypsy8ikJivuRqebMokKLSecX/SAH6NjAYSafDzUIaublbMT+tctayY0drlWPrx7vaeR717z+VNw5kUeBlrDtUOfHHCJR1CYodUgR0OPz8uLq9A6aXK/PxE0QVvSFQDdCj6AwWswtkKhkT3u7lTaLAQeUUv9Z9Nl2JhMtOyEwYbpd9vqK9/1DKn3s8HfbwJcNr4/jSAjuXTIbKb02QVFrMZYw8PFfShFKVnFvqfmZd1I4J8HwUhcDVXeYzslLJZJP8iEzo8K1u8Jfnpt7xDJPN1km1d/a+iBlLhnJpMxofxR++kPcRSuKxOvueMIrmPZkEW2rYUUTAStU70bNIO7LHq8MorfcN4TplztDjJMRUbzbYlrxxpPmQojiyMto2k+qgvfqZKtlFqIDPXCWThMSIyDd8JeMOVBTgKWiYehk1wBLtgEQmRrKJTEg29EoXYRASHfeTCWAJTh5V0lU8GfoOMVoV+B2/KtcHx7pDc0S6O8weFjpNb+4wXfQ5LnVBilOgIlzqJmz+Q36WzjfWz1nF3jwNM88/pEcEbUW7v4kHxLfSNcYs0r1OXiC4D6nklfcpwXjwjGkdK+mCfPIwXJ3s4VNBSXiU+9j+I/m1VgLg==";
				"home":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-dss",
					key	=> "AAAAB3NzaC1kc3MAAACBAMa+T44Jat4ZubaZtanOlvq+7vj2Vn2vdOoAeafH3EBiXRc3FWxbL7MUInttfVMAQ+kKpMFrMfyZLCr+xfe2266zL9NuRN+0NK0unHnUJxKFg1xhlwM/miLuVIRPNYjx0hb5bnEqEdaHWhzDAac2Th8t4l3Bkx6irtLkEbG5X7rbAAAAFQDPx0nvVb7kjyGUtRpUSQgWqwO8BwAAAIB6ywz35DCRnX1wb6d+rjxR2bzzpI0EBe0XFs+EhWGcphAmc01gVOQj/cgM8X9lWzbzcepN/VLJLNYZDmhT7BCQx1bI+3mYMdHin5aTA1yLo0sNbTu5ECbe4cPywdWkRbUVXFFtxG9+xXd6l7TLUV0ZweFiV3hmeB+hKoisV0L/GQAAAIAF76e/8Nf7K67DM2DlYmjrfJYG0fC8WwbARKIldylkiVrADY8DFdc+dEXbUFlqvSMX0wyWS19zlC0XbkA+6EwIMfbEfukJoo84ygOhcdiqySn3JGxyQpuBQfiHK06oLxqNxpxs2R26/beqzkIzzIx8wXDN+UmjZUDuIVvYlWUWsA==";
				"tim@morisset":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABJQAAAgBiM8cXr8iIufFuuivuFQU77SWPnzdSmAk5eiPmkv/g5Vx35VyportZd3pjXKJMmI5biZkZeFdzLyFdhv8PPafoVjUl6iNEIQNA2HGf4N0F+I1EW2AKjJVG4sy4x8xlqVnza1v93Q4ffjSGLNAusXXbSx4SVRhZmNZ3QoKP5LJqZHrwpQpQTNinoLsX8FWVzaiWNUqoaVb6T1HgvMUbMiayHlvmFZijA5ps4U59Yf423jMPzS1snNZ8E/zVrPAN4fBbIAk17hcdAMJm9eCFwmKDiSnX1lU2ylHy9tPgsOFGTTZkWaEkcQ6/9DuA59NckO+bsVtj85QtCog7X60FHppRNA+0+8fUPX9MCZJp7oPAH1J0V0k3zSrLXA2SerrhyrwyYBQIlusK85Op6OfS9OOgUwf8FJXwAa+6tAc4HUAJbNpuR4UD/jZg1jJygPtY9YzCKH6WS7eWXTHKtaNEnBT5l68QainJ5zH8Mnt76STMwzD46rrmD+TtnZEqF+Ejd0Mmi5XiyuC/aI0/5Eyv/6cVq7cZ0yU7dWBcvutpwtWW1DApOkT6q6QmaxEGFfuEIgPaZPCzLSn3dztYO2qRk06VQ/B8W4MlHxZNef9tMr3nASmKNiMqiLtbAPpbZjV+XPOTCpy3/7Yt9Bh8/Bdh07mGMQ9/nIJo0UhInNU5OsXsUw==";
				"tim@colchester":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABJQAAAQEAj/IGK5iSyu9wKUTpAtrJBYl+epUbJMaGZ8KWJnNMTHisYqJv8qHivTbNKx8heBt/6d63V2V7GNjwz1MUdJnN3Qw1opxFSzgWoz9CYepYyMcwY0Z1Tz+aR3SEzvuA3s4ot081TO9muDH1XdjNFwCXxpwrf69jL6pqtScjaGec6WFVD6gfA//+ol1dCbgpohqNwmhQyQB0wiKixpsqS5WF4jPvBWHcyDuUKxDshyVzTPRH8pRMIGKX/lrkk9s/rZkNG+Pw5/Klevz0YsoIz+fzVgkONJemDhjYggLBXQUI9tOcrvfU26QM18F0/TYKg53IjXEa/M7P1xCrWZ+KNl9TAw==";
			}
		}
	}


	class catrope inherits baseaccount {
		$username = "catrope"
		$realname = "Roan Kattouw"
		$uid = 546

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			# old key
			ssh_authorized_key { "catrope@scratch":
				ensure 	=> absent,
				user	=> $username,
				type	=> "ssh-rsa",
				key	=> "AAAAB3NzaC1yc2EAAAABJQAAAIEAg8ogPqDDyhMBfXdV6Z8UKv3esRE4I0EAkrxnCCXuBfBnJ1A0dNsV8hKBsdRs4UCEitIA1a6bSCbq+kV7Xvq0yMihAFe3AG+26OISi5NZP+gNtx/aIBLGAgDXoC3M4Nb27F+pEDSfhT5OC6N/uO3o1UK4RSfgWNsmNW/lk5Ir57U="
			}

			# new key
			ssh_authorized_key { "catrope@fenari":
				ensure  => present,
				user    => $username,
				type    => "ssh-rsa",
				key     => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDt0lR5k9MsCt1TnefSX/AiNsVAurjqgl5w0l6xgRmZWeuJUJ0X+0svKjgJPnTVFLjfBzMy7ACkk3R5U9UnW4JNY4R3PlgaSKUe+u4/iFP9MVC0UsS6My6uVW3xgEFTksEQucmWsj0SJVjLcS5hGIu0Tl9SLkSBT5gQLwXRhrXopCK+Aco7ACSuMNjKe7Vtslmh6l3qYT8L9nfYJ/dZ/2Oryzw7rMb1SgQQhXqUIUzTu0lSBaTSjPbe5fre2RvGLnIUQbrt0PQd3AKGBI65LaW53fEMhWHXTdw/p46PkJLfQ1X3i+N8o4ZGRr4aVP/6Cn5ANOyu3JnSoxmI6Pjoyurj"
			}
		}
	}

	class pdhanda inherits baseaccount {
		$username = "pdhanda"
		$realname = "Priyanka Dhanda"
		$uid = 547
		$enabled = "false"

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key { "pdhanda":
				ensure 	=> absent,
				user	=> $username,
				type	=> "ssh-rsa",
				key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEA3HbBUW7PKFdkYaPkzvPJlXywNtiu2+9w0nZyfqnC2cM1oEh8E1R8q5gWiUnaeNr65XYceMl/bja+g2g9QZkBAHtQArOZ+DePoejPUyfR1UUczARRywTFVTCS6vSZ5gAnujPuEcrOU5UTVgB+jicX7tqMh3AyJ9HBSDa0FCgK6PP68w4zDgIIFp5wRVBhzfPUNXHUkRBMuUaN7oGtq7VYaDITGLvyIFDIQ5FHLXiuy4OAAPvnf9/4pC30d0C1BVMPJEEIrj+KzlNSdUfy9WOxeNYn6vfsc0CR+soie0um5juwfyQWiDVmw2/lJcB47GoEqZ9dp3zXc91tsVEom7TADQ=="
			}
		}
	}

	class zak inherits baseaccount {
		$username = "zak"
		$realname = "Zak Greant"
		$uid = 551

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key { "zak":
				ensure 	=> present,
				user	=> $username,
				type	=> "ssh-rsa",
				key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAwu/7oKLKRTpxp0fLluRb09aJQ0LzFkN9mT1R5AhJHJ85x/UimXayTdZ67oJ72pteDEbLuGFGtJ3KsCs7a+L1e+YmRXKETap4Wy0ALsPQs7Dwvlp0AnOBcLXiWYtrdnAp21SKOSjIdw4Gd3RlcHAvWCAMKBodXLwInrSH7YLgD3JHwFyCBjqSqamfz5MPeoaFd8dEAPwTQUOHZfCHny9ljqTDrznIQTMKslM4TImw4WBYIfFtgokgBNTsZdRkJDqy4C8FztzphdVbPuRVvOPALWES12At2KlauofjM3wNMYB64jn5luqa8LcMMwdyz5MlXLfVV7MBpN3F6rlVdxob0w=="
			}
		}
	}

	class awjrichards inherits baseaccount {
		$username = "awjrichards"
		$realname = "Richards"
		$uid = 552

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname]}
		
			ssh_authorized_key { "awjrichards":
				ensure 	=> present,
				user 	=> $username,
				type	=> "ssh-rsa",
				key	=>"AAAAB3NzaC1yc2EAAAABIwAAAQEAqlaOugpX6Kz8NC2/5FdwvYlBE4ve9eTRHjD3/myj4cKzCkeKlDZT3DLxU+T4Eb7jmT/g+BeTohmafLoadg8d2YPu76HU5or7Ix6Pr2ZprDgNrLEnxdzhKeRZXT0IbXekKXWflmiRaB8LUH1MO9kTtm/QxlsqXRV90dExoJGNTlRiL3tEFro5zeiZ74qXFYXSAvofOAxueS/ZjIYmO6qHKuUUybo0/G/rN90wfG0tzzclhHv9dkUUgDqxj/DzXx37u9HxkaVFEDX9yQxVwQ1odq9oaIQvZslOMZZhaXoNkBlWjnT2+a99up60TOYbjy5tUNP5UJVzvtfyO/UPe6iZPQ=="
			}
		}
	}

	class rcole inherits baseaccount {
		$username = "rcole"
		$realname = "Richard Cole"
		$enabled = "false"
		$uid = 554

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid, enabled => $enabled }

		if $enabled == "true" and $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname]}

			ssh_authorized_key { "rcole":
				ensure	=> absent,
				user	=> $username,
				type	=> "ssh-rsa",
				key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAugxekmKIaoXPi5P3DXSG7CQM8tvDsaXjE9SEdAhQ0G/elNvjpaVUO1qp1OatsvcMkehlKsRC0/7+SsQVXJAANe0TD7gnYJPfQXq8aY9+Q/Jw+/qNWdTzlJpdyY5ZY3OuBXn2oDgmxk1RmEzCGYfjGN/+/tuQiYUoX+tJu/EbxMnZQjs9CTf3YmzKOI1Sghy2wHw7e9yYnnevA1zUgWBd0hy5CImxDquzgiW38Bmx1HyUJnaTmxeSoYG7/o4Mxqpx2HULPZNyrDuvDxpO3pUPqANgTIHalH1PrSlbpORm/mKlH16q8qvV+ea5wOTtev8/Hso9+Qh67emczngQ3K2LUw=="
			}
		}
	}

	class rfaulk inherits baseaccount {
		$username = "rfaulk"
		$realname = "Ryan Faulk"
		$uid = 555

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname]}

			ssh_authorized_key { "rfaulk":
				ensure	=> present,
				user	=> $username,
				type	=> "ssh-rsa",
				key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEA1WerRcJULxj26JimklCkoFUO6XKBjwTbPH54/hUv5c3lvyuUol6AF86rWziHgwIAy4+jPlm9mTS3IzWoRf0sSMgSrjkmykVaD4Zc+7QnXXGtnehHfryKTyB30TI39/JB5CoS1pGQQoMg67kF0nl2RKP47r0HY07m3rl1m5MWMTKByZ9p6/oVAuJ7XNxLjfN1N+Li7HhyueQonkw8Na4CxSz/Uj6zDgxB1Odw9LgHErgOe99Nza4yOsvpa9iq30eLJjXYKJ+9s8aPI68H+nBh8/CaBaPJkuTcYfwXhE6EG9JTtUrf43y88J+SDeN0lRF8w0SMluheIzkv/3TNyDdr1w=="
			}
		}
	}

	class laner inherits baseaccount {
		$username = "laner"
		$realname = "Ryan Lane"
		$uid = 553

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname]}

			ssh_authorized_key { "laner":
				ensure	=> present,
				user	=> $username,
				type	=> "ssh-rsa",
				key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEA5i6EW2Qwvv8bEEVOM9UQnSU9i+83pz0tmJ9zU37jimdMNmuxUb/2hi1mzmJlDRYDiZ08dIIO02MhkkQROQ629kWU+Dyx2RkxAtHF+vDmShpsp/PNSsPs6+3qDJs89Af7SRvAQJ3jVmQqJ1TzqniiLu1Ab87TDJoFNE2WjqlPlUWDLZa88023CO65dL8e907QR7OHYPLxbpiJMLYFvdJ1nByquo9t+iV3Iu8/WQS1JOPsGriN282qyc3EErir03et75kS7h+1Zhr+Z6BB0MO2cd6SJDl1cChcIrlHzs4zpufUzWXq9ELBmIaxYBH5iUYYM4ezSyA+qEbDnEpweJiW5w=="
			}
		}
	}

	class demon inherits baseaccount {
		$username = "demon"
		$realname = "Chad Horohoe"
		$uid = 1145

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname]}

			ssh_authorized_key {
				"chad@veropedia":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABJQAAAIB0gV8BlCV+bNI3YkVmoDu8XoSZoTswATlO3gPbEcE9oxZ0MaaEyHRoV2+G9IloreAfPvr9+bs0fHj1omWid5xB3obsh2PIqNVu8X5Se5Zyuqo9Vg3eKYaWFwINgcwHrUH2I0SpO2l/U7+Z4SPoRQpB+EK9+C2D6I11oschiou4qw==";
				"chad@anyonecanedit":
					ensure  => absent,
					user    => $username,
					type    => "ssh-rsa",
					key     => "AAAAB3NzaC1yc2EAAAABIwAAAQEAsWDBqUQBaIfJYCslelxUgpx1YVeKGKiAq1OZjGiJZMdjQb6UXPN44CgdamuZY2sFZo7D1mxI0uvxjv+zRfLChHkYQr5vPcPfsNzWAKLo+54rzC3aBhjgZE40H3X0W6x0HgctopCAVLET/tp9/EX5cstGBRw9CfAOrcF6jpCwWg42Y766lpvwcG+JtacuT/BqeO8wh+V1blLBIiF+ai3G173WwVXQ4e1f2/tZ40zKoy4VCMYLl0MtvPt4aPqqHPa+WNdx10aFWNCrDQIQa28EYcj3kw1pY3xlTORyxM02DgqFzqc8dNSU7UhTfL+nKR4kuG0S65e7SXiG48axnv/SOw==";
				"chad@chadsmac":
					ensure  => absent,
					user    => $username,
					type    => "ssh-rsa",
					key     => "AAAAB3NzaC1yc2EAAAADAQABAAABAQC/M7FcM/RpajWHfGsCgQiXo07cTkC9sQkpPvfInCA16Gk0rLOm1nJb2BKSlg5PhXLuJySS0iu7P95HJaKwoZDHkFc75bHx6ISRHOhgqUr1yR7S0pTdm+ithTi/zVEfc4j3KNQyift4o2pwVgx0CQTZjZL8sgf7XoKbw9YeftDt9Kz/KabNx45uB7qeH2sB7xnqixnb7knKu3rFN932eyFmA+G5+q2sPLjHNoyGhr6sfQi/dbUV1DDyd3zIs2W2Isej38WAX+B+KPT+mAj1uO9TUkY9v6ollDE+N92uQHiLrQDZ+dF4joDTsQu5ydai0QTYs5xNvrim/bMZHg+5F+X1";
				"chad@wmf":
					ensure  => present,
					user    => $username,
					type    => "ssh-rsa",
					key     => "AAAAB3NzaC1yc2EAAAADAQABAAABAQD74a9VKRGqzCmiWZZUkZoy1XnPgd9nlFTsPrBn8Nnf9mMBbzEArMupuolHOSFhczk5lC9y7KSRKiWJ6sypvVjfGZypr98SA1SEe5AxvBN+8DbWEpxxwbOGCMhHo+GPVucILa5cjzZn2iKlCli39oMa0Dxwzd7v+SuswNtfqjp47RlrJoG5hTZMYcbICjEVGNDvSxSXBX2E17Kxdw3CiPnvZun+twTRYEuTo0GshGjO/2fQaTnyYHfPKOyFYC8HDsaaSaOWzXPXb7ey8s4lY+vEt5Imj5OqHhNOuG+thH/5dxuSv6Jkfi1Ygl2t3j1aYdo5g/0IRQ1lIqhRQuFqxe7j";
			}
		}
	}

	class logmover inherits baseaccount {
		$username = "logmover"
		$realname = "logmover"
		$uid = 10000

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname]}

			ssh_authorized_key {
				"root@loudon":
					ensure  => present,
					user    => $username,
					type    => "ssh-rsa",
					key     => "AAAAB3NzaC1yc2EAAAABIwAAAgEAxrFa52jnHKDphkJBJWENCvBdopcnW74PI4dCQ39uUgSHqcbsy44peDOuTlIOoRG/uyYxRF7akR6Zd3ejgS9loVrF6dJB8VMwt7NMPqMwhmbTpZSrO+Yqu2v53Wx6ntTB+FJ1mhIJYFAzvJ3Cp3UGbd1whK1iIzi9t+x1rBg7VvChnmYogSTKuN8CzR9O4hA2hT+qFlWCcQJDBn7GaA3vwrtpCNu8kjdSs3N3ld1IazI9w0HRmso4qMRqP1vayUrPlGf1eEJZjZJ4CbLwiwhRh0orNAuERtUMOb3JWsIhTjj8F5zKW2ktUkxLZEgbBoj0nNvPwRIBPE8hXZP2SgjcArocJYTGsx0uyAT8DI5+F0aUScuxYhYf/59j4U1YQ43VvIArgMkXHG6/WXXsSeMqWOWfWPK8O1GYWUk1EfJ3elkBZFT8WnGB8OtJTaK//sIEWJpevElPKSxD74s1/TKP0Br/itkeuAFxv7z4UQI4NVU+WfCdI17NS/aasnRQeaVFCkQV+LSPVX8mLpky8j0U/B5y0oTChggZMymjjAhsa6N1CVIgHbugcM6+k4NHFBFU+l6pCbq206Q+MTq3hgSEzu6dd52XP1zMvqDmrp0G5sFK0Obo7YTx7EMhimttvsEUZ4NFWYDCfF57CYPjpaEXKmlSdbnCDE0MF71YWE1Yiik=";
				"root@aluminium":
					ensure  => present,
					user    => $username,
					type    => "ssh-rsa",
					key     => "AAAAB3NzaC1yc2EAAAABIwAAAQEAv86yzKoTo6pcgfJVQ51FAIcQ8NwUhWd93SKNRTqDmIkkMOe6lVruEManMOqJXGcVWp8WpCvqzkIyx77Y5HZISzVZL3hEfkJL85HyOn8gWB9jF2uNYa16Ik2nXR/HxP0w/xajJM8RL6qlC6x2hkCFsHYWt28ug82auZUHhW2mJwzdbJx5iHw7tHJiwXvBbXFs0WyjOB/J/mh/H+ohlcI5zH9S8pGgypMeFUen3wpgP18auiigARyhCTgtBRoWos9TmM16DMjskronEjvC3ArCBll5nUiuU0mrpPVfADSycMrYR2Glw3KhkwGAxbM3QMAq476U67JctXWPuqBnLazDPQ==";
				"root@grosley":
					ensure  => present,
					user    => $username,
					type    => "ssh-rsa",
					key     => "AAAAB3NzaC1yc2EAAAABIwAAAQEAxFTyC11zMrjacT0aXzAbBUKDkUYpQrxQFC/lnb7vO4aQkAZx3eC3IU0Xe5dDTK97CSOeuexkHOU4++dUXcbeBmsXX0lr/za7M5mb0IKRTxvk8+arls+WhPCZctimhsIHg/vfhGT0s57LHQHAXVmGTumYdQ3rbOVfsHubgjhyT7u2nlLLUi/cG2yP5S4nKF16wiXljrdcUdjNSXN5jsW6U0M/hNgFcz2uI33s6hNWPUcOfaHCwfI0FgOBdsNTlRyCqFydKoa9kd2NKVbdO3L3q0xOdugaUsnRuEKNi3pEQKVOxWy1o62oR1gL9NUwzJJiOA9dahDZ2z9ej696aEBW4w==";
				"root@hume":
					ensure  => present,
					user    => $username,
					type    => "ssh-rsa",
					key     => "AAAAB3NzaC1yc2EAAAABIwAAAQEAt0zYrPQ9uWGikvIQymX30hGeV42aSNnSZ3ClhEVMYHi98IJFFCFJC1UiQdhMV3p0fyVN0KZRTzYDFDsIKZxAN7/ZAyNaAujmRb5FBJ2IxDUaG89n0ZbmMz09BktVbM9jorzkaLatMYs4ouzjuH4EoW7Dbr2EO/cYAzK4Qv0wQnVDbd2bTjcJ48b5QWhQ9PWvytPOv0PgJTql3zUs3lSVAc7sOTU5FmwGIQBehGCvHJvepr/b8omJwTICQUsiICisJELlZesc7QdfiourSZIy3MYSMefhbELPGPBMC132bS8IhaC/3iFA8GAuTuNqaHqJVzrUm2t4r0ZvDJReX0zLdQ==";
				"file_mover@locke":
					ensure  => present,
					user    => $username,
					type    => "ssh-rsa",
					key     => "AAAAB3NzaC1yc2EAAAABIwAAAQEA7c29cQHB7hbBwvp1aAqnzkfjJpkpiLo3gwpv73DAZ2FVhDR4PBCoksA4GvUwoG8s7tVn2Xahj4p/jRF67XLudceY92xUTjisSHWYrqCqHrrlcbBFjhqAul09Zwi4rojckTyreABBywq76eVj5yWIenJ6p/gV+vmRRNY3iJjWkddmWbwhfWag53M/gCv05iceKK8E7DjMWGznWFa1Q8IUvfI3kq1XC4EY6REL53U3SkRaCW/HFU0raalJEwNZPoGUaT7RZQsaKI6ec8i2EqTmDwqiN4oq/LDmnCxrO9vMknBSOJG2gCBoA/DngU276zYLg2wsElTPumN8/jVjTnjgtw==";
				"file_mover@emery":
					ensure  => present,
					user    => $username,
					type    => "ssh-rsa",
					key     => "AAAAB3NzaC1yc2EAAAABIwAAAQEA04+NGTd7Vj5Qx7a7IMFfphwlADq67dSCiU7iU1R8rIyDYu0mKioEYjq5JItM0yEE1CyiDYOaYY+L40j11ySlD5+qchg5gMxigNVWcQ3L6lEs1p1MkIm2LtRkqPC5vfLJIuTJlukad6W+G9atdEk9Dw7zK6yVaWq0/zcNXxHiJC7lUqckGwy4A/mLecfiRhPL/4ksID2TiqKfvarpqg43IjycoLX65BGmOumDkzDfR5mvHcOeWsDdhB3b8rIAPfjLg1l5V3CkaGT2xQBSN/YbLB+bIPf7nn3b+HjjxU4JHEsDdogUn/BuaMQcjqfJjZ30h97hkyvTaQQ6DS5JI8eDaQ==";
			}
		}
	}

	class file_mover inherits baseaccount {
		$username = "file_mover"
		$realname = "file_mover"
		$uid = 10001

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname]}

			ssh_authorized_key {
				"file_mover@locke":
					ensure  => present,
					user    => $username,
					type    => "ssh-rsa",
					key     => "AAAAB3NzaC1yc2EAAAABIwAAAQEA7c29cQHB7hbBwvp1aAqnzkfjJpkpiLo3gwpv73DAZ2FVhDR4PBCoksA4GvUwoG8s7tVn2Xahj4p/jRF67XLudceY92xUTjisSHWYrqCqHrrlcbBFjhqAul09Zwi4rojckTyreABBywq76eVj5yWIenJ6p/gV+vmRRNY3iJjWkddmWbwhfWag53M/gCv05iceKK8E7DjMWGznWFa1Q8IUvfI3kq1XC4EY6REL53U3SkRaCW/HFU0raalJEwNZPoGUaT7RZQsaKI6ec8i2EqTmDwqiN4oq/LDmnCxrO9vMknBSOJG2gCBoA/DngU276zYLg2wsElTPumN8/jVjTnjgtw==";
			}
		}
        }

	class datasets inherits baseaccount {
		$username = "datasets"
		$realname = "datasets"
		$uid = 10003

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname]}

			ssh_authorized_key {
				"datasets@snapshot":
					ensure  => present,
					user    => $username,
					type    => "ssh-rsa",
					key     => "AAAAB3NzaC1yc2EAAAABIwAAAQEAuLqmSdltCJzltgEin2j/72k/g7RroS1SE+Tvfh2JRPs2PhWweOJ+omtVp4x+YFNCGBg5wW2GaUnyZkUY0ARzv59aNLsGg87aCCY3J1oAudQ7b+yjrEaE8QebYDPmGTXRDV2osPbXf5UFTzl/O350vRy4q6UHRH+StflSOKhvundwf9QAs2RXNd+96kRe+r8YRcMBGmaJFX3OD9U+Z+gZID8knTvBceVGibEsnYKhHLXLYvMkQF3RfBuZHSsWZiiiXajlcutrLTo8eoG1nCj/FLK1slEXzgopcXEBiX1/LQAGXjgUVF7WmnKZELVCabqY6Qbk+qcmpaM8dL50P4WNdw==";
			}
		}
	}

	class py inherits baseaccount {
		$username = "py"
		$realname = "Peter Youngmeister"
		$uid = 559

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"py@trap.local":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAo6QSWqR2j6bS3c0WzlekW9d5n3DlxhwKhHHd4GJScPiTwztyVCN8wj+flb7qfrXKx0CT+UY1z8VlnoktuTK7OyvifQAvyIrkeAbX2JoOP+8NVB3a/bsnqLjKqdvbrlndBtD0cbdqvd4XJd9OU2BoJtxNNpcBn/LEUK8LJ+PiAMO1PVEN5+UY3hqm+LM7syMxrWugGEVg7gHDpOzmQmhmqUQ3kXNfabjsgG9xyXa6TNqyKHvP0bhdWXAYjgMMeNU+IufDQdNJMFBKblo0QFqEO7/vgDQTnkc60/fvJSekRchSl9skeiE/nFw8O7s4h6fF1iZ4J4kiAF7nDgfvVCNi9Q==";
				"py@tarp":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAADAQABAAABAQDR6AzaHdH1o3fQopIaGGmZ0wT2VxUcb1tovmrIpuoWQofr8btP5ODPZ+r5hCmDp6YZNGHxUBgp2TVXyP+e3qC0g14igtFOhgD6MgoJpmoED8e6rm3r97L3NB5vvkWpZUEIo/aNNix8A4FouR4LqvF+1rHo5vI7q70JIKR00hbS6aOjC1pw5+bRVIl5LgSOH/U9UXSfKkTCKbVArvozVyJAZ1zv6lD6U2FYWCEDlc1Q7zR5CLy2I4wmzgjMRUFS3mwMf+KMNNdFxbpZS26i+YxMdFAHVMlF6Rty9Sw3TfgBnczXZ9qlix/vJdd/KBKw70EEMgJgfCaub4PJsOAX0dY5";
			}
		}
	}

	class neilk inherits baseaccount {
		$username = "neilk"
		$realname = "Neil Kandalgaonkar"
		$uid = 560 

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"neilk@zilpha":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAyVfwM6IreX+fjXaGwuYMgva6acyUdOB9JDrDcIJLIvzD1Ii5ChWDsM5I0bj6/H9hfSZAXEB4o8w2hVQR1zRDbEPR14eg3FbpR/mP9oU8rdchGMZbn/vgVFKVcjYcNb3ADlRiMRv3Jrmov6ZESV9Y09S6vGwssg3dabfT07tBdjohOHfg4HwHTTwhj5O72OMxOk1zf1kMsOKJ2l3bT0O8NavAn4by/w1gcXek445NrGJBMrdMLh1+WCPWsxaGI3J/um0eNXjxLLbz7tngRBP17JepU8EpQfgVRFy1GsOIxYs13TS6pvWZYfuLhugr0MTmHcyrycrOXZOGBHDFG9pg7w==";
			}
		}
	}

	class asher inherits baseaccount {
		$username = "asher"
		$realname = "Asher Feldman"
		$uid = 561 

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"afeldman@WMF263s-MacBook-Pro.local":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-dss",
					key	=> "AAAAB3NzaC1kc3MAAACBAMcz1/0w6tfUkS2RWeLS4voMnMcKf2Q3EVfAcBX818ssY/aGusB/CAl/NuUyPIzTHIE2gd62WYH0Krz+CGZ1qOzAxs+IoB3CjjbulXf0uIatcTu/OSrqoe0hXf6G1UidVl+7Ymomlwb7AMWScZeWKHmECbc5QQjLJ4h/Ply/65P7AAAAFQDJuUJ9zKoPn2GNx22da5s0WSS6gQAAAIAZr4we0xRJRk7pTLO+Ep+GOnccLycZlNctUMTZ5oDlGk9BJT3pjiYE3BXd1k8OwlDiLE37EiLP4oJXIsVXSm0EuN3o65Oi1opB7rV4rL7nbjZQdJUu+UN8ikQPe+3KQsiziupsP8nufgvufvbmQECNLHkYEiZsDdQjhCwHafdjUQAAAIAJX+wEMbR2dNlh/+sX3QTxYLSMuOKSGp9SzPwqyqX82GO4oD7iFKX6mBFYmFLq/JopGwKqxUQKhBhkBLYaCEN0K+DOnkxNz8oeGRx2YvQLfOiBISuHHL0QMy9RfTvGl7eE5JrwE6hkOzN3U2CeI2fHcsosdsL0poDmUz68GpOGTA==";
			}
		}
	}

	class ben inherits baseaccount {
		$username = "ben"
		$realname = "Ben Hartshorne"
		$uid = 576 

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"ben@WMF290.local":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAADAQABAAABAQDM17PSNhtrXqE8fBSBmv1I79kyBiwy4gNS1WjVqHraDDJ75TJGD9J673LkGgjHAerrG+u5nSjD0X+eJQXaWsZeh2ZZjnTcSyoFxge9t0n88F568h6OdYFMc0Obl9OHFANX4x5p1jsPqM/DBW7McW7QmG699eYdi0na8ubN97DSCSBw++V49x7QMx/2qYjAhJVJt9aCreBInGPa9FMGfXQKHdkS25Xh7PxIhk4XPYstey8FqUtOyIacdEGpQnAuMvKGxyTsvf/SQiMXMSvSvAOk9x83aj9cwcJgfrAJFbsraQ57oaP8/rpvWWW2PZ6xokgTtbdZ6lEK3bp2LVX0Pugd";
			}
		}
	}

	class gmaxwell inherits baseaccount {
		$username = "gmaxwell"
		$realname = "Gregory Maxwell"
		$uid = 562 

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"gmaxwell@gmaxlpt":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-dss",
					key	=> "AAAAB3NzaC1kc3MAAACBAP3J4fO4aWz5PA+fHzGKU/ZsqwItFRyH3hU3ahRtGWdAxWvwn/yyOyNs56VsPpmibLmugHqfrHIQFhv6wIiX6/U7Q03VV4WUd8fuXTYBrVPRAnIhQruQT8pGIljhWKSstYAdk2XvCzkIXrhrkzzxCQhdoPcqwPMvWpTWQvlQw7EVAAAAFQDrqUv2zfyMmx0KUy+kRphPx4JD+QAAAIAYeDr+bVOhJgrr7zcUpVdMMln+fZPwZZ+SIySzI2LbAcIchjJsvT5d9HMlFgFDJ5mYkydRosWdBQRSgJ6GcEeLjrhkNtG7HOTR/bR7zZuwQkr3qUqW+hi5Rm37ZB5S3uLUNl3OLNtdn4FT1lAkQWSuVBsPeTpDs90QNxSVfH1zzQAAAIAcRLEllDpoHzfTbeYbWsiQnb9CX2XNuhyilyqOo56lrEAca1sjXfgef4vECZpleznRU5OCMyrJvJiJyYr9K8AZ7q2x0NDdXImYaZ62luYHgqMccWHG9HIGiM0iDiyl1p9S5ceOk0wBLt2vHm/MzAFoUsH+OzjZ+vb6bMcbn831uQ==";
			}
		}
	}

	class preilly inherits baseaccount {
		$username = "preilly"
		$realname = "Patrick Reilly"
		$uid = 570

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"preilly@wikimedia.org":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-dss",
					key	=> "AAAAB3NzaC1kc3MAAACBANqUhyPERX9/5QZhAfj+4m8DqHGbnk56qMHGqTwKTfP1EoYq7tATVHx93CI2LkURbq8bVUcFFdfZfBwpKVGoFBiZBCW1lppDQFO+MD6lWABCjeWg5foC2X9yNoTMc7BEBgOWZcPSwj2EyYS9VeWko+GxvM1JAG3C5U5paWAGj0mrAAAAFQDt4i/pu61OEdyg685hHBqWkpvvYwAAAIBkUqw656A3EOSf4qjv6Ph9AlTzpLhglqzdwYbOZ0CdITnfSuZ0/lBmJjMg1Kyb28eGXCA8FSF/liz3dG0eDFKVPxsNFr2CiZs3IjVPVaZPwjnxvEMPRECj8bb8w2GqX+q3fXyPt9h+Y2Q+I/4ZjeGTnta+PIeSp8Vy58Xw+hN+6gAAAIB7hoyYs0F9vhMmydoXIFjxo8edMe33Sdx9uKWcycDvNiDuk5oQb1K0v8UNVvwNIV6jH2F4yXFVkV79Jk8FUqhzRs1gPGJQeR8Ve/qWFtJJqUyDYPWyRJTLG6ZY+KrIbSFec2T1V5NTy/jWz3TZobhd9PdxhWN3QIKFqX0kpxvnvQ==";
			}
		}
	}

	##### BEGIN ANALYTICS INTERNS #####

	class shawn inherits baseaccount {
		$username = "shawn"
		$realname = "Shawn Walker"
		$uid = 563
		$enabled = "false" 

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"shawn@Eeyore.local":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAgEAuA2p4U/s9OEU6xnv8VO+SAYOu9A/udnQCFGRAKbJ+oNtBhlxEbQe18zJ657UdKm3gRcJ2gW/9MVkqasj3PagTYpw6ffrT39s6vneUYu8+IQP1RfWCaMIHOPa1BP/eF11bHUUSHsxFSISiTiC+0Wzg1ot/8K1Xz6C53NJj1dSt+ILZCI8e3St01tQ6AXGaG8QnYzRS9kDrB4AK+abTCYd3UJYaUnGsjceGRN0/R0z1cYpDSvXSvdJT4UVk92t4H4MhUvpQ18raxj4RuebxJIUkIJpNVCheAYlHp88F89Flo67iSscZZryOmXkgMRjkxkE9D8iKX5Wc8/w9ELXmWNGakQff/uN4ExhzlWudKAIywPFIEP9TyGVxxyPSkrQUc7R3EHDFYokqZrJ2YH/Nd+WsyOjXD1J+6nqM1CDxEICmIYDSI1lu3KyKasT3Z/HgB6svokazKw5MrEu4gwD+NwkM1OiLbz9a6k/IiIp11Q2syhKDRN7G1asvXgK1gwFJ+tNeoLMbjbdHd2TTBSKsvd6lqJbhIveqCAbUPlK3zZbvEKxPDuDFhQ+qSF+2vbtuS9LCX9QrdW8T6/VpSop6uyvGJkA1bQ0/tdMpP2eUVnML72BttT1VYdwLiUZk2/TrRtQ/6Ciw5DwrjVxg33D8pm9K/2jm7uESjIE1I9iALQTKhU=";
			}
		}
	}

	class halfak inherits baseaccount {
		$username = "halfak"
		$realname = "Aaron Halfaker"
		$uid = 564
		$enabled = "false" 

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"halfak":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAuTdhPxqwEA5HR+HSH7LlPpKdducUsHg5YfIAd2pISraE5vNSYmvMGQHTLdq01JIxZHwCsKZ3UjdE5mL8/IANXR3Azk6v/Uoz9N5pBvH07/o5ZzDfTI+ZzaJw3ejv2C7lUXfbCPP7J+6BITV/q1UluFwmSOnwtSQ91s9/iXGLb6LrKkfXOBUz1P/hY+kF/Iw3zykBCpVkqIlqo3wBJo7i2qwL/zOxrRTuqzUyfCy+x87qSp5e7KUP26b/xVc/9km8FWO9twDGU6BotoyxHWZIXRaIrHgz96CCtDFFn3+TCGy5LlHn24+UtBFZXPfH0VsM+L7ZF8k+HMWxR57M7IBwtw==";
			}
		}
	}

	class dartar inherits baseaccount {
		$username = "dartar"
		$realname = "Dario Tarborelli"
		$uid = 585

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"dartar":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-dss",
					key	=> "AAAAB3NzaC1kc3MAAACBALJJr2K8ifFwcRrJglPqJLClim5DL6zuGFST2rE4+PAEq5AuONZVznVgmBj9ve06h+86NjFy4WBaa6ncVXMblbAwlfEEIl1NxrNFXA9s5+Y/qtlnTqH4VylLiz1Fafqjt+YsTi5oUXJ9mR413PvANQ6hykwPEaAiUzHleTcsXXJZAAAAFQCbAsJaAgW2tf36oCgp4ysZ4FWHIQAAAIAQ0v4ATMrm9mfCe06tyQW/JJKiEVAjrpA9LujBx9HJIR+z55Ofa7ogmaFqRJcPZw6u9U4CnO6ch0iKJvhKo84TVIZnQ7wj+H6AfrXOYAKWUDqCpqswhMt8qOKekkTzZ2TPDoGdOuERzOXHqhcN2b2MUw3RyIKmvwP/h92SBWrVywAAAIAKN7Oyuu9a9cADbY1u62f1Lefxjbi7HJdxUrduI/ewUWjW9KIjQCPOuWBYLF7VtES+agvuo3A+OCHAJFluZp46L2Uv0UsdBxrOUeVu1xVP9iziUBjKqU8Sw3gWWu1Nl1qEQBCP9gTTrdMekgrmPCm4NHMYIItsbVZ/jrsret234w==";
			}
		}
	}

	class diederik inherits baseaccount {
		$username = "diederik"
		$realname = "Diederik van Liere"
		$uid = 565

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"diederik@Diederik-Van-Lieres-MacBook-Pro.local":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAgEAtpE5YKnKPgHmFG5a8x/1lfgRUIFhv8Vug/57XCMeuQMG8NNUuQAno1OWYT1ukla7DO/3KF+iWAkyLlUq3z+rO9WB8/BuxLOsNBd0dBF44yoVsjKkTCdkuhh/3a47uIGAKhGG5Cj+c1ggAnKGLMgfoaF2H5vifhSp0hJbRGMXxzC+OoVq0X34GnkEZK7YZAg2oYVOyLRbOYNDlXLdIUoQ0579/T8/ey8mZzbxuONZy7UuRiFxwOB3O88s5SBhGwKHR/3iJ63PE5KZ+OCBg6nTPM+4rYfQHIy8lwvna2OAgweoqQRmn1NFpZisqhWcAAABKTyJ6MYQu1J/6SdGI4QehWEinsPud/ZJ7EbrAWotLTnDaeQnPwdQnSNVTTm6FWKjkKAbzcIRpWqw32L5fMU/hwmJ9K2GQSYHxdiGIdlgXsI+Pel4dyhtbl/UT3Zj+BWg71rGF4SY7lHCfAm+3FbbBa4wHSQExa6k6cFUAv2mPnUuBeLKBPZnZc4kRBehiVV16ddiyYgDwhjO3s1CLcPLz4napVDviMj4QSC1Em1NsqKPNIwITC9rqFuxhjoT9Gz7FpA4OWkQaqECkO/L2NjP6vTlxfpof3tD9+aagCfI11JNNG06oFMjc+GhvObQmUA1ZtV4xNhYhFJDhvSmxNwF8Bux2dpPwaaemBZtgfUEszs=";
			}
		}
	}

	class declerembaul inherits baseaccount {
		$username = "declerembaul"
		$realname = "Fabian Kaelin"
		$uid = 566
		$enabled = "false" 

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"declerambaul_wiki":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEA3aScUQs0HeQEp/pnMuJ6JKWTwEa8IPVKa7Gkrx2DJ3z1qUtA5wzxSG6m//MJBokIntwBAGuqRazAqs5cB3m4GVqViA1fabxZy55l1/GB+962/d8goVEbtkj/MO47vuUBosVSy5GGjGOs3hWtKId9q6+AU0OCNZwC3j12tXGIX3ztcf4Ef2pdBoCfJMgrvlnIpdFDBftrua9kVvYRQj6tVr5rTbFlEioNgNcdQXhvDP0sU81i1NG/nAeOZMDYOzUscDHa6JcCts3nRyqrqgaMixxGjF7WG42tqS+AEqKi9IOqFnaiHtwipZrnJJ8IxtDOve3HHA3VctBsh03qB4RZ6w==";
			}
		}
	}

	class whym inherits baseaccount {
		$username = "whym"
		$realname = "Yusuke Matsubara"
		$uid = 567
		$enabled = "false" 

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"whym-mediawiki":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAIEA1LYOpxAxnuIgjkZMkdimojSVWGRJtqbuxaiR4eHZhYOEJSz/UbDaDjb9ni7MIbyLMPdj4TfPzq3mJuSxPWVG0FNFi076zgEDKh7tOohFz3aFTq27/WZXZ7IZkmECA+SxdTOOxq9/sffKmzh4UiavWJLBUTznXufeo7P2LcH6BS8=";
			}
		}
	}

	class giovanni inherits baseaccount {
		$username = "giovanni"
		$realname = "Giovanni Luca Ciampaglia"
		$uid = 568 
		$enabled = "false"

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"giovanni@titanus.local":
					ensure	=> absent,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAs/+a5RVrxt3LPd4+zr/xtMAQfm+HpYk6lOAhfG6JZB6NusRKOR6HFbzTKFQ7v9S676bLZXdD8Cu2tuVspegMdx+RGw4uNlISrxpyp5FXBiXpC10oRVlk5cMthhWp94JDuBFsVstuXR9FotRF3aScM1Hdv5cRFyXDvJTgprESXwFm0uH9MDi7xdJpTKYAV/8Q83IFKwz/6IUKEQ8cnBKfLY9wVIgoQd6I1eQ/4pVuoLcCUQIh/zreFMbfhyehArKVPeyOtgR4gRKZJxlQcVuvbzZFLexyHf9VZrO87IXf+LaSwvWVlBPGDD//8g0Kl7yVCgQHlLzbctB9fBZIk3FS8Q=="
			}
		}
	}
	##### END ANALYTICS INTERNS #####

	class jgreen inherits baseaccount {
		$username = "jgreen"
		$realname = "Jeff Green"
		$uid = 571 

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

                if $manage_home {
                        Ssh_authorized_key { require => Unixaccount[$realname]}

                        ssh_authorized_key {
				"jgreen@spork":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAIEA0065bEe76amow8pXj+cS7rMHajCMfBCrUxOlijTgUv5o6e1v04hm7iEwxadcUbPrauGgsZOoeuoLzz3J/oS7qb1pliNKgdvcMw/sA+sqZoh2iIKjwLkEu49CJJ6Wxiolg+p3Y8yQHOUTc7sozkREkXsDyZZsNbmOcwtDlCe5SJc="
			}
		}
	}
	class khorn inherits baseaccount {
		$username = "khorn"
		$realname = "Katie Horn"
		$uid = 572

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key {
				"khorn@wikimedia.org":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAADAQABAAABAQCo0sPfXSU/XsJzevSa8p9rODZabOwVbv2zx0htASdEB++TaMk5k7s3rTznNjTzD8mgia9h9+Dl/9lUBnLeiWeEPDLYO+KiITs4pZ+akL/4ilWl+CJ+59C8Wm0apsezQwaMEuPGzdx+3MVrqwhRdl7Fg9DOMYIz1n5O2Jrr2QnD9TamWFw+yYhmZBkl/Ci9rbU/T72A1cL+D2UVFk08B+FH1d48XDMoaUppLbV29/fc0Fz4f0gZkLYBKmOo+xpZ8SXkVieP443a0uGyfy2FSljnqF42dP21XO2tqaAtf9q2i2sq8fnB072C7oIYleVKLfLvxk6C7mYvzTN8A3m4RCLJ",
			}
		}
	}
	class kaldari inherits baseaccount {
		$username = "kaldari"
		$realname = "Ryan Kaldari"
		$uid = 573

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key {
				"kaldari@Kaldaris-MacBook-Pro.local":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAnmxqe0czLnD+blnxcDNRsOF2MDhydEMtUqWwHytxJeU84YmUDRuqxsEhKCNRSxiZvSf8RrPfiO+OiF/nF7ECdFTvtihDEfV89J7oemACClmrjOD+r41CNYCFhpI+fZIUzNuenf2h5cMx2Oqg57i+uV5PPSNX0U2VOU4HUgKl4ymjRW2QGpvtNmtQflwhXPD/9ih7VqlcO1DEbEPj5+jN1LvY86roaW8JDz9dvV+zmoe6yNcHn68W5bG13qOkfW5BCnVxuofIwN0REvINFAOliHF7gErXjgBqJiDr8O1xopc67+9bHLaqBKa7ji3aJSmrOcVvRlr2o73M1hC+NoJ2MQ==",
			}
		}
	}
	class zexley inherits baseaccount {
		$username = "zexley"
		$realname = "Zack Exley"
		$uid = 574

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key {
				"zexley@mb.local":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-rsa",
					key	=> "AAAAB3NzaC1yc2EAAAABIwAAAQEAnxY39MUzzNTIfKkR20U/qTl3+ayt5RM3CwoQQKdFMLw6waL3GC7F7XjbY8EOFnm52eDyGWsfdoHfZSOYJADc+Qs/e8T2aqXHcKTYSo2Y8JZRw6qmzthvGJUIGfG/A7BrK3oj1nSwyp75EkU+qSCtnIUfYyg2hwiqNc+IHdRPxp/hJyl2oqrXTLk2+XpOrdWjPMhTPwjzj1i1ZV3HGM4xBTye1W1ZFTH/2SETlSTLRhoczahCKt9g0TdCxMBqNHVSRTmzZ8IcF//LEdQRYxfjyPQpjmcEotXvmB2dXoimq375IM4D/Ml50dCiH2a79vPee/BG2NV9FTlRfCvqOmQuDQ==",
			}
		}
	}

	class sara inherits baseaccount {
		$username = "sara"
		$realname = "Sara Smollett"
		$uid = 584

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname] }

			ssh_authorized_key {
				"sara@Sara-Smolletts-MacBook.local":
					ensure	=> present,
					user	=> $username,
					type	=> "ssh-dss",
					key	=> "AAAAB3NzaC1kc3MAAACBAJzkjaqCp+VxgB4f1TH8vwYAM5OMKH6LFH8wdW3byMQkAqVYjh3ynSEs/DIqtuHMLKqFxFmOAmBusWeBQ9p2dmbWPN39THRwtIiXRr1ELyxML6oY3NWDm7wWD4hWz0ZdsUT/6X6yzhrVbBStGlORdjBWiA/8gSiOrZHP1UJ2frPjAAAAFQD67sNxyBwcvH/EZKI2Wz2O/hcEfwAAAIEAiaDIoJnkKBMVmxJBqY/r6ko4fnSqqAlkam/41aiEs9OwmX5LPH1kkneUge+bfkX3pp86pKG5xWBw59qJsL4FRwQWtX8wsP6l9xJj7qr2Z7hCJnvrv3rM0mYpL7o/8BDhwauJJ68ObcK2t/2UMqnZ87jUHZBb/l1t3jInrLSJKYgAAACAZKIh1AGbUxixY/V9RdJnQ0/oWbF5PEa149sceIyB8q7LSixUkPi8cfVvOHKNqMwV4InBz2GZyANWRtHbk75UUuuJDklPyQsif58vokJIsVw733Msx49EVSEUVSl3ZQ7c9oLmsXp4UsGW6C9Hh/OwqZA3VrMT0zsZqZYJ6mmZ29M=";
			}
		}
	}

	# FIXME: not an admin. This is more like a system account.
	class l10nupdate inherits baseaccount {
		$username = "l10nupdate"
		$realname = "l10nupdate"
		$uid = 10002
		$gid = 10002
		include groups::l10nupdate

		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }

		if $manage_home {
			Ssh_authorized_key { require => Unixaccount[$realname]}

			ssh_authorized_key {
				"l10nupdate@fenari":
					ensure  => present,
					user    => $username,
					type    => "ssh-rsa",
					key     => "AAAAB3NzaC1yc2EAAAABIwAAAQEAzcA/wB0uoU+XgiYN/scGczrAGuN99O8L7m8TviqxgX9s+RexhPtn8FHss1GKi8oxVO1V+ssABVb2q0fGza4wqrHOlZadcFEGjQhZ4IIfUwKUo78mKhQsUyTd5RYMR0KlcjB4UyWSDX5tFHK6FE7/tySNTX7Tihau7KZ9R0Ax//KySCG0skKyI1BK4Ufb82S8wohrktBO6W7lag0O2urh9dKI0gM8EuP666DGnaNBFzycKLPqLaURCeCdB6IiogLHiR21dyeHIIAN0zD6SUyTGH2ZNlZkX05hcFUEWcsWE49+Ve/rdfu1wWTDnourH/Xm3IBkhVGqskB+yp3Jkz2D3Q==";
			}
		}
	}
}

class admins::roots {
	$gid = 500	# 'wikidev' by default
	include groups::wikidev

	# in addition to adding the user to this list,
	# you MUST add the user's key to /etc/puppet/files/ssh/root-authorized-keys
	# to actually get them root; that file is not in SVN.
	include accounts::brion
	include	accounts::dzahn
	include accounts::fvassard
	include accounts::jeluf
	include accounts::kate
	include accounts::lcarr
	include accounts::mark
	include accounts::midom
	include accounts::py
	include accounts::robh
	include accounts::tfinc
	include accounts::tstarling
	include accounts::ariel
	include accounts::laner
	include accounts::asher
	include accounts::jgreen
	include accounts::ben
	include accounts::catrope
	include accounts::sara
}
# mortals are the software deployment group, we should rename and rewrite this someday
class admins::mortals { 
	$gid = 500	# 'wikidev' by default
	include groups::wikidev

	include accounts::andrew
	include accounts::awjrichards
	include accounts::aaron
	include accounts::nikerabbit
	include accounts::nimishg
	include accounts::rfaulk
	include accounts::zak
	include accounts::demon
	include accounts::hashar
	include accounts::pdhanda
	include accounts::reedy
	include accounts::preilly
	include accounts::robla
	include accounts::neilk
}

class admins::restricted {
	$gid = 500	# 'wikidev' by default
	include groups::wikidev

	include accounts::ashields
	include accounts::austin
	include accounts::avar
	include accounts::bastique
	include accounts::cmjohnson
	include accounts::dab
	include accounts::daniel
	include accounts::dartar
	include accounts::erik
	include accounts::ezachte
	include accounts::jamesofur
	include accounts::pgehres
	include accounts::rcole
	include accounts::rainman
	include accounts::tparscal
	include accounts::khorn
	include accounts::diederik
}

class admins::analinterns {
	$gid = 500	# 'wikidev' by default
	include groups::wikidev
	
	include accounts::shawn
	include accounts::halfak
	include accounts::diederik
	include accounts::declerembaul
	include accounts::whym
}
