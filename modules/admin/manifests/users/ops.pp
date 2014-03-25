class admin::users::ops {

    @admin::user { 'rush':
            realname   => 'Chase Pettet',
            uid        => 4610,
            ssh_keys => ['ssh-rsa  AAAAB3NzaC1yc2EAAAADAQABAAABAQC+IUUkFX0t/8UqTZJFRJ6JaDPvwIOTsGu2mIg7OGA0lDhJH8eRz2dCPSM7Z4IwKPh92mtct3+aZy8ziT6bb88TNESU9n92m4HdHogOLMz/ksJW07oY2fTjXs9DeaPZUP5Sf8uSrU0ip40wPn8fDuXIjEX2MhUgzafNk2nm0+VFqdU+p4vMf8PvTjtjDMqhq0r9mml0YH4T4kknibwAWlcJaM7O29FlRWoRsI2nIzde5fYASdvrstPN620EScBQo3vAlfbkQCvxvWpr/xO1DfkFDUcIOmrC5uWbOKrGCZRLfnOQTBaMCjHcKmEPJ5YzII692G3BTvbIZ+6AqnLSoA81'],
    }

    @admin::user { 'akosiaris':
            realname => 'Akosiaris',
            uid      => 642,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5IbCL8F2mKMLVL2yp3RP+1rs5v6R4iveIctHQA6kccymfoUa5y9FLT9+hx9ljXZDjrUN3rPeagbZDrGQj6UlI32YZVKRwAeaLkp85HpbzaL/2GKM9UlSq6Qztnuxp/cQGQtDrSK9rwPHk1kqxhXQDeu0+mzqgKMsTqZshG2pH+T27rpZMcUyyF0nX14yoqPHdxvetYfjhAo0WIuwmMcyDcv/Au4AaDgOoKqbYVNY/I5gRYxEotRuJeNg9NLFlUDmntA5mXthotK4uWimfDV8rI1695n2Idvf/iNtZiO6tnIFfs7nrv3C0vFZO+MMbrU0cz/Abbhq4zaQH7zqrP0GfaR4AJu+0SgOjDbmAhOgwgYOxpdhChIABjVJTP3chKgJ1y1JeUxyUaIayddp/Kyye7z0kFJw0+D8YROAPWkkJvpV6c0/U88LMjupG2kcVlxqPrUCJiL4e8viyZQxxJOJhS/Zdf56AO8Xh8WAxX0RZGLbA2GYln1euu+8zZuvfYuZa+IRPihlY9b1fkyYP4Y7WtVNkvtFuwqKzwI2qyRGPH9W6PI0yva1BYNf/jg2qdFiboH44cBzc0MoFoqjzD7RHJpPQJQFeEiZsrQjDvm18MMCONJTPHYJaA5YwxClRXH8scWx+H0MjDwC9KmhMPm+Rb0iXPh7KePhP1jAxN+Ldew=='],
    }

    @admin::user { 'andrewb':
            realname => '',
            uid      => 590,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAvx17BMqWpcnI5aAl3tVAJ3WI8+geWfF0jTh+/U+kr8ls91tBk94sEJ7xI1T73JepuRlqsNRzzpZxxn0kipVnj7jxW3nbqIGmpXAfb/2W9Fnp65P2u+CKWd5tMwYU7Q/z9zEk4FLoLEVK7Ce1ia0xkbG7oeM7La7sATNl4mx3BZNPUiDCQvEOrePYFUdxP+wS4wsJbZ38RGil01lPFeLuF/3aG+j3xgttwO+WjJYGEAyddUSuK9aw6rBpLOFaMBZqU2U2hK2iIDN6EfiSOpdk7zeNNKOqHfcH5N/rRGBx1niHV3K71WsiAhYApZ8MBiK7iU56+/lahsarstDJ3GKZAQ=="'],
    }

    @admin::user { 'ariel':
            realname => '',
            uid      => 1001,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwaTYlLZ90/oQ5tDYDkhI2mHa1L6Vh+zcekCt8D08N7/CrFI5sUVteTwMWw2ytQlWnyT3HVgHb4IS1EPjpjyuqseRcNW0HYsqBk3E36PCBQIqjLZ0nDAeHQtm6T6pXiKC5qUppghwrvDxVYFpF3lFzAzfYMrF7iugk0xRPTHZWm8df7dqIB/6FfbxSD95yQVAlJefxoFWbo3Yn+exEZQvWv6lQYXnjV5DSwMf8tPGDkc2DRjrnR52ZrXPRZFCqc9JGkA/l8QsYtjmqJdnOgq5raOb56aRulJYdP2j//B4lRJJlglMuj8dSZE/j04zub+P2QhfdqeEHmeaTUqbwcnZZw==',
                         'ssh-rsa AAAAB3NzaC1kc3MAAAEBALcKsz9HL20xCAB/hWLUxE/26tdeZBQqLWlNiWUC1ilKlqYtHL99ffkrJIlwst+IN/1SOfBhs+5pZxfUyfIT/DaeVNVQXTBfyAXM8iImtY/RsQ9M+v0xhwTLVGs6jTXQX8bkOYAEIZd+x5eGFhSTyIVZmxkz38XpLsTuNyUjs2gFUWZtPGZIgOTToxnYK9mpvpM1gRsHuhLMYg9ZpgFpul41Im+znRcWnrmW6uPAYebvO4V3uNwqdPBh50mrrqyakRj7QlCiFs88zufyj3BmC5mwTNlHClAbVyLyOBY6GCgfof5wFkbvAnYA0iglGZBnk5qIIuPdO+6vxRztUIY3gI8AAAAVAODnUYfx53vWxQVx1GHkzuwSP5JJAAABAEUZuasCiK2tMhQyDIJuad0F8H3aW1CrVtG3ZJuZXjLxpsXQsaOrG/DcFLxKxV4YheQSAVYc098IoQmAiTBc4W++b5lqgu1lmEMwMxQd+o+V8/1ywla61DA7feAAc1H5+eiKUWJDGs9J4HnUiAJc//B//rflE32po1S4Al+8q5GnngOqGEc66u203V/CCtkEbFCOqBXcj36nlTEtxbkbHe633z/TMM/bAwH3vNDo/9Ia/SdTTnQ3XaOD+y2PYF2ley6ImedGrGM71RU2zUv8tmQW8s7/5SygoAWGkljjk3IZy+nYRH232fcWumwORmGvpiq9pPPHhC6zYXjF/5thXRcAAAEAC4uOPvwmzpdwWjJ0QzbcPknWtdc9pvjWC2OWGoJP3VxQckZnWwBEIi9TjxeneX1xU1ZZKQ7s5xcIBWE1qn8P8gNgpqGLVK7rmErN9EYHGcxPR/n0SfujHVo7qEHB0tRhCtABFEpYczl/K/xIfZ7+bCQmvWKuyYETP5QTwbAD5efJh88/kfFKqtI1qhhAenfG3afATU0SHya31HYjrghXZBbA8YvAmX2DfBkP+WYllFaeUmUlvMpnW6wx2+SW0cbMik8CFJIjcMO3NAWppsR3mgSwSGvWorlH6Tskei7MaEUBaYJH01aZbkJOkigGVQhna3tQ2JeKhe37GjednwoBGQ=='],
    }

    @admin::user { 'bblack':
            realname => 'Brandon Black',
            uid      => 635,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxNcPFGwSUYB24njYY0BX/vHm2AFXZSQtPcPGyJxP+fkkaTQOKX4pGST2oCudlV4hBnskTTDyd4r4YF1+HPAzxX7myCcCFh+9L8AOuVcdcH3g9dSiV3csAemlOsfPivrJEx2RG5sFiYqaLSfSMF65QjJUaX7thWIHRFH+sDoPfVBEJABbvO3yeA9uPBzqWPs+kII7n3WMEsiZPvbPRypsfFwa0yoZotnoOC0ZoiQOFZCm3v+Xnoxv5gRxGIZCrR86dstKoISJU0PmPaVZkYElAhtbLUxlBCsE/lSQi/phQduuI9u+pApaW+4FxpUOPD+i6NfdjchJRfNG5Lh/7PPgUo3LWXfQr3qKm5dOT0PbgY7Mif3fvkoI7CT5RG+TVau5YjU6zL8TWAx8nv7U2hgU/VuJT96FvBYbnvbySJwk7LMEl85UzZ4M3o9D74csj9lRGIc3VXoOL7T9peYzTxr6+0Uuo6mBWOdgnp5tn/ew145SXJmwL2Ly3k/KVn5lehL6F11QaUI74Yw/MuZ6eXmiR/ZBcbBHD2WnRyJOPjw/IOwUO848A4NoAcie0ESKSRk5RdmksMns5wYniUEYOCjuErk8NK3ClquQ0Wd6yOz0TTRUkPrUR4fIuEGraYlIARUvnidxK9kFj6q5KYc2MKPGw0m9scPGLGokEAnllrs+nEQ=='],
    }

    @admin::user { 'catrope':
            realname => 'Roan Kattouw',
            uid      => 546,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAg8ogPqDDyhMBfXdV6Z8UKv3esRE4I0EAkrxnCCXuBfBnJ1A0dNsV8hKBsdRs4UCEitIA1a6bSCbq+kV7Xvq0yMihAFe3AG+26OISi5NZP+gNtx/aIBLGAgDXoC3M4Nb27F+pEDSfhT5OC6N/uO3o1UK4RSfgWNsmNW/lk5Ir57U='],
    }

    @admin::user { 'cmjohnson1':
            realname => 'Chris Johnson',
            uid      => 579,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDnDmdyh5Stw9bMTm7qL1kWuNpazc1m6HiaN0ZlaqwbUIhvtADWobHZcHvTHMwyauU/X6joE+a6pyvYgM2hr6+wRawjmgOuK8cak90weyp+i20HCiPb5GqOLE0uDmDizI8Hb50kxjiXLF6k+7cT7i0Lksa9EKhsYEwCjgnOiGor6wEvN1RlwRuwNBOZcI6OUvV39G/VP/pjpZBeUNoUZHWgpr9nbX+rlctjzK0s8sRbUamvCG3lyeB1pNIVCkY9YOwvf1D2UpRnhIm3XQspojphCFzC6HqRqZOyygweKc98fmvxkbkiyzh9XPtKyV5CtRS+9ECUmZjfmcWZpomCN2tp',
                         'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDP7wD7CRHLh4V9Sjn72a/eh3hTQhprQ3fPxUX+G7oCGuRXmWAwHcoB2Rm7vZxiAEa6hA151YOEorYN8e6bYP0eqcpEu9G9cbDirnaAhKHf+r+n9OgJmpA8hDQQ0H4MuWH9W6uQLEi1Xl9Z41/u/LlfrmD9F77ed2jXCYAYgVwuNuO5lnOevMxLWH+aCtfYdp/QtEA9a+o2j0Dc0JveqXNFlCdcacLAME2q7ZHnyRwFndMgTiljnOSb3SjV/1tkNtq3Dkhnp1T3LXgSIX7gtxbfVd2u5b8HoaQYmpXSlRhyL+ulVJDJAEFVA+tp5lbcGK4kglNnBNKrQO9Bng+FlKwR',
                         'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRLeXOUkI5OZkubtTv8jVVq7itOUQ38usJdMap8zjSQw9g7kbLj66369NQrp4g8MRiD1WhDGkxL5IeU8leQcAhTYB0SmAr/JAK363a/bgcR3OJL3LZcoji6iIhhDukanXNwo19uotoqJVj+J/CdSWzIbYefihN/FGf6CW9bqHhrBKY0t8k2HaT7EXxvxx7NXlCUQCSKHlkfNyd+BT+nYQ+oQQxyxFHrvKPhs9TPy8U7eVKpU1d0DfVVlKKB65l0O2Ldny0K4i8NPv+CmwX1zJqRzqc0inqfT3Eatc6a47pqJq2tL8ah4hYyrtYh2swicY3JbOP8lVWvnV3PZ2/iRMN',
                         'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDjVPy2od8cEq1waL62yVzYmppKJSg95xFecXKVUutsE8P9VcHEdGFIg+pZoOv9X9u1rV4zrjxFomLka4RD9fhV4be3r4aXIswQ08Y9fQhQ6ixs0Y0rNmfF0P/C1vxZgZ9gPp5nSIAfng+W+CU6Ecsf/0TUc136KnpliYBIOWUD0kcgTRd3cu24w+6JYHXelZXvMB7dImlb9ilkk3OehXfNuABZpBN0PHM4CDDiZeSO1G6OD38evfuigFBo1U5zezRuOdDh5tTWug3fkmGf9bBH5MKnnIEfrzsbzQomeB0fJs1LEweFlwPZAsjQ4o0riJEhLwWFUlE88ABGbPhwJ9/X',
                         'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7y4rw4Np/Xy1MgQYx6dciv+vszegmZjZbh5p7PHdddLI+8wDM2Q7tz+ghm6PkKuUlcwK99fD2ixlb8FoBrznUABTEmaSMBdSIhXS2J81mJ5ycrCeb/+bG9YQ8e1sABjfFSWu07wqUgPZqx6roeduc1fkp9DvH8FasbFZcuPsgkvANwaWm+TTSY8Ik1h7l1bJHIp7iRuLRQ9fZjsZCHD4svfuU3YEyIHKPYmPQFgJn1wyYDKgIbfewcK/rFX43E9Kqd/SpKqapIex1fYWA0/MtbAzVLb3YdX/vWQP6lx4Kwzc6OPzib++RY6bR0zd14IdkGZ2wgwcqR/MRaafotARV'],
    }

    @admin::user { 'dzahn':
            realname => 'Daniel Zahn',
            uid      => 575,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDY3GzbCE2eOM7IxQClHag9FRVg0eryA6PVa7p80Yp4suPzW73KVv9BgbSDvkdGNv9NOsVqkZkp01oZe7+XVxh1jaxM60nkF02DGKI0jn2lbzzWR5YS6gabjjn9SaOnh0MAwC8Jpvdz/YKOyE9/PAIFXajNwTuE6alHU/nWnLHaR1FJQRlfZLDlP9deNRAPaXOyn/jbO+ODNQIFeKSV0TmvZAh994wUlLoDYa1UcuqTRc9tJBmpLALVPZs1U2FZvLr7fkuOnUhcOC/uqE/pDdalSy0k6bAh/pkILOMFzhCHtrsbUV0AT7cVBogE7qYRuTo3eBrpzj9Bbsi41Q4y29lridBoyBgEMH/fnEIMDivNLzec5nYLPJ/XIDSc0G2iFoWY/u7SaVT7A6rjlSuzS7owunNXEj1mhmNW7v/FIOqG2Zl3K7INBj8Y0rFL9GuwP5LIkZxlNZT7NEdUOA3i8L4sT3YJJgiaup4Ss66TpWCDQ/znZoz5Vi5ODhXjqMVVFbrHI/7eIYMChoR5HkcRdjaIShvFgSfWcKXlwHouIVUiXprnoZZGmAa9CTAx9GFrjgC7DixK654yx4Gb47q4dttSE2nZKY1njfDRHcbLRuZ1ESEpAcoxkos1agvShw5B4ysSYRcMHkF2yqi2srq7Us19JWCmLm2RW5z+4xPBAfEMcw=='],
    }

    @admin::user { 'faidon':
            realname => 'Faidon Liambotis',
            uid      => 592,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/m5mZhy2bpvmBNzaLLhlqhjLuuGd5vNGgAtRKmvfa+nbHi7upm8d/e1RoSGVueXSVdjcVYfqqfNnJQ9GIC9flhgVhTwz1zezCEWREqMQ3XuauqAr+Tb/031BtgLCHfTmUjdsDKTigwTMPOnRG+DNo+ZHyxfpTCP5Oy6TChcK6+Om247eiXEhHZNL8Sk0idSy2mSJxavzs25F/lsGjsl4YyVV3jNqgVqoz3Evl1VO0E3xlbOOeWeJnROq+g2JJqZfoCtdAYidtg8oJ6yBKJHoxynqI6EhBJtnwulIXGTZmdY2cMJwT2YpkqljQFBwtWIy/T+WNkZnLuJXT4DRlBb1F'],
    }

    @admin::user { 'gage':
            realname => 'Jeff Gage',
            uid      => 4177,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCs/SColtnog9MyumWcau/7bfSvJhot5bSZWGnTPI9QjMupTQH0WCr1IWdD6NMvGsiDd81RzpfdNO0qCvyXQgAXFBs2O8ORea9kNOi/VElyGh9HJkqUERsMScrLFrhhmUyNVTw1gnk3sanRXASTC7zSXiZS5a5mqr9LfzPYhw04K57XCspFwERsg7kkIMYbl/yPMFmmPTUsLWTPMyF7xyn0TnrOTUx32RGIj4G/Kcsc8kcvSDGpiZSLvoC1QxuXEWOK0N7fd8PcL0YEYArLTPTdzM2CTvP7jEB0totPtxgWLFy+03aohdtX/cnWe1i1Udfh4dr5Z8/1x7BBSW1NX0JJ'],
    }

    @admin::user { 'jgreen':
            realname => 'Jeff Green',
            uid      => 571,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjkTnfRGIhs0of/3Z9GhOEEavkzFFg87n9D5BqNJAKtRSy5uh87p3DEHWnYcA5Ak7TD66hWae/V2tyQTHVBcDfZhoSFKsIMmhC/ooDtN8iewl37Dbss+a7m4GT0BmILkgUC2IJnFDFz2Eb6RVsnD11ajfbO4buNfokJC7jMjxQ2btpR5FojWNX7xffw5yg4aGg+k9x+32bM8ZTEzyYUGpxUZxV9jmbK1uzTBfZSlgmfok3Hn+scki52DM7EPIU0pxf8cyPHPIc7WX/wR56GsILoFNMBkePP86O/ZDuhOSdsFMJaBmOHM+9qCMW6JPKOtogvEaglbgCRrTZ0VkJx2HX',
                         'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEA0065bEe76amow8pXj+cS7rMHajCMfBCrUxOlijTgUv5o6e1v04hm7iEwxadcUbPrauGgsZOoeuoLzz3J/oS7qb1pliNKgdvcMw/sA+sqZoh2iIKjwLkEu49CJJ6Wxiolg+p3Y8yQHOUTc7sozkREkXsDyZZsNbmOcwtDlCe5SJc='],
    }

    @admin::user { 'laner':
            realname => 'Ryan Lane',
            uid      => 553,
            ssh_keys => ['ssh-rsa b87TDJoFNE2WjqlPlUWDLZa88023CO65dL8e907QR7OHYPLxbpiJMLYFvdJ1nByquo9t+iV3Iu8/WQS1JOPsGriN282qyc3EErir03et75kS7h+1Zhr+Z6BB0MO2cd6SJDl1cChcIrlHzs4zpufUzWXq9ELBmIaxYBH5iUYYM4ezSyA+qEbDnEpweJiW5w==',
                         'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRsK78adkRJfbYrsZznpbwldoSpQyyQXrXG6WzrJEBAVIAKz5gPSM8zmJ/kj89QygYRaKRPWAcuF5GZhSho15dwDXm5M0ZTva4/m/Hu4H3j7oxx3PKjZKBiygP7mSu/32TJs7FynPGAFVl/B766Snn9Ll/xwrx4lg3v9ZNEpNMJZ0DQTFZ1xXD2Ns08JvxW1csAEoNrpqH6tTdXdHmhurXdKQq1G/JmKR3/KVWbB1MNvUwCY0mQbN1icuy+JsOXbvXEftumigXRV16reLvX3q4sNmYSFfOGOMMW7K9d+nDc4TRNrUjm8R0AEZ6BxTJsvpahDi1gCOfZnGmpGKUEWgZ']
    }

    @admin::user { 'marc':
            realname => 'Marc-Andre Pelletier',
            uid      => 634,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1kc3MAAACBAIhfgD+1iRANjpwfBQbWD383oiDHcrzj2urFBKC62o1h7cgK2NplOfxCU5eHtGh5ftzp6JU4deNWw2s3/IRJFVfQnNiHV89/Rl1uqMjLhhvLb07GDonbs+KExCsYsZFHKUH+t2dkVg0NlR1Tpz+h6huYEkaCKWxg/ozvUswHroRtAAAAFQCPGGHMiPuztPl4yFm3cHp+QSZODwAAAIAc9/psvWDUBTSnsIzTwe801NHz/1mqBZHGTmk6IhFb2KTwdu6Sf70JkWQH47h5MmTsld2rzvBopbBMubRfBu6KCWXJM03pfxRdgUuhwovAKgU1hddYdonhkiq24qn+U7tnYHjHfu5jB7dnjEEqoOggUXmVUwS7QaGJqKUnA4B0+gAAAIEAhoDEpBOFA5NsgurAjntLMZiTpkQFyE+c39lBqgd6B5bX7GEB5JkMPVSTjmzogd88+SwImCWgvb1I0PgY/rx8nd9wMkE3W5gBGUiDTNJa2v78nTK9wS+imFDRMbuwdYuN1wmKGrnvskvQ5oi1juLA8jn0At3L2/SYiC7i5z/z//8='],
    }

    @admin::user { 'mark':
            realname => 'Mark Bergsma',
            uid      => 531,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAorTmQ0qlrxB3RL+GULLzex3k1Pg/c6tgLbKsl1A7Qo0B5XI4eNgfWwaAXUrKyQW3/9gwDH3YJ2eoOue0/BGhKX6voOTnNPeGE9ZbrufpPLT6DXDEbvpmXQd/qw8s0GxdftleHYl28av0nTZgKY+1/Oc+ZHNUN5YxmdGehWBvTXs='],
    }

    @admin::user { 'midom':
            realname => 'Domas Mituzas',
            uid      => 527,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1kc3MAAACBAMOWDta08PH5U6hxvnHq7xT7lqIxWxMzP8wr20np4thUtlOqLsxmpJzHzdWJMlaEu0cLrJXxYq2Bm5jBpDb8Tmfo2TeIPgmFWmLgLpF9A4biXmMA6V9Dp5W/eyZgmlHjWlTLu6Y5WaK+Dr42rKzCMHeSxY8T/gvVIXvjZliNb7cvAAAAFQCLTv4hEekK6nLpqX2j/ac7Wj4eHQAAAIA3D0eTxabhSGD8a1IL/2i+Fb8YBLm6uJOXHmeIZNrpl78ml7lOcXxlQSlrQ8Gixc9eKz1a4vzuqKhxqdSFMFcA3wK0cGtXQuCtbiKGgFdKDsK1uBk/5d5mowqYNwZ62taA41NO4VGB7rYHga8Wg2ph5NZ5yuQgmOI8JqlbALH9oQAAAIAwDc1SQBOYJacBv/NeXhQIuDUO2x7gnqyr9Ud8hlnzy34GQldo+03AvL9vq2RSemCQBjnEqxXYUGhHqDshUvnHq5JxpeWjKRP+p5e0Xy7aepss3g9/IzUUrZ5m9HskczSfrlNBwDG5ybgaCJfyRX0MXnV1GCjaGlI2k0iymqGT+w==',
                         'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAomwyIAuPEDxmRFl3O11IH1yH+n7th+meS4dmB9OzKxh5Sg/aURrfFPUV/rSh+2QqfR7M7kB59ganKpc/7tCXW9mxoIr/c1kQ9jBzpyc7VUox/VTlSTZOFJA9sH9PUVIDINVNPyPFLNy9RtvWkSfHwffo6LHNju+us9PaUlmAaE0=',
                         'ssh-rsa AAAAB3NzaC1kc3MAAACBAIRBscJUrqCDE7vK6YwlQdEXsGCBaW44dbPoG8QRtHU+bD8wZg/ViI5RX6hRCEJ7EWC8W+3xfocbo48UP94cAuvsQCquDvE+mwnVPihy3EtfbPFdPj0X8E/dGGD3YzRhq7ALMAnRPYlsgixd2YMDUrEYM7gsmeZbwfDrfgFYihTxAAAAFQCZv5NzAdGZSURVo/oAGr/27rxYswAAAIAlzeKOSWRBHV+01jPhESwbQpDhgVWd7KcowZ8JP/Ok2isperY9Yyi49udCy3PTNR63zyVqsrA8HHFbAmQvMXInAQxeqLxthWQL5MPYGKaZ7GeFiR5IhJjW1uK7flmdL8855BAbFbtdMGXgLVfH+Wa5o68e8hdNfP5jKkzTQRqkbAAAAIAhIqRn8sfBgd8vh0oZfzEJKaU8mOentbfN/tGXoFsPZF1kI4HTnYlktfzxo6wd9GGeXb8dJOa3r5OBvuw35zs/4ChPyONaMwyXCLRIDf6Iamhn6Vh81UFrGjuhng5awW5VLhQJcAr5zZ2tw0YWHQ8UExFnIYPnKuWnAs+qIFv0rA==',
                         'ssh-rsa AAAAB3NzaC1kc3MAAACBAO+dLGWJQ2nu3jsNnRG2zsX7W9HK/XHOvWRRiezAf8e/d0n8vHOUL20MszrIRenM+F/WP4DPhIpDBpZ0DlIslY1IxX0hNeG5kgkq0dftRbO+qnf70nurWmggAlK5H+omCDgn9odR68f+ovfkcCz7edYz2Gq2vNHFpuK4wOJhQGZTAAAAFQCWwe8yW7iddPkBaViWTDpvLwBd4QAAAIEA5AYTGGVu8DAuL0OShVduean+IQd3j2xiU0HTCuALQZHTxMcN9BSxbgYY7Moh1TRAKpNwQUvtw6RVS2k58s69RAj8URpFzMSmnrgbTZt6CZ3AuRrnlz74S8FLTwDWMeHDyg5ey5ezOcQn0o34wuK3H0EFtkshykKQA53nd6aFmfYAAACAax/cZBm/Sjrb2+c3HE6WKfVSSi0dLLe/D1LidksSYEv/Kfcgx+/6ze7o+yHT3n+5cW813/2Iaa18cYD591o9tD6NM+WI/WtWrJIx/4sIwudow90N6P1JMkf+gr8hnIszaw52Zf0Xw5C7tLSkR6gMcI4WgwTQakQkram1DaJEIPk=',
                         'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAvIaIOXvgvLTMPmSIEg/ebFWQtwj9x8KGs4148oj/ytyhwtcBcx1qT+dy03YyZebxt1snVUr/o/xYnzQNksYJug61dmGZLmeG7ktTVkLeUJqoLDmgP450vR/Vlug+YX63kGCKZIaCO47AzINfSSBfaXJq+GF8OBWEThfxq8V5GoOp2BMqf7e3LPIQOe/p7/Yr0yGAjFXZ5ju+KLs3JFP5wDVKSKNjjs+x8a74DYyUYiKeFox549e/iOXq8cLSfGyLQ7asYRKS0+UjPLO5Pi3iW5bGLMibiSNui+sWLL8meEPVr7DtqtZ2/XptzDCb9KUaxldRtYNoYczls1dR0fXjmw=='],
    }

    @admin::user { 'otto':
            realname => 'Andrew Otto',
            uid      => 589,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAw+oSU5aOOAxlmjTZvJnOEPbOAOchKKeTi5RO6KIVddIVXspHbBZKhuBmDLbppsB2x/kA5XYC0otA/FD1Ldr7v+OQp3XRTUlxchjGKci91ztPL4WbedCR33DUjjZW4ro2XlvoSLgH0vIZU8B3a7a49BgtXIPxtXw/evmzRmRfguNam/pvVfv6AE+1NGNQGadLNP2nHTjd8B2WEC1aVIblk3ZOsLsGvvFQQvuwLdMsDcK9/6Khy6rE4fYXJGd9ucVYIH0V/487Syg9tvk9xMEX46z4O38EV42CVhBm4ebpQ8roJJwwuD7MGIUeRicylvmVHHd+KxMqB6VkvGYIUXcasQ==',
                         'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyYwXitC3hSK+Gwfq3y0PlGlQMRHaqsTtJcDbgoxuE0kzEEKwSVpyXIxoUdUK0Luh2eVkR+CZ8+5lLVDJOhrGpBT6r/Z9p+o+9rVopNEkHM8QxqbhDoS5gbSEngISM+Zcyo1wTK+bB4tbzCcX7eJEVlxmPv4Tb85zDcMWSR2ZWV+jPMai9/3uO61Q3n9GOX94+3qIWmZE55AIjLT/lw3iGffwSMffO9/8UC9U2sVW3v3daXuvDgmjKkAiGaJp+Evq82ahQEOgOWPDuLXYo1DyFuqsL67CDA1hYZfA9FJRfUhOW9I32mGmFpjdJsFeWSU4VIOHO//Blpy0j6h4IPacJ'],
    }

    @admin::user { 'robh':
            realname => 'Rob Halsell',
            uid      => 2007,
            ssh_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAoDAuzkYEIeGVC10zh3i6WnyJjhWK/JpQbSFlWfb5t02kGPvmi8m+fdCPhvqiOpOCcQqTL1Knia6AeRNMx+dj3qxctsas/RnJtIUbACK5gH6aKg0OMmcG9LNiVLN5knx1UMHhQ7Ma6KSiDLeqsID009j7+Fj8qgGup7lKOQs7WYRpaXlAyR0hdKeyxcXWh+GPQEZAhl0DHrjFgdDcc5n2K8GBRESfdfCKm0SomHYGWPsTIpWrY13se0kUJzWXIafzr0U/czEdVDuSuil6P65d9cU7vypcUC3i5d2L4QiO4MBVNcXluFuFNZ8UY/QAlixz/5x/ARbgjcMvXwJQWjhh+w==',
                         'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAsyIODQk6BtkDVp8rHfMRZFcDJxdv7jLK6ga2U5oRUb/thKLoocECQ8fEzkAJBOmuyhv825W86NmiAmPj320gI72zQacCyu3Mj1FnLQV9P9z2G6POqs/OdnG+3wZV1aTRoWHFREalEon1FoBOSE2TOgr5UtNnL+X+pmFkqjIKmCx/97KOq27xwNlYLEzO6FJcSptDoWoYEChT+/MtUiKoh5ZwAxSH1j8iLLwsKhV7+RC5EKKor21teTRMzYj59oYR7wM9IuhKFJRewKRJwaZSFboS0H33QxMsEgZhbawOSBn1r3mepfNsa+AI4B8T/1EIdSe3H+NArq8Wm/oAR3hN2w==',
                         'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA8SKRT6tT1G/qDHuSoZsR/qTEREN7Zk39P/Gptzr4Ttu2TdCRDLyStHrssqfVXVXwa9AJ7UG8FOnwkz6Ow1zjQEOce6dOAPnZI/hdrxChsUOULTzxK56KwHh9J51vu26+2xpuW6CG0w2ycohTjAXiNEQJbfGthQTXto0h26KdZsCGqTbAlKy1X/Gm/kJeOXzGNja9ezivWRfD8XsNX4igKz/2PHRlWhv6hWIzBVZmMJ1yYm9guhwWaya97uRTWhD9H0OL8/xKBwMrM5eXlVWX5BQhFwkqwvtArSioIWf5wD3e6a0OdOjfCHZEpBpUY/Rv1BW+9FXJ310nleoN4kfuvQ=='],
    }
}
