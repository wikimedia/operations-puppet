# decomissioning.pp

# ALPHABETIC order!

$decommissioned_servers = [
'analytics1001', #renamed virt1001
'analytics1002', #renamed virt1002
'analytics1005', #renamed virt1003
'analytics1006', #renamed virt1008
'analytics1008', #renamed virt1009
'br1-knams',
'controller',
'cp1021',    # cp 1021-1042 were reclaimed, 5981
'cp1022',
'cp1023',
'cp1024',
'cp1025',
'cp1026',
'cp1027',
'cp1028',
'cp1029',
'cp1030',
'cp1031',
'cp1032',
'cp1033',
'cp1034',
'cp1035',
'cp1036',
'cp1041',
'cp1042',
'cp3001',
'cp3002',
'db29',
'db31',
'db32',
'db33',
'db34',
'db36',
'db37',
'db39',
'db42',
'db43',
'db44',
'db45',
'db46',
'db47',
'db49',
'db50',
'db51',
'db52',
'db53',
'db54',
'db55',
'db56',
'db57',
'db58',
'db59',
#dysprosium -- add this back later when it is reclaimed
'loudon',      #6633 decomed
'ms1',
'ms2',        #5994 decommed
'ms3',
'ms4',        #885  decommed
'payments1',
'payments2',
'payments3',
'payments4',
'professor',  #6269 decommed
'search21',   #6106 decommed search21-36
'search22',
'search23',
'search24',
'search25',
'search26',
'search27',
'search28',
'search29',
'search30',
'search31',
'search32',
'search33',
'search34',
'search35',
'search36',
'sq31',  #1706 decommed
'sq32',  #2472 decommed
'sq33',  #4992 decommed
'sq34',  #2823 decommed
'sq35',  #1404 decommed
'sq36',  #5727 decommed
'sq37',  #6520 decommed
'sq38',  #2017 decommed
'sq39',  #2581 decommed
'sq40',  #2581 decommed
'sq41',  #5646 decommed
'sq42',  #5754 decommed
'sq43',  #6520 decommed
'sq44',  #6367 decommed
'sq45',  #5986 decommed
'sq46',  #2581 decommed
'sq47',  #1597 decommed
'sq48',  #6274 decommed
'sq49',  #6520 decommed
'sq50',  #6520 decommed
'sq51',  #6520 decommed
'sq52',  #6520 decommed
'sq53',  #6520 decommed
'sq54',  #6520 decommed
'sq55',  #6520 decommed
'sq56',  #6520 decommed
'sq57',  #6520 decommed
'sq58',  #6520 decommed
'sq59',  #6520 decommed
'sq60',  #6520 decommed
'sq61',  #6520 decommed
'sq62',  #6520 decommed
'sq63',  #6520 decommed
'sq64',  #6520 decommed
'sq65',  #6520 decommed
'sq66',  #6520 decommed
'sq71',  #6520 decommed
'sq72',  #6520 decommed
'sq73',  #6520 decommed
'sq74',  #6520 decommed
'sq75',  #6520 decommed
'sq76',  #6520 decommed
'sq77',  #6520 decommed
'sq78',  #6520 decommed
'sq79',  #6520 decommed
'sq80',  #6520 decommed
'sq81',  #6520 decommed
'sq82',  #6520 decommed
'sq83',  #6520 decommed
'sq84',  #6520 decommed
'sq85',  #6520 decommed
'sq86',  #6520 decommed
'ssl3004', #added 9/17
'virt1',  #5645 decommed
'virt3',
'virt4',
'wikinews-lb.wikimedia.org',
'williams', #5908 decommed
]
