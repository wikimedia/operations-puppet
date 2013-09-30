# decomissioning.pp

# ALPHABETIC order!

$decommissioned_servers = [
'barium',
'br1-knams',
'constable',
'controller',
'cp1021',
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
'db1014', #renamed and reallocated as tungsten rt5871
'dysprosium',
'labstore1002', #added 9/17 to remove from monitoring
'labstore4', #added 9/17 to remove from monitoring
'mc2',
'mc3',
'mc4',
'mc5',
'mc6',
'mc7',
'mc8',
'mc9',
'mc10',
'mc11',
'mc12',
'mc13',
'mc14',
'mc15',
'mc16',
'mobile1',
'mobile2',
'mobile3',
'mobile4',
'mobile5',
'ms1',
'ms2',
'ms3',
'ms4',
'msfe1002',
'praseodymium', #2013-08-29 reclaim to spare by robh
'spence',
'sq31',
'sq32',
'sq33',
'sq34',
'sq35',
'sq36',
'sq38',
'sq39',
'sq40',
'sq41',
'sq42',
'sq45',
'sq46',
'sq47',
'srv86',
'srv87',
'srv88',
'srv89',
'srv90',
'srv91',
'srv92',
'srv93',
'srv94',
'srv95',
'srv96',
'srv97',
'srv98',
'srv99',
'srv100',
'srv101',
'srv102',
'srv103',
'srv104',
'srv105',
'srv106',
'srv107',
'srv108',
'srv109',
'srv110',
'srv111',
'srv112',
'srv113',
'srv114',
'srv115',
'srv116',
'srv117',
'srv118',
'srv119',
'srv120',
'srv121',
'srv122',
'srv123',
'srv124',
'srv125',
'srv126',
'srv127',
'srv128',
'srv129',
'srv130',
'srv131',
'srv132',
'srv133',
'srv134',
'srv135',
'srv136',
'srv137',
'srv138',
'srv139',
'srv140',
'srv141',
'srv142',
'srv143',
'srv144',
'srv145',
'srv146',
'srv147',
'srv148',
'srv149',
'srv150',
'srv151',
'srv152',
'srv153',
'srv154',
'srv155',
'srv156',
'srv157',
'srv158',
'srv159',
'srv160',
'srv161',
'srv162',
'srv163',
'srv164',
'srv165',
'srv166',
'srv167',
'srv168',
'srv169',
'srv170',
'srv171',
'srv172',
'srv173',
'srv174',
'srv175',
'srv176',
'srv177',
'srv178',
'srv179',
'srv180',
'srv181',
'srv182',
'srv183',
'srv184',
'srv185',
'srv186',
'srv187',
'srv188',
'srv189',
'srv190',
'srv191',
'srv192',
'srv194',
'srv195',
'srv196',
'srv197',
'srv198',
'srv199',
'srv200',
'srv201',
'srv202',
'srv203',
'srv204',
'srv205',
'srv206',
'srv207',
'srv208',
'srv209',
'srv210',
'srv211',
'srv212',
'srv213',
'srv214',
'srv215',
'srv216',
'srv217',
'srv218',
'srv219',
'srv220',
'srv221',
'srv222',
'srv223',
'srv224',
'srv225',
'srv226',
'srv227',
'srv228',
'srv229',
'srv230',
'srv231',
'srv232',
'srv233',
'srv234',
'srv266',
'srv278',
'srv281',
'ssl3004', #added 9/17 to remove from monitoring
'storage1',
'storage2',
'storage3',
'thistle',
'titanium', #2013-08-29 reclaim to spare by robh
'tola',
'virt1001',
'virt1002',
'virt1003',
'virt1',
'virt3',
'virt4',
'wikinews-lb.wikimedia.org',
'wtp1',
'xenon', #2013-08-29 reclaim to spare by robh
]
