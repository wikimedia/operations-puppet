class admin::users::dev {

    @admin::user { 'dsc':
        realname => 'David Schoonover',
        uid      => 588,
        ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA90Dj4DCHCIIRQv4K3+s+HAZUWZXmmY6rEhgaClq7tWZ2cnwQrGZJbRlhgTjfykPkyI6l+hx1xqMDz4ORGzMf1y/Ee5tEa+Btca1kfvY/N8bma1c3xO40M06/AC+1jyRsvng6byoCpDzbN+TrLWhwkKZglACR9i0eqoa8eJ6Sv9L1hz6bqjDoS8DXEx1xJNT/It60wyB08OVN2s2WiM/Cr340j6AdkyoTx9O2oigiOdOqfTUVXpK87zU6Ph4PxbkDtpfmyPEwX1LPmuwAie6b3MW0/G48sIZpJG0847m4qEDE4k04/E6jDYFssGB1vWDTAA1O0L2rIcQ5K6d4bFkzgQ==']
    }

    @admin::user { 'mholmquist':
        realname => 'Mark Holmquist',
        uid      => 626,
        ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIAim5ZuEvBLdg2XabmNI5OHHQgBzi7HJ/AHZj0AeZCdfFg/wwB1TiarcDXRITf2ZVVn2caTuayKeA5dzDWOz1ouZycJ9L4rr2cgs3pz0TJfyP63usqevnwYpHFiFlYHqyR37+JaUrWknHTcslAxeiL3zAHrRLjqI2H8zyajWJ7AWdBLMSKKan9EoFpZ4oKzTYr7A4fGqj70yXw2c4R2qJNuXxmG4CbeVL1bjyTd+a8OT1Ixx3zuMtVCHL1QZDeCtBaMpF62cKKkUM88btoKh1ESSmzQTWu7ZJP/LA1nnTukRt4l4kWv33zt+iAa5KffxCppx77fRSbOlkyk0dqjrj'],
    }

    @admin::user { 'demon':
        realname => 'Chad Horohoe',
        uid      => 1145,
        ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD74a9VKRGqzCmiWZZUkZoy1XnPgd9nlFTsPrBn8Nnf9mMBbzEArMupuolHOSFhczk5lC9y7KSRKiWJ6sypvVjfGZypr98SA1SEe5AxvBN+8DbWEpxxwbOGCMhHo+GPVucILa5cjzZn2iKlCli39oMa0Dxwzd7v+SuswNtfqjp47RlrJoG5hTZMYcbICjEVGNDvSxSXBX2E17Kxdw3CiPnvZun+twTRYEuTo0GshGjO/2fQaTnyYHfPKOyFYC8HDsaaSaOWzXPXb7ey8s4lY+vEt5Imj5OqHhNOuG+thH/5dxuSv6Jkfi1Ygl2t3j1aYdo5g/0IRQ1lIqhRQuFqxe7j',
                     'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDptp6lYbp9jlCe/wjp2gHH9i6BcL5pgrEUnjz3f+q8Scfm4Tzs7wTSsaAsfYmdYcI8ERJW2ZYU3BRiPqPIyCmOF7WaUMSM0qTf+NoZpfFb+hV0J9CNfdjwNCQGbsZyq39i9u8hCmZg9+fg+eSZ5q3ceH9MJCckx571YtFJs+F6DioCUlad5uGg+2sPE36cbJtQOmmC+Oys+E9go/vJ72mrxEaPoBUP9Z1p8c5GhJ5TjoSqg+bYUsnV0d9yZPTrcyWeeCWeumeQe5YKtG9Z0EJ86axQgKp7nIBAL3EovTTaPTBSMusfjvftCjkIocbS7eLt+6LqgOyxtUWco5oKCtQn'],
    }

    @admin::user { 'krinkle':
        realname => 'Timo Tijhof',
        uid      => 607,
        ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCm44jLSJBG8Qul5VNqrgvfUCjOACM0v1RzehkF7XMYRr+yBzBGJlRSHOs6/aUoBauJDPdM2VSb1LR3PCALwczYmA4Slnm/9rTfq0U/CAeFjHKBiQey4cntKFrYIUM0Qf+XsaDBQ2uK9C2GOw3Lo9RIYfq8Kz7keS+xtkk/6t1oypAcdG6Yt4Wi9z8Mgwmtd08mmT17yszxCf9emq5fo8otUC5nxWmXhAtnL5baaPDbi/0CpX6jm4BIAMm2jhGN6raYHLPIBhqk/uUa3k2EqkQ2gncY1judpyiUHmNB7dg9rDpbHF9pR+EvdE+tGRq8iirJzEbP4ErF0Vw461swIOB5',
                     'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrF4bY2ygHf70rOL3GGIWGurAXo2d5X07g+tzV5189kgKZs7Bz7l8R3NwzcCwuSIQqEWryjZN/lGa6lUhXaln16Ks/tn21eSfuI7TFjWZbLbQHJtf+QYhLA6dRBk87qfGW2z05w526OxRt7vPYo6uutdV+jt1wbpbMhA40cttsyDzWVqZ63TwielxaAZFABA1Tr5cWZbS0tz0Bmoiri8PPPDjeV9GCS6ApRZAeOJjtAeChu4RwEgTgHLkdACGJSg96G0BCT0Zd0RE7q357j8DlMbvw6a93DIrlhSrma0snHRHsi/fS7g8ULa/HmhweJocM+Rzd+URAaBSegNnlK/Hr',
                     'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDftk5lndsGU70RXMNRlwGOT2qr/SSBQZog07fs4F5wBL5Uevf0bZkwFokissYOO02cgYy2q6SyN64SppfnWXjOJtX7uv1gasfxmufNMx1c/JIl3m+DUodkGzXsECM66ykHSmaIjLvdpsqS5FJ7FzmkAOQsQVvnzK+Ltb7XyOd1zf6y90SB6wo03RHalLoAXEP0GmKPyv0Tzvad3wjSxS6FxTAFji7wtdSdwOxd4xOQ606h4H7J/JRHWJrmGX9yn8BLPDXXB/3a1lBasaZXEyhd+a2RXvnMgPdqfRSpQRD6gRsaMoj6UiKG1+RoUlttXaKb4COI8llG+Q3tVzWm6IJr'],
    }

    @admin::user { 'hashar':
        realname => 'Antoine Musso',
        uid      => 519,
        ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAvt7LIRTvsztelZFaFB+3eovqapFo5Lur/SJoxcV+O5YxPAA6+BBXuhaORJIPgq022VcJAZagZ4CaOEDRVIMJnu3olP5DRwgjGbiLxtFaMglahp9aFUFDXQ8z7ChY3HE1YYPJVkSwchWBcELZEOoIm4423AleQb0ZOie24xH/l4M=',
                     'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAzNhpIeuPMLolSk17uv9edHPmPHrxSNEAT/TofxgFyDrebbiExixcT0+riF5kB1BKlpyIIpiIHA5FNgQI6v40QOJ8YA94n1KIxp9hXGNPBgEaoTs212LljrfH3Yx4/6FPGhiFCC29N5oHwwav1RGi6+YwaoW4lSDH+x6YVI21xQE='],
    }

    @admin::user { 'gwicke':
        realname => 'Gabriel Wicke',
        uid      => 622,
        ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDSPEnznabK4A8LBxTt/z18gW9THN2QVmGuY+y6uvSsqM2cXrj0PCvN3+sDKqNrp7jvuu/3JRGl2UcYTT3uU2L+r4nYud7axhodwlCepEUZlVABu4n2BXaBAKb1vlAdOnGLZm88rviT08aJkmiQGlm4dV/u+kPVJIcN/1ewjynWVcH7suZtVD0I6GIvZUU8PthbktBFZ6lpC5b3TFv7IShY2/qmbVFXjrFrfDZ6fMecabx5OvpQK36teM3LD0DYfpE/o8JCsjEYmBNQAXvK4MBvyKnqPT9QL2lkVd7vLpfjtVPOFlaRRc6ku7nS2gRZSpGgE70pAmu4KxGrzQvhi7txECmVIcfvKG2474xwwTVLdqhqdEkhvdPPLRGCp5Ic3YY0w9DLx91rwLKh/7OdbxC5EKF+ZNaB4pnuq9vYuC6Vl89/g+Dw28OQyE6pEjltqybEA5T0sQPrNd5U9mEabRWhjX7hkXXDSmfRs0XZ6Yi6u7QZUO+0aqaoiHCaAygmyi94aiAXqxFaRu+2JceiTpRDOxeHU1KupbuIDPXK49zyi+QkfKNJ37GPqe5hRsw5cq0AA6+GchzpJr8p8XIstFv87eNB467NdQft8uVvMjL0fT6HZ9Gzkr/ThCZs34OnGDPLybkK3pwSuv8zRkggDK7yRB6bvDDYX4s7qoHOb1naLQ=='],
    }

    @admin::user { 'ssastry': #RT 5512
        realname => 'Subramanya Sastry',
        uid      => 648,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDlpsA8yuweHpvf1MqoURe7npQV5PlqwVjIGSshN2BWUrqO4tzC9mvy4vfGyvKdfPMFUlsk8hs6BQgMbIY3Qr3cF1+62CH7jx6FWzRWTZpFfyckUhdJu22vaxwYxzZu0au2zIkeVaHqnV+QYPrhjnvcOrwosF4ArfW3guXH5gjBF9RsJWqlC0xejiaVVefsaEKan6cOLslLG+caQalJdNfJ7mBs4hPKLQWF6d8tbWld5/jJUL/hFe188/hkyLyfD/TSmRyWtoN0q4Ubcqx3LMDoX3EKYAl95i42a7TT+zg2GOOZXLk9rruFKk55hNfg4R3T+JxAffkJygKykyPvlfhp'],
    }

    @admin::user { 'aude':
        realname => 'Katie Filbert',
        uid      => 1185,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+OiQ1ptiP6VqmiP8IOp0sKET9pQHOJxscK6bAvAmAP72DL9MgLIBaWpaL9iWsb/DMXI2CQpEnu88VMVXCSgiqw+Gy6Q93pAquAQWAzkMnDD+QvxTm23oFCxP795IEP3JMHuONNg2x3NU3jYaOADOGZX41nRhbkO4yl32jQCTF9i670KS+CFDHxRzmOMzNhlytWJYyVPS6iqUGykaFcebFNThMtRtQF+pWJNreCFxZoXp1TyzkiJE1rX98tj2yhVQmET6mENuGXuAES/Atzpxp8zvsckHn06Mm1RZZmIExEqn/JdK6nHs1UoSNpsI195ltzkKSEWdFdYKRLZNFuRBL'],
    }

    @admin::user { 'andrew':
        realname => 'Andrew Garrett',
        uid      => 540,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA2Di7q/bc8OJ5HP4X2U19r8w/mIH6CDbZHkOv//5cNvE50udM7McwxRWSz5idIF2P2JyIU2tQhixM3vkWO2chcifIom60F2/vhKA+TuUr9l/IbnBv6CoCjeAxre0g3gVhcazHKKtjbpRMYRxMSrLs+SBzsQpTuB/MqJB/jy1rUDTLCwN8Dtz3nAR5vRtgM673kivDLvDsHrfgR1uScESawPe6c9iFLbnzptH4z86r98tj3s4U+3yVFaH9AG7YuovulyA6UEgXFL8swsrpp58s1+XIausfYAqjetIL0YS3vOwEeBw3Hg57c+bZ+dVODEV6wc+uOgtJFZs6zVHTFq5QoQ=='],
    }

    @admin::user {'abaso':
        realname => 'Adam Baso',
        uid      => 639,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDoKHi5isY9FixH31qz/81V7fOHsorLZI/NLKr9Z6Xawl2a2Ih0ZV/pJtD+BTu1ufK2QOdgobeRSrnybzf2/1aCqi3Z9H2XxJhMCfnLb/9AIcKJ9tN63T4nRnjLoPsmRgDQrOSIqY5NfLKzXBsQOqc3chZ5SaDf8f09OdBk+Obn5vhr6yWh4GhrfTzoZUfp6+JRiueZZYuGMIKdBAH82s9TyuhuGWvHJmO9WC1MJOV/3hIcim+X0xR+BNLEU/Uj4OPEXC0/EiXh2CJDLugBpLU28RF+Y16TRj/WmO2H0H6qVdmkiK7Ez9PCbsy4RFPq4hdART9QiQbQJzZzaYSAkSFV'],
    }

    @admin::user { 'aaron':
        realname => 'Aaron Schultz',
        uid      => 554,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAljtlNa6pQX9gEyjrpCUqqQyO1HtYtHFSDuWBiWX5oiLnTSXRr0e7pECiuy9ISEI6oIt7KkaU68+cxSkqK6gwr9YwZ5Pmj3kkopT9LjguzBYxN3jEOj5+oGwdyK6ivQQA/PwPEtVgk8LgJ0EKf+74lQ4cQVsZXyu25HTq3cjfLgQRpwoYc9OBuuwIj//3uhLvIBKS3JvO3BGFsjZBPJmxoZr6+HJI7lXNfy6wWbbinXMS0gzVYhHvPwU5lFYSN0/njh3gCV8EwBYdzV6PmF0q6HXM0R1gLH2FfrhwJY3mnveWu30B7VXENYUHqc6H3wUt3rS2koTHOMvBgy3PbNCyXw=='],
    }

    @admin::user { 'awight':
        realname => 'Adam Wight',
        uid      => 616,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCTng4vgEtyrjtl3JDNv1Q6M1PVvHWIomE17fqODCvFx6eClupAmY1XExdj3x6sPBtZd2ZStwH0IopkKgF6172b+0fl/ReMUq9gOiywKMOc8/wf/fYuWTI2TSR8MfdYrkq6k4rkn/6WMUayHcHrYl610Wi77WJ5a6PF83QRo1D3VAy69Z8PA+P73tTur846iOgfuDBfKw8aTb6mvwnq3hELuuYFaj8cVkveqEi9m2TYDZF/TWvLRbNTQvh9MloTjpOYhtyNYqeWj4xxjVWlr++RPeFa92TeePzKag87O+k/g74tUSfTqrqjhGGK615JPHVWNWMmNUHeFcajltKAf67N'],
    }

    @admin::user { 'awjrichards':
        realname => 'Richards',
        uid      => 552,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqlaOugpX6Kz8NC2/5FdwvYlBE4ve9eTRHjD3/myj4cKzCkeKlDZT3DLxU+T4Eb7jmT/g+BeTohmafLoadg8d2YPu76HU5or7Ix6Pr2ZprDgNrLEnxdzhKeRZXT0IbXekKXWflmiRaB8LUH1MO9kTtm/QxlsqXRV90dExoJGNTlRiL3tEFro5zeiZ74qXFYXSAvofOAxueS/ZjIYmO6qHKuUUybo0/G/rN90wfG0tzzclhHv9dkUUgDqxj/DzXx37u9HxkaVFEDX9yQxVwQ1odq9oaIQvZslOMZZhaXoNkBlWjnT2+a99up60TOYbjy5tUNP5UJVzvtfyO/UPe6iZPQ=='],
    }

    @admin::user { 'bd808':
        realname => 'Bryan Davis',
        uid      => 652,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdtHX29Vcd5n950X3H11kAbQdmKTCJvOOclRKkaXGofp6UuCzgbbdK4Lfvz3cZ2dH9Kvv6M+Yf2uzh6XN470XxXIP91IzA7lVcaMV0sjOuhZKSvqe0NlA4kN/uytHGcfmBxlYAM+b1RxtveXTle3vVWefo1SkQ4fHteA8U/WWXhQ11HnCGd/ZAuiPTf4Fyfe5HFY6y4ECj7zTBEX6I6m2vDyJB7vsthfsmjWbll5Nr+wpcEp2ILVYdp+N+BUhHLkH4C6pivdxpAZQMSpACPPI7Bs+2Fmr08aVnaYKSFC6eZAFogf2lQ3l1oUVBhJRO4OX++E3TNEHNmJ6FeHD4acFv'],
    }

    @admin::user { 'brion': #RT 4798
        realname => 'Brion Vibber',
        uid      => 500,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1kc3MAAACBAM1lLHYwJW5sCLFGF70Kg8c7/Azrnlep68ufEZUPGrJkMfUHog0zLDlwVKTm5iRozUxwAidKS4wexcdmvbrz2SG35wsqjmEbd+jc8nJ2RLIz9y8EfzPLD8d0RyMsGYyQAm2mdyeLjMXsvSs8vq5DyBtvn87EUiAZoElmPTHsXQirAAAAFQDpigMj47QooCg5ql3YwfNLbHYP8wAAAIBWOJEimpUdjQF6FFEotuJc9G4FRHGC6Wpakx12KthAvywmWOCR+BHPlBVeufocCzkRxteCZeMddDi8EimXJJeN8CitsmYZCFFZYIkY2nntxWJLAKRI7LgsB/jjyw45HGO0piim5Phb0pqPjtJ04vaEc2k0xQq8a50IV5aolloM6gAAAIA7LQ8WRvWhj4gBgaCiHDc5TkqJksYd/lY1/hLY2prMSngkn/DLi0bepKmgBRQKFxqEBDl8kPFoVN7kb6qflwD+MBZumyIJmcw3mjgyNdnD/mlgGluAMBdrTKu3BtExyCqZsRvdlDYNFo/Dc4HZ6RuX4HM8MUHvrqmdyvLKHEk+QQ==',
                    'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEArC590xpWpe26evaQ424SBC3AnfHy7yb5M84F/3Wa/Pwb2Uh1ujHYmVHHnYee0ChWfsNXc3lHDlH278v//hMDagxR/O2sCjCjq9loyQQnb/t+f2INvrtna/YPRNO8nxH7dMT1mi4+i0LFlIkxwjwvNWoqJpZQouwckXzV44Ssx61IWR7S1s6Q9jthUa4O9U8Ffc75IQ4NgsGMcZoKS7lpqn7xQoVcQQ+RsfNLcmekUZ4tSdh3qp8R//Me6dg0h62VWucvjey6uLie/TW9y2TgT2XRxxLGZKWyp0YqVzZF2r2AZLvB0yxlb30+/qxTKzs9g51dUg+d8M7w8gAURggjwQ==',
                    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPe5ARdfajt7cDlcK6Fn3uFf5d5hvFdefqdr3L4Q2qeojQYioEvgcbZfVXRzpoSuPPx1cl/tDZCdfYityJiZWaE3T+gDZqYh/zO4M/JkiRp0vfnHKQeRbW7ledlitPKi9ZoEGE0e8FX17V9DNxnSolI3wBrEOOHxmBnnqS2Q04bM1/MRuMH/jxkcOWEp/SG5TOJtlSqKMAOrui7vU0gycQ9Kn6bwB0csuRA2IUwAnn07oVlCoBLR4nDTzj+iXF9j3aB2nyuZE0huXJM4ys3oL5CSDVTDow42vLyH4jwMlugxsgC2QBwUuCPLGz0uTVOvdFG5PstXBEWJnr6lL/0D13',
                    'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAmi7DfRt6vSuT7oQLE8kBjXN6tZvskked8ZHkAhwB80d6yuSa317XqMzYrxzU2SqDnprNqZZTdK0i2l7G+X8jLodTADrTvxX3oANQy9ConVkXFrd6+qfZxUs6y8rTMX/FPNxCCK/G7iQSg1GjMGzyIwdOwHPOaxx/ASJFKNbCbAhxaf/lRUdz/rirPm11KcS/h5qplA/G/Kbcgd7oopBBXnmmEPLEyVI0agIBNb8E4r7GNXikycJqPON2Wxp3id1Fs84ALacStTs49ZPtynUuRhprslhN3z6G6uliighcc0PzHMRSR/H8zjBREfqcfvAgdqSgn8DSqIv2bzWDjcNtOw=='],
    }

    @admin::user { 'bsitu':
        realname => 'Benny Situ',
        uid      => 595,
        ssh_keys  => ['ssh-dss AAAAB3NzaC1kc3MAAACBAPwC55vAiGT1i/GtaqbDjrDv7eBRL85Zzl08k1ywpxwaJrmgfWuZvm7yjfP77jnMFETlo3FNzVPXklX/W7XZOay4wGEmoJxGZ3Xuz4PLDf9MOCxPb7WbkfDaBn11H6llT+nIGER9cmR4GUElFC/omTs5OQXxm2f0pbk1USFYBkD/AAAAFQC+VpAVk5vUqjcjkur5OzNjkMPRAQAAAIBTx1epSxl9tg94Gu4UGeTrzzPOr8ga+CJX+KGi0AjPzpnhUhKuW4hJYhABwItltAvLAT8JL1+jq27++1XggLgAm9uX71zgrv3AUbxIMAMqnBNyub2mNidWzRWtjQ3S/HPeYjIViswGIudxxnA4rvZ/gJjfGdCAjjB1IW5rZuF0HgAAAIBiZffGKUU/TE04J0QjYuCrPQojyvHniicVFVUgRmZedL8b76lkTPgLwQr2hOH6+CqXF5/lvAtuF45+MLVPIKxCax7n6UzeOecIaFHBvfHWXb3ghIL+jf+csDp3rsrD12VxCyK/K5eNr/6xlQPlWoB41z465doAYqkY37K+2We23w=='],
    }

    @admin::user { 'cmcmahon':
        realname => 'Chris McMahon',
        uid      => 627,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxI9s+xp5hVPgYCFoiA7fVZWHp+tpsk8zO+iv0xpoeC1HKu5plsyQ+IrJyZQ3AlXU8TdAregeCZ160scrVJcCLwaU+3JC9dgRKOVnvrOMieK3HFsNBAXgOpLTRqXwXi37OQElEw/+WmnUW6BPtE5laQXwiNZ9HmdKUnuSB7k469gtX8Zp67/NyypOJR4gEoBC5OU9xD99lkKhJMW2o/eDIX//vzjtInQVgVBpfSSp4iNjeB9Z1gx5E28Xc8y7DRe8ShyRL/wQkagZ+cexmo33JkoJ6+vwV3Md9JkKYFkj0WCUrLBfXRAM7zagcnY7vJyW3xu81+HVQxcQAONUxAAKB'],
    }

    @admin::user { 'csteipp':
        realname => 'Chris Steipp',
        uid      => 609,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDsUn5XTWrJ8ojk6O7kF7kdQS1RrKtjkaMk2QtsdYOOCPo3YbK+70Q3Dy6gVBNOhsRWHeCimzfH2Uv/pVb0wNkrwenmBeD7nQyNICudewEANcnt5YF2znlke3lsW6TGzKUzrXIncdhDh4LWjmpJR/+hnKyGz7uQKXm8xWw9LGk1PEpeHpt+0TH/bUWzWjpYXfbt5W4GbYPwnHo1Pn27pcGwqgsgb8whX9ufDjw5qyLPTVW3AqP4XPRXYDB5Ui7udQeuCk4Omou9CirtC36o4ih2NrZ4CsacHyIMJf09HZo6yLE9EeGM06SO7qYqjYwapKGv6csZGney84udKaCHcdm/'],
    }

    @admin::user { 'ebernhardson': #RT 5717
        realname => 'Erik Bernhardson',
        uid      => 641,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDnafs6VPTCwrVEEqllEMpH6zhLreme1qGFuLxKD5uYQu2OJ01fhxICnswF7uuDrOSs5X9kTyj4zYjoGLHkEbucv3tBunEwYvzbrtRh+WxWkNjBNqhnUkM6T3IxOIpGlXwFxs6rD57i5ZtG2RPdRbOd+NYMjjkR/tELNSwuOfwi0vFeaumqhrbs5Q4XRqcdjPpMxE/BwqqAFA0SU/WeU5ewifF+FedAwYp5LRaeGmgWt0wuRnTjib8xxyyoH8ZJa79bYHK1CSWo4HU/EPsFdAgTWhrX59UQwOWTFOztQKU6zUc50bfh3cpv3wQ/4+VXFWG4J6XMdL4jLVxZwhCebYnf'],
    }

    @admin::user { 'gdubuc': #RT 6619
        realname => 'Gilles Dubuc',
        uid      => 659,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMDCMiDMjp3hY+P3DBJ1D2/IxS0xMHpS5MpKgxd1rU7aOHByncrRWL4tJ2isyi8/Q5H6XH81eWBat295U+3hqTq7YDuRiNoyPQPvwgT7guJPS3z8AbrlosUSIBc0B4YnrJXKeSTYEvHqQTGeozGDn1XaP2/xjeQR9wpKPpa0Mq7S3CMv8BEhvJLDVmwEP46AvGMeeZ2IgxlbH2GAAcZrGi8bvlq0eFcB0I/q51k/kITAMiBrTXo9sJ7FyXXvPnwmScfzIZFqO33lktMaYs5q2w7sad2Wtpz2tR+hMNm9Xoj0znPgKiZ1yFfGoKN7U62FDIJq23IrIRRUbinI/F220p'],
    }

    @admin::user { 'gjg':
        realname => 'Greg Grossmeier',
        uid      => 655,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDcwwxwZqCRMBQsMIutloeVS5Nx+nljUr914Yradb8YLeo2PbqLEjVKgC6+yKHe7binFNk3rlgiXhXOm2issytl7sWUZz8YpFqxp7fDqnfVVOTGTwMtAjBoZHugz9RaR1SVlz2dRk0N5qrovffz/Av3QQIS12jX3C/GCdqCMixgwi+ecYo2xA7WJyEGFnp+0Ah8hBIn2xabZAfHhZ8dF6VifEHsgp08Ot52sOZwb99+H0SjEWRwc9decwuPGNWX94BPvWcP6dQ2bzjqR3iRkwEIvKcgMvanYUXAvPb32382QCsW0r22HtvsUvA340ISlvcauRS1GGpyYmZYGSSfgHVH'],
    }

    @admin::user { 'halfak':
        realname => 'Aaron Halfaker',
        uid      => 564,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAuTdhPxqwEA5HR+HSH7LlPpKdducUsHg5YfIAd2pISraE5vNSYmvMGQHTLdq01JIxZHwCsKZ3UjdE5mL8/IANXR3Azk6v/Uoz9N5pBvH07/o5ZzDfTI+ZzaJw3ejv2C7lUXfbCPP7J+6BITV/q1UluFwmSOnwtSQ91s9/iXGLb6LrKkfXOBUz1P/hY+kF/Iw3zykBCpVkqIlqo3wBJo7i2qwL/zOxrRTuqzUyfCy+x87qSp5e7KUP26b/xVc/9km8FWO9twDGU6BotoyxHWZIXRaIrHgz96CCtDFFn3+TCGy5LlHn24+UtBFZXPfH0VsM+L7ZF8k+HMWxR57M7IBwtw==',
                    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqjDvky8+pqKrACjc1eZ3nLuAOa9pmwHBEk7EFqRVMSSy9IsaP7Q2RbblrcMFUJP0dCj+rDDu5Q4YKDYhN/x0Wr0vPdjQqrU2Ujx65EEeeYJQ4/InG1MgABoFOcm8TdCjkOFdvwD/JFzaNJ3YxMilv+xepqyGOTfTf+ThsXtGX6qGGWMZwfBmt7Z7oC/R/juaH49xHcFihzbh3DFdZLB2/VpyzIn55kvtqXFcw6SBppegu7bknnLMaXFi4edG/Jm1BjuFBnpHRVO1V91ou5tNNrMhTDGLGGyKgqmz/xYS70yPdy3nW8V3ygOdZWDmOCeWYMVGQE4pfSNA1vdsuV33r',
                    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDI6xBPpUqjfZl0AkSgS4sMLqaLdaVIUzZdCmNvzw+TbITw6PWOtMAOnP5A8HOn7aqnSH0ZYYWN/AzMz+9zT6+5JvxOfY43pCmT6qJv3e6mtCkkdy79kCH+b8S9NtrhttxMt9iem2RP1sbJiXLfcinOHuezd2Q05BoY97Aoo8z2/tRRvkPnHA2QU3fxAMS/PBle1ZytN2XJtz565AS7vzrts0su/jTej1ikLNZtMITZIrgB4o9KVcF5FHsmTIBehVwOEQRNYc6AwK+GWDQ1ZDS9m07/VmSIAO8krFPJ8y1M/EvMSP/VR78ABXOYTNlgzTCSuLFjocFMARBOnpA5Nfg5',
                    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUTJ/rlBnGfXU0Ybp1gjJNizb66gaRFPzq33ptdnCLSP8hWymFgpzmuNyUaBClWJwl9qxXIw0xZjHXyTcK7Dv8ajqatgeiY0ow1LoVfzFDtN3Y0dxFNKC5/bC6lk+VmBl7fmNk8+fx5Y2FF8LMPy+QceZU2CJOvJzEkjd1lJJTFnSSonRrMBzK2xhT1qG2PhlThWWhVklrEvO+wIdi9M2B+m4cjgzaLaK/UgeqhFWsTQd655tLb2trhNHj3I6Nn38l/b+TFKsYT1+x1QWt9IxrSgKcDc2oAj+HSrcHIaKIXLbMMDaFIzRpHGMxnSXpJvCDvSq9aKyfw9dsoqxuFLF9',
                    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjS8cth/18dmTr37h0A+K1g82iVqfrQ5c98iLrtl/ejvkMNDvVSo1Kyho6sXhwCx7HsF5hF6Y+fVB5FaxugI6o3CeAt8PQBeOjOWOdCZCUudywwnNWQgLH1XejaAxV95VRZTeuzhTLMymZRojOm2Kbb2f89C3CDCPohlOqVKMRsa7vMA6mgHgJtOXjqdrn+Toj/oe3+ZLvTpFsD8ROTsppKo+ie8AvRRzaCobgHF31OrihlAxQlovAPH/3eH67NRlmwwJhkuGAIra7+ZCfJzNR/9RVoc6mZgRANDXASTsBuI7ZdUQjgRIHbdd+VkXlzR+jLQy940ukLT1IK5hH9IZd']
    }

    @admin::user { 'kaldari':
        realname => 'Ryan Kaldari',
        uid      => 573,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAnmxqe0czLnD+blnxcDNRsOF2MDhydEMtUqWwHytxJeU84YmUDRuqxsEhKCNRSxiZvSf8RrPfiO+OiF/nF7ECdFTvtihDEfV89J7oemACClmrjOD+r41CNYCFhpI+fZIUzNuenf2h5cMx2Oqg57i+uV5PPSNX0U2VOU4HUgKl4ymjRW2QGpvtNmtQflwhXPD/9ih7VqlcO1DEbEPj5+jN1LvY86roaW8JDz9dvV+zmoe6yNcHn68W5bG13qOkfW5BCnVxuofIwN0REvINFAOliHF7gErXjgBqJiDr8O1xopc67+9bHLaqBKa7ji3aJSmrOcVvRlr2o73M1hC+NoJ2MQ=='],
    }

    @admin::user { 'kartik':
        realname => 'Kartik Mistry',
        uid      => 3033,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwavUwjlUmLv0CJGAvtUfjuLkuukC1tNUi0BmMzOnmbtqJ1oY/RJ40HySJuV3RxFNCvFuMztqatX6icE82G+nBNUa5dzPKThWjsq9+rEyaT2KeEkJTXxBqzrWikV6GaIDCOYMVcw+0DMVfdhd/OxgcetYDgMADKolkcJ1YjPRI/HLKBtWDOS3X/tkl4xjYTKuARGH3lBTrmDZQm3XXKmlvnL5GXAcFu9C+rWhAGYefrIgWCGcQeNZa20A9dcIYRzERJ93szFdeEpJqGvQ2niCOmJfa4eyuc9jAvY9Xjp9XMXkCzRBfmhq9h1qRS4EpfRlm5cDs/RL+VRD2lVMLApE9Q=='],
    }

    @admin::user { 'khorn':
        realname => 'Katie Horn',
        uid      => 572,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCo0sPfXSU/XsJzevSa8p9rODZabOwVbv2zx0htASdEB++TaMk5k7s3rTznNjTzD8mgia9h9+Dl/9lUBnLeiWeEPDLYO+KiITs4pZ+akL/4ilWl+CJ+59C8Wm0apsezQwaMEuPGzdx+3MVrqwhRdl7Fg9DOMYIz1n5O2Jrr2QnD9TamWFw+yYhmZBkl/Ci9rbU/T72A1cL+D2UVFk08B+FH1d48XDMoaUppLbV29/fc0Fz4f0gZkLYBKmOo+xpZ8SXkVieP443a0uGyfy2FSljnqF42dP21XO2tqaAtf9q2i2sq8fnB072C7oIYleVKLfLvxk6C7mYvzTN8A3m4RCLJ'],
    }

    @admin::user { 'manybubbles': #RT5691
        realname => 'Nik Everett',
        uid      => 644,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvG6VYTnUwHQyLYFUv0g1EUfp+OByn2agzc6Y3oSj9JhjYT2zbzpfquCB5aL8mLv4A1J8iKVwWHGeib44QY8uggX/66xdRrvEZ6QaM3GkVehDS4MpKl8m61rnVfITSxmPg0n83pBDhKfXPzE6vzchBA7ZhonccObwpcr4jvpUrvFcgWDrhjbC+YeJ1YKz5lm6IPW0yeY6Ni/0LRNbIUkv0Bj1epsFqBPORO9GoWc9ydV3rDLJJGJJ5YhOlbFSjc6nblUDMwBToxov+5icnT22wNdlHizGPUafluw6Wf790Bls3Znoje0qY5KgC7zOoQWWR+3k1kZVpuOIVQU6U3/uP'],
    }

    @admin::user { 'maxsem':
        realname => 'Max Semenik',
        uid      => 597,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEApYlzRyFB5UNUnmCbN6sKPe53ZRd+P3NW64KmCj8MdcTsdBsOxhd00DBL7h1r3VUCYfkqnJuBgBfbqF0xFyv/Wx2fEUtZvneQEZUGIPciSkEwkh12VvNYeuTxWqW05B3eZYSnYzKwcziecf6/uFwRfMv4E5eTT91U22YYUzsgzVLVCDqtZWAESHqcZgfq5zxKoeO+PHIBUYYXNLz64Cs9UJNki8sbDX3sJMnRCebztEUjckUssN9K63KNXaQcXJ2GQJmqMG522+VkGMzbUV5yT4tjY8SCPNsPa3ij8af52HJNAz8IMfOvLak9ILxeDDugZJmSdBTEK2R6uCV2fo+vCw=='],
    }

    @admin::user { 'mflaschen':
        realname => 'Matthew Flaschen',
        uid      => 625,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCermpz3BWUs5f0Cw4kD5+ngYPoE2/L+5Semq+6/LTboD2+mmXVF6vF0ODSt/Q9VVipzuiYVF0C+MQxMeSZDLKe/scBE3eIftLEQouHSiYq/YS19+ym4Q11rio3gmdqF4yS8Go4cg09FeSXmWy2F1H1apnWqZ9ISfZkeO/ScWQgcW9mY5GzbgZDEK+suXq8CjA3xU6HpPKcnWfRc+nG0ryLkO932Lh4L5Foev0buVEIIbVHcBZijsH2phdYkxAAytP4arRDdMxhpIHfaHdDYTu9OfJq8v+pAFigEj2jAnxCO2gtZRloEanzbTfgUgIhg9/vXcokaaDKtYZ3ezoMu5kJ'],
    }

    @admin::user { 'milimetric':
        realname => 'Dan Andreescu',
        uid      => 640,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAOgZWjHAoVJF6hJCrDUjVuiZiNeW1GudEfkFJS4ORo+WpVaMjwrILGThrriIYZNEIQNEf4l+7ht2l7/9g7e0j56NxXX3NJftJWRKOk1d7s57CKZAdvcbQ4G+L/Tyed+qZj9JurHdMstcVo50nd6S/UvbvDAdieXHemhZLtFcqPBQj66XDJkGzm0U9eW49lB1qCzcQnsNQbxRbV39RsSgIU9YHeGWMsglI227nZX6Lvd6/Vvz2VsFR5xtdPBHQ170XqbRylZQaBaR1lmRz9Aa7dSKSbNgGYAUNkzijILhBccJK1Iulmh/yDFPm6ZVWFaezinbCspXnvCIdJfG9EoLx',
                    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5BDWG/6bvsz87yKBkFf1ryKSbF2/CNzxTJn1Ux135/ALq6xcr5/+zS4KA6g7D/P80hfvTq9+oaPVVLVX+ANGomCv/kqvyClDvEnU8r4TEAPkZBrOWHAaexn/6oJkY7xoWbm+ElTPTDJfedWFYPKJx82dWt5CBtij5jpZ5CE2/Lt+i4gTH1G8n3Mo9gCnA8AlhMDTr18XssfqAS0aylmCwd24TJQJE3d/2NYdoytKfTebg87lJ0hbFJcxHVsS1/ivT5+in2wSfLXOIQiJPI/ykagoD9z2FSVOiMcdnrL44Xb373QaS7bEAxpjBJrCUQzeJfEvS4nbPpOpJfSN1+7Kp'],
    }

    @admin::user { 'mlitn':
        realname => 'Matthias Mullie',
        uid      => 596,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEq/VIh0GiXv6PIUq45Lbk9jgOmkH9FRN53VGMJmaxyJV8fRpUpdB1rmdqqe9gs5heSyObP9Ci5fEL+8PbXsEygK7g+ZhoRP+XDJDMe1yjMOMgjNaN4pM5FJnqkFgXFPmhOvRizrT3SWenUDlGBhxufekTUVsl/zOF0R2g5jTWbFWPoa4P0c2aXeJgJH3s65Zd+NoWolVrPG8Q1LT2l7xwJdRaS3t4Mt8iusPx1e+Fvdvd5LuO56/zDPQl37ocMeax0lVMbKPbKymhezxotD29sez3sljrHiB8W4Q/oNC9d5jEyCegMYV5Wh+eUkqMIAZ21knjGmWrkB5xGRhsrOVl'],
    }

    @admin::user { 'mwalker':
        realname => 'Matt Walker',
        uid      => 605,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDs1a/cRZMNw1DerltODiEFOWoCM1YJpPcdYDFnEIEvl9dz3X68nBnfHMfAWbQcOxD3f8tCTjrQ4i4M079kawGkm+jEc7priWm5Ww6TFeyA7B2jTuPqRHWfJ6AsPvXnrvJF/RMuG6NwdOluunipbb0sbHpPreBMYwu6KifvEnQNLYDp6Y0c31PYC22Nr7jZTcCkr7P72t0yhxpuDUV4p7vhEsTKAI59wHSdM17ViJRU4DwDIs43ZBKulCwjuiwJ47oc903c4iVeA37D2jV6nrNbao4huJRyrApfpTYm6RwCnKkOOCBNSB4MndZikSpYXGjNgUHWJxj7vquumje4AsGb'],
    }

    @admin::user { 'neilk':
        realname => 'Neil Kandalgaonkar',
        uid      => 560,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAyVfwM6IreX+fjXaGwuYMgva6acyUdOB9JDrDcIJLIvzD1Ii5ChWDsM5I0bj6/H9hfSZAXEB4o8w2hVQR1zRDbEPR14eg3FbpR/mP9oU8rdchGMZbn/vgVFKVcjYcNb3ADlRiMRv3Jrmov6ZESV9Y09S6vGwssg3dabfT07tBdjohOHfg4HwHTTwhj5O72OMxOk1zf1kMsOKJ2l3bT0O8NavAn4by/w1gcXek445NrGJBMrdMLh1+WCPWsxaGI3J/um0eNXjxLLbz7tngRBP17JepU8EpQfgVRFy1GsOIxYs13TS6pvWZYfuLhugr0MTmHcyrycrOXZOGBHDFG9pg7w=='],
    }

    @admin::user { 'nikerabbit':
        realname => 'Niklas Laxström',
        uid      => 583,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAz5I9ctvMwZwehidz3oen7Teoj3pWi6M7+q0PnjXCWy6JuqkIv5vFtmi8NvCDSTCEaAdNdr7WPQHpGTSqUkbWsz0sswPlODZLDM97x9fzC8z4YhckJt9nlhGCYYqUi9hbchxTOGX2LL18/9IeU7yA5nb8qd3PPzhzjzgJkSjTgMnU5Ni+OBY3WiNJ4FFwYyitokYPVIF9ZFKkUWwuM0bSiNUjbNIUb4834i/tJ3g2plxX+9+7d5b6wFSWu7+e8wgN4avaTC46B3zKcYmfDUA2ebiZuhwUU2NdsP/z0Q3rOZ3LxRmVkOJFbK9vgmkQtTzSkhG3ZEgUiHc2QCjgccjkv+KFayn26WujtbmZZoIELC7/46lgwWGEZtb0QUbo2rY8yHaeetoVuVzZGtCrr0tEBx0w2AH9BfOYsQOnM7eOVzM/VSdW+3sTrQMCvfpd8HZsWT7d2dSyM4hsvRaETwxxoXQEiZZfik0oH/EJSH/AogfvXu4MTUiCekNtPRazJPa9nI5M8CVtMiSUb3mY7OJ1OLfn4nWBvVTxp2sP3nTSwLEYpop2lMUwEwy/O4POXUuKDZQOEqKb5yRxuW7bOSGSDKZKHaZn5X25BwVOT/oNX/vqSRGxf8OWGVj6Ic2RNuGnYWDmEf1Rp4BVn8xATzOO8/o3yDnElw3M2gBkQ3hDWFM='],
    }

    @admin::user { 'pdhanda':
        realname => 'Priyanka Dhanda',
        uid      => 547,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA3HbBUW7PKFdkYaPkzvPJlXywNtiu2+9w0nZyfqnC2cM1oEh8E1R8q5gWiUnaeNr65XYceMl/bja+g2g9QZkBAHtQArOZ+DePoejPUyfR1UUczARRywTFVTCS6vSZ5gAnujPuEcrOU5UTVgB+jicX7tqMh3AyJ9HBSDa0FCgK6PP68w4zDgIIFp5wRVBhzfPUNXHUkRBMuUaN7oGtq7VYaDITGLvyIFDIQ5FHLXiuy4OAAPvnf9/4pC30d0C1BVMPJEEIrj+KzlNSdUfy9WOxeNYn6vfsc0CR+soie0um5juwfyQWiDVmw2/lJcB47GoEqZ9dp3zXc91tsVEom7TADQ=='],
    }

    @admin::user { 'raindrift':
        realname => 'Ian Baker',
        uid      => 593,
        ssh_keys  => ['ssh-dss AAAAB3NzaC1kc3MAAACBAM3ttq0+aY9x/2rcqLwIVWo95Iy/4JD7c+GSsqtTlISCtkIkkv7HNzYUiwQqKBVn9DDTO7abdtqeyBmX5e0I938F2c/4mUUYYl/+q8dIiVUKgFIZ5v5T97TQHgUbNQ1N8E8G5Aw3308BCjD1NHzRSFD1VpekpvPMA3DHGrMlwZcRAAAAFQC0LNBLhS9UzgnCkZpw08m5Wm3OVQAAAIA0+93B5D6ShSg33pmTjKbheso7pm8dI5v99crl26QTR0H220tT8ytnJ8n0/xz23nCtelAGO3adI7+3nZS8iKq2d8QpwSqJZa2je47rJuZbxOAL6E+/65GHzXAPEhrhiWmj8mlE22nRRqX4EIspctUi3rNdtrIjMWkyKcF9C9/qaQAAAIB07g9z4M9/cJmFsOoXpvVTEd1XUFN66Eruqz5cMYg2Fpqi7MjkE6mB7IqVVcuxk+m62QpNWNHPPzGJRZg0TsYHIf5X/brv2QejfxFmPFppYfOfdv3d0NMBFEUiX8K/Fakxyfz8jerzLEIM95zQZExKoaJ6ZWMaxo62+YgmrwZXDg=='],
    }

    @admin::user { 'pgehres':
        realname => 'Peter Gehres',
        uid      => 581,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8+5CuJlnFqzlYcs8QRu42ur5Y+9yM5g+uQIDYX+3SRA1UzOOOmj/Tqv0pzGhmvK15/y+Vz5LwE927fcI9VwAxBpCgfcV97r68aDF3YD4Zqo8ksV51GhRwk2QPNlwvCtf7+BMCLFt+ymLpAIsq3L1YReovJgfkDHvOQrujXH7LGd6tEXaUksqyn9L7TTbFEyHUZxTkrV33OOlaSxIJM1EZu1fsVSL0LppmXaLH1bi4/gPSbw3A4l8EAttWAqkvK0zrty022wn/1JRa868/OD3WWCoDNp4SSH0DisURdPlT4Jc+q+P6+P/RqeWJAx5IqEQhVg2GxW6BMIKQP5VigS5j'],
    }

    @admin::user { 'rmoen':
        realname => 'Rob Moen',
        uid      => 614,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDG/0pPRUoAhvHvgodmPYnqh6JZH3+QFlECg1rCbetr2sVx/0cpEPkqciEC3UlYm8iIRHLr1AyxXS2fq9ruB1oNnzzCzSHitzCP1XkjqqofkKVWSAUhnjhZyJ6VN61XDj7PvMJW1dPY6ueqKfjFR5/1icbG1yIqeUeJ89frPsOQiXxUAnebOojRK5dNkhVuX41jJfUBI5y0CaxxE2EqEQn+LlI6ZYDpORj5q8vP6YyvrDYS/708pJltUN+4rM/BKTSbJ2TTqc89klkY9AcLgGW/i6QMw+Qaxc22cx9TmpAAhUmvh8GX+yX1jylh6Nt4mky8L2cf6wW4ShAuDKLZoRFF'],
    }

    @admin::user { 'reedy':
        realname => 'Sam Reed',
        uid      => 558,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA3k6XjeMEmIHonzsmRBbHCkeVhxS6oObibs3PPP4DAO3WYXPIGBye+OpPtCpSZUuVp4t/GwnqIHCM0MrlVoFKeFcC3tHtVwmxhIsTp/RQRPjjKNdH60Iz6RlDTZ3TJDaYkYOiW7spdCONLzkYpOgkiph973aMNQ3D0vS87jht1apUl06bkxYeC+Bziq4DSBVNqpGKa+NqSYOvtS1kapwCYTtRm6YASb0YeMXzTUyfClgvq86h9XLsbx7klWgjHfKbfi/yheAm5EY6jxicnYaVAmy2gq2ERO9e2dVbpJihHmhPTpdRba5Eln0CoPkWrLVX0jyiAVB4biRtYoTtxGDPww=='],
    }

    @admin::user { 'robla':
        realname => 'Rob Lanphier',
        uid      => 556,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAu53QXIYXig1FTP4ve0MOMSXZXtMORld4y+f9cqmKA7OAStnT1VYw6F0eBSPJH0WUo541iMKcsigENytdn/kuSu8zmh1+nyHvhndB3LvP467IBo82LRBaZ6X0+0y5X+w1w56oX5H+t2zixWPHTQu0f9XQBPCsZzfV8DkVbJjwoHk9wcHI/lJSa7r5dI0xWPWYXXHM6BeAHbET1kcUAe3km1jWDsh2gBgKfwis7iIZx6ROSBOfHdYs9MU6miFq/9kk2/Z1vKOY6bj3adVe+wbd6JFF0UZdQzstIW3/15NfWJjJ8X6gx5U7wchtuPjnIyydUTU5u4UiS6uUS4e+MFsoOw=='],
    }

    @admin::user { 'spage':
        realname => 'S Page',
        uid      => 608,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQColhx7+65SMkm4j4iPu2WmHoeO3TpC5Iabvr5neBmqQbSQB0PE7AImy1p3+Sd5e8Seqdi0QIPyu2Jw3NqlOibn81snUExcRBaV8cKvN+c6oBJWVL/OILopKNS1MZynNPVOSjVzmpLNID5U3slEpopyS3aNMhI0BD93QAq0xE3/5kaFf19mkOEjJbaUcEevWTwI95NQKVovJ3y1R5v8e+GaFk86F+EJ4i99GZ+TzmN3VFMy5HfnjMOVGcR+WYyZ87Oa2CTdF1lbV6W9EwZD3eTbuDPZH1VW215Spw8MpFPQznJSkDLhwrg6GH14XuDOA9edf+npYsnYgnWUWF/k1syDlZgQvK3xp9or9Ld4fumAw7a2lQijbrP1SBn14H6tSBK4XGN5ciKPbfj9c9z3C0WVjXZsaQn1hmF1kWu4Kdnx7uYh3RlFnImpvGSRESHN/xuqhdF6o8/KiF7ByDion6ac5VKX40PplUFindsDiJ5GPnsbQWZ+0FbRcMCjE37t5P5NRR/Vfhr0X6fJHqlw1DXGciURVsCXF1E645ZqGZ2jC3PjgxgEVnGgSoaYWoWcX3vpwBIz5syglOgq7k1VDA3F0zitcIkem5uRFlwWgDo/y9DdIW4HNb9cVgMN2dZYQRlNnvKudLni3mjk+R8nie5C13lNHfgz7HMFwufrcxaMkQ=='],
    }

    @admin::user { 'yurik':
        realname => 'Yuri Astrakhan',
        uid      => 636,
        ssh_keys  => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEA4nAjWgQOlzel8gYe/Hsl3DpT7KF7ygNVl7mZBG7285YUakrr2Hj8fSn0YfYX8b4u+FTywah7adefxTCuG6x9PkEzKAYSnaWXRxz3C2bZclkxXaKcVR+IJUG/9WyqwLxVj/UeATsuydSEljcwoMkTkV0m1p5hFNShTwslOiKA6VIwVQPufMjFaduUMXl3H1MzA0ymO/xzkMsOmsqXLgOIE6GOE1r3kzQHSD7tvb0o9dwtApUEhRiwGPnWxlDaGpWhzNQ9hHXGZG2XvfDvhVZ6HNJ/wR+x0WI1xX6b27fPbDPYkQDxOrts6G3F4WjDqmPLMYJGcsBXwueh99X2LaaDX6rWU1vq37Hj8Q8ROEdsL/RX30t8WdOj7YRGBEMbZliaGJNhTyOK2nFOBLKRcLSYVXtCvjFa9iTSqG8ZHdwho+vYRcs26hxMa1bWdS+Sg/YUJlfCxZk+zi5xryF/pog0IJdyqgNDqPau0w6DZKphlo8/eXcLJB6KkuaJ2xE52iqLokGGHu+EyYyOSrBSCOLsvbHvOwe9ESqDiJs1TAxjXqoOzNfWZKrfeoZb0AqycDwwbvM3oQB4/N590Jsb6frozsDCo+y08AYfjhM+lIFY2SdZHOmEzmNTDwJYf2MQOc7Mi/5wl+tMMnkXU0OPz9Y5ItDyfTwIsyESumVa3FYSE2s='],
    }

    @admin::user { 'mhoover':
        realname => 'Mike Hoover',
        uid      => 656,
        ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHHt80fZmlmhzmFRgT+m0oIOs4h9ZDpqP9a4G79TZfZOA3eCuiq+kucyhdm51ge7GimzE/rhFgw3ZBVXvcdKpwTDyybArM5mOJsyg0GNp0Ns3hlJrvAudIXnxEjGlMuVF0ek3Vexi/hBzci5chqXSXxQJfUnfZnBOMiFyAGGM7KQM2W11SwTxyB9j+2McWm1ZR2rC3DjTsfbsus4BMlNYgaR7hE3ovMiCdke3NorFJ+NjZe2NjoMmSUNnGyTJvwwUncDXLELE4S2QQ4L6Vc71mMAC9VC/+qrpjTN6CEfae8nEcBvrgA1s/ahMI+3OdsWzRU0Gv3+jgqUR/641gXdkB'],
    }

    @admin::user { 'anomie':
        realname => 'Brad Jorsch',
        uid      => 617,
        ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDN9+TME+RHccrQypKmHUXdRdlr1TVQkhCEL6DJ4dMA2CaWIsqwIkfqIjzBzVoqLUxNVjVPh+AF8ahrtSnx5qQKrPn3icv1G1J1J9d4pagHuFcNQiYWS+7xk5P/rz8GETOcNkKOl4ZaCJf1KGvSiFv67mC8ERqY3238UIougv74uTm8u6KHfJQoNMMgtQ0YlGD5pD5HjKMMkzSG2Li6a9gR7nXQ4WKHDKyZW1lt8v4U4v79ZcTTIDk8jie6DNOgJLq6NHpurosfMjZI7d7wWi84mqQTazTpgNvRtaAyO3dg+iZYGrc0d642e+kBA6izMlz8QpWOiem5tR1PGN2itTrL'],
    }

    @admin::user { 'tfinc': #RT 5485
        realname => 'Tomasz Finc',
        uid      => 2006,
        ssh_keys  => ['ssh-dss AAAAB3NzaC1kc3MAAACBAME+XGr43e1N0iWu7qmC2Do/mGBoWEGrSObLXk6Fll9+WJ9nRNHvmQAkEUexWEQaolI+ItWFEAVU/j9pO10MvF4YcGQSGcUEbsQD50W91P3+T/ojnP6bhjI2/aX4HAg6bk0Sq2ckYNpu4owJdhDnTHNk3luptOSwVLnJ92Nm9S7JAAAAFQD7L3zwmi9owkB+HhHxzqgwWAB7LQAAAIAOTsZLkm8nfbqMF0QRWKCb4NU7spftTiFLgVNiq1nQcSA69krEzZPi17vOfJ1a1iMWJL1zKHZhIxbXimDxMAwKS45WU2RxfMbtZw70dAK4AW635yb5riIyuc94NwmhquRypPcGUQKN+/mhxB+NDs8AG32iQjVD5e7M+fczfLsRfAAAAIBoRL51kK9c36OMcrzOJVR8J9b6bkV/AclSQmlNzm2b3armXf9w2OlifqobOpoJL2PG8HWKd7QAqv7PvON20HErNDBMCYhfRmX/Bn4WcWgZzq5y5I66rGs86nqyycbWAFbz/Yd+zq6P1z/LpzXnGsy8j8CAJGQ8c2tXvNGhHToHtA==',
                    'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxk8Zks1Z1qsFhu7CmcYC8474ikLmDVXXLqeC2ekBznIsdX2/1IPaYIZp8w4G8M2X1InMOqQswCqTfvQFuMOFWxJvTQXxZOJUC8L2El1xB7t4O7mvDXw8uq1h20L7ODsLkFga3M7W7IIg3pU12HS1UAInYDQt0SCXtLaTbPQpgP8H0XNZhn/I3P/NVQnaUx00YzrS9ZojNbwEHB8cUpwp2N/gfv/byTTe48Xaq3wlAxw/QTow5G+r3atEOVJ0QKGztl+uScF/ZzP8QYficdMP7aNffg9aQhf/uER10hXu2F16UZQyoMx/sFkS2U8ZNVkCKLhI7MKti7+ZGz4/+fcCOw==',
                    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOXgblcBarO8An5LNYfIBOjl+//EK6XhJu3agV8nQvmuaT2qnPtIiLl3W/X34bKHcRJbWsJRe7C3MqJqFWF6BWWtU9MZWj/s1TRtyA8Olgx4y7cXGXSUY/0woJnM6yIh6WitQEPX35iZyKaVapX5FCYlkkSbTEAbJwm/bFV5j2hOTyews7Cff1E0Zp0+E4hli39MvflkMOtllcZvFoLjve5AjETeabZEppvvSR8VPAK5bNMl7zo7fWcoExaNNlglLLRxP8y8Ne2PQlks5gTMrsh5e55BGVr/Nd6kD5OIB7s63InMbudYViWX66MjPgKMXXg8m7RKqkLB33nBifQrY5'],
    }
}
