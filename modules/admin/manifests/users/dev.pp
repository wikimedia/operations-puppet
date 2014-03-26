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

    @admin::user { 'reedy':
        realname => 'Sam Reed',
        uid      => 558,
        ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA3k6XjeMEmIHonzsmRBbHCkeVhxS6oObibs3PPP4DAO3WYXPIGBye+OpPtCpSZUuVp4t/GwnqIHCM0MrlVoFKeFcC3tHtVwmxhIsTp/RQRPjjKNdH60Iz6RlDTZ3TJDaYkYOiW7spdCONLzkYpOgkiph973aMNQ3D0vS87jht1apUl06bkxYeC+Bziq4DSBVNqpGKa+NqSYOvtS1kapwCYTtRm6YASb0YeMXzTUyfClgvq86h9XLsbx7klWgjHfKbfi/yheAm5EY6jxicnYaVAmy2gq2ERO9e2dVbpJihHmhPTpdRba5Eln0CoPkWrLVX0jyiAVB4biRtYoTtxGDPww=='],
    }

}
