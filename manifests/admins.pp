# admins.pp

# HOW TO ENABLE/DISABLE/PARTIALLY REMOVE ACCOUNTS from nodes

# See documentation at top of accounts.pp

# these lists can't use virtual resources until bug
# http://projects.puppetlabs.com/issues/4151 is fixed.

class admins::roots {
	# In addition to adding the user to this list, you MUST add the user's key
	# to /root/private/files/ssh/root-authorized-keys on sockpuppet, then git
	# commit and pull to /var/lib/git/operations/private/ on stafford, to
	# actually get them root; that file is not in the public repo.

	if ! defined(Accounts::Wanted['andrewb']) { accounts::wanted { 'andrewb': } }
	if ! defined(Accounts::Wanted['akosiaris']) { accounts::wanted { 'akosiaris': } }
	if ! defined(Accounts::Wanted['ariel']) { accounts::wanted { 'ariel': } }
	if ! defined(Accounts::Wanted['asher']) { accounts::wanted { 'asher': } }
	if ! defined(Accounts::Wanted['bblack']) { accounts::wanted { 'bblack': } }
	if ! defined(Accounts::Wanted['brion']) { accounts::wanted { 'brion': } }          # re-enabled dz 20121004
	if ! defined(Accounts::Wanted['catrope']) { accounts::wanted { 'catrope': } }
	if ! defined(Accounts::Wanted['cmjohnson']) { accounts::wanted { 'cmjohnson': } }
	if ! defined(Accounts::Wanted['dzahn']) { accounts::wanted { 'dzahn': } }
	if ! defined(Accounts::Wanted['faidon']) { accounts::wanted { 'faidon': } }
	if ! defined(Accounts::Wanted['jeluf']) { accounts::wanted { 'jeluf': } }
	if ! defined(Accounts::Wanted['jgreen']) { accounts::wanted { 'jgreen': } }
	if ! defined(Accounts::Wanted['kate']) { accounts::wanted { 'kate': } }
	if ! defined(Accounts::Wanted['laner']) { accounts::wanted { 'laner': } }
	if ! defined(Accounts::Wanted['lcarr']) { accounts::wanted { 'lcarr': } }
	if ! defined(Accounts::Wanted['marc']) { accounts::wanted { 'marc': } }
	if ! defined(Accounts::Wanted['mark']) { accounts::wanted { 'mark': } }
	if ! defined(Accounts::Wanted['midom']) { accounts::wanted { 'midom': } }
	if ! defined(Accounts::Wanted['py']) { accounts::wanted { 'py': } }
	if ! defined(Accounts::Wanted['robh']) { accounts::wanted { 'robh': } }
	if ! defined(Accounts::Wanted['springle']) { accounts::wanted { 'springle': } }
	if ! defined(Accounts::Wanted['tstarling']) { accounts::wanted { 'tstarling': } }

	Class['admins::roots'] -> Class['accounts::all']
}

# mortals are the software deployment group, we should rename and rewrite this someday
class admins::mortals {
	if ! defined(Accounts::Wanted['aaron']) { accounts::wanted { 'aaron': } }
	if ! defined(Accounts::Wanted['abaso']) { accounts::wanted { 'abaso': } }
	if ! defined(Accounts::Wanted['andrew']) { accounts::wanted { 'andrew': } }
	if ! defined(Accounts::Wanted['anomie']) { accounts::wanted { 'anomie': } }
	if ! defined(Accounts::Wanted['awight']) { accounts::wanted { 'awight': } }
	if ! defined(Accounts::Wanted['awjrichards']) { accounts::wanted { 'awjrichards': } }
	if ! defined(Accounts::Wanted['bsitu']) { accounts::wanted { 'bsitu': } }
	if ! defined(Accounts::Wanted['cmcmahon']) { accounts::wanted { 'cmcmahon': } }
	if ! defined(Accounts::Wanted['csteipp']) { accounts::wanted { 'csteipp': } }
	if ! defined(Accounts::Wanted['demon']) { accounts::wanted { 'demon': } }
	if ! defined(Accounts::Wanted['gwicke']) { accounts::wanted { 'gwicke': } }
	if ! defined(Accounts::Wanted['halfak']) { accounts::wanted { 'halfak': } }
	if ! defined(Accounts::Wanted['hashar']) { accounts::wanted { 'hashar': } }
	if ! defined(Accounts::Wanted['kaldari']) { accounts::wanted { 'kaldari': } }
	if ! defined(Accounts::Wanted['khorn']) { accounts::wanted { 'khorn': } }
	if ! defined(Accounts::Wanted['krinkle']) { accounts::wanted { 'krinkle': } }
	if ! defined(Accounts::Wanted['maxsem']) { accounts::wanted { 'maxsem': } }
	if ! defined(Accounts::Wanted['mflaschen']) { accounts::wanted { 'mflaschen': } }
	if ! defined(Accounts::Wanted['mholmquist']) { accounts::wanted { 'mholmquist': } }
	if ! defined(Accounts::Wanted['mlitn']) { accounts::wanted { 'mlitn': } }
	if ! defined(Accounts::Wanted['mwalker']) { accounts::wanted { 'mwalker': } }
	if ! defined(Accounts::Wanted['nikerabbit']) { accounts::wanted { 'nikerabbit': } }
	if ! defined(Accounts::Wanted['olivneh']) { accounts::wanted { 'olivneh': } }
	if ! defined(Accounts::Wanted['pgehres']) { accounts::wanted { 'pgehres': } }
	if ! defined(Accounts::Wanted['reedy']) { accounts::wanted { 'reedy': } }
	if ! defined(Accounts::Wanted['rmoen']) { accounts::wanted { 'rmoen': } }
	if ! defined(Accounts::Wanted['robla']) { accounts::wanted { 'robla': } }
	if ! defined(Accounts::Wanted['spage']) { accounts::wanted { 'spage': } }
	if ! defined(Accounts::Wanted['sumanah']) { accounts::wanted { 'sumanah': } }        # RT 3752
	if ! defined(Accounts::Wanted['tfinc']) { accounts::wanted { 'tfinc': } }            # move from roots RT 5485
	if ! defined(Accounts::Wanted['yurik']) { accounts::wanted { 'yurik': } }            # RT 4835, RT 5069

	Class['admins::mortals'] -> Class['accounts::all']
}

class admins::restricted {
	if ! defined(Accounts::Wanted['avar']) { accounts::wanted { 'avar': } }
	if ! defined(Accounts::Wanted['dab']) { accounts::wanted { 'dab': } }
	if ! defined(Accounts::Wanted['dartar']) { accounts::wanted { 'dartar': } }
	if ! defined(Accounts::Wanted['diederik']) { accounts::wanted { 'diederik': } }
	if ! defined(Accounts::Wanted['dsc']) { accounts::wanted { 'dsc': } }
	if ! defined(Accounts::Wanted['erik']) { accounts::wanted { 'erik': } }
	if ! defined(Accounts::Wanted['ezachte']) { accounts::wanted { 'ezachte': } }
	if ! defined(Accounts::Wanted['jamesofur']) { accounts::wanted { 'jamesofur': } }
	if ! defined(Accounts::Wanted['khorn']) { accounts::wanted { 'khorn': } }
	if ! defined(Accounts::Wanted['manybubbles']) { accounts::wanted { 'manybubbles': } }
	if ! defined(Accounts::Wanted['mgrover']) { accounts::wanted { 'mgrover': } }          # RT 4600
	if ! defined(Accounts::Wanted['milimetric']) { accounts::wanted { 'milimetric': } }
	if ! defined(Accounts::Wanted['otto']) { accounts::wanted { 'otto': } }
	if ! defined(Accounts::Wanted['qchris']) { accounts::wanted { 'qchris': } }            # RT 5403
	if ! defined(Accounts::Wanted['rainman']) { accounts::wanted { 'rainman': } }
	if ! defined(Accounts::Wanted['spetrea']) { accounts::wanted { 'spetrea': } }          # RT 5406
	if ! defined(Accounts::Wanted['ssastry']) { accounts::wanted { 'ssastry': } }          # RT 5512
	if ! defined(Accounts::Wanted['tparscal']) { accounts::wanted { 'tparscal': } }        
	if ! defined(Accounts::Wanted['tnegrin']) { accounts::wanted { 'tnegrin': } }          # RT 5391

	Class['admins::restricted'] -> Class['accounts::all']
}

class admins::jenkins {
	if ! defined(Accounts::Wanted['demon']) { accounts::wanted { 'demon': } }
	if ! defined(Accounts::Wanted['dsc']) { accounts::wanted { 'dsc': } }
	if ! defined(Accounts::Wanted['hashar']) { accounts::wanted { 'hashar': } }
	if ! defined(Accounts::Wanted['krinkle']) { accounts::wanted { 'krinkle': } }
	if ! defined(Accounts::Wanted['mholmquist']) { accounts::wanted { 'mholmquist': } }
	if ! defined(Accounts::Wanted['reedy']) { accounts::wanted { 'reedy': } }

	Class['admins::jenkins'] -> Class['accounts::all']
}

class admins::dctech {
	if ! defined(Accounts::Wanted['sbernardin']) { accounts::wanted { 'sbernardin': } }

	Class['admins::dctech'] -> Class['accounts::all']
}

class admins::globaldev {
	if ! defined(Accounts::Wanted['erosen']) { accounts::wanted { 'erosen': } }      # RT 3119
	if ! defined(Accounts::Wanted['haithams']) { accounts::wanted { 'haithams': } }  # RT 3219
	if ! defined(Accounts::Wanted['handrade']) { accounts::wanted { 'handrade': } }  # RT 4726

	Class['admins::globaldev'] -> Class['accounts::all']
}

# == Class admins::privatedata
# Includes approved users that need access
# to private webrequests access logs.
#
class admins::privatedata {
	if ! defined(Accounts::Wanted['abaso']) { accounts::wanted { 'abaso': } }            # RT 5446
	if ! defined(Accounts::Wanted['awight']) { accounts::wanted { 'awight': } }          # RT 5048
	if ! defined(Accounts::Wanted['dartar']) { accounts::wanted { 'dartar': } }
	if ! defined(Accounts::Wanted['diederik']) { accounts::wanted { 'diederik': } }
	if ! defined(Accounts::Wanted['erosen']) { accounts::wanted { 'erosen': } }          # RT 3119
	if ! defined(Accounts::Wanted['ezachte']) { accounts::wanted { 'ezachte': } }
	if ! defined(Accounts::Wanted['haithams']) { accounts::wanted { 'haithams': } }      # RT 3219
	if ! defined(Accounts::Wanted['handrade']) { accounts::wanted { 'handrade': } }      # RT 4726
	if ! defined(Accounts::Wanted['howief']) { accounts::wanted { 'howief': } }          # RT 3576
	if ! defined(Accounts::Wanted['mgrover']) { accounts::wanted { 'mgrover': } }        # RT 4600
	if ! defined(Accounts::Wanted['milimetric']) { accounts::wanted { 'milimetric': } }
	if ! defined(Accounts::Wanted['mwalker']) { accounts::wanted { 'mwalker': } }        # RT 5038
	if ! defined(Accounts::Wanted['olivneh']) { accounts::wanted { 'olivneh': } }        # RT 3451
	if ! defined(Accounts::Wanted['otto']) { accounts::wanted { 'otto': } }
	if ! defined(Accounts::Wanted['qchris']) { accounts::wanted { 'qchris': } }          # RT 5474
	if ! defined(Accounts::Wanted['spetrea']) { accounts::wanted { 'spetrea': } }
	if ! defined(Accounts::Wanted['tnegrin']) { accounts::wanted { 'tnegrin': } }        # RT 5391
	if ! defined(Accounts::Wanted['yurik']) { accounts::wanted { 'yurik': } }            # RT 4835

	Class['admins::privatedata'] -> Class['accounts::all']
}

class admins::fr-tech {
	if ! defined(Accounts::Wanted['awight']) { accounts::wanted { 'awight': } }
	if ! defined(Accounts::Wanted['khorn']) { accounts::wanted { 'khorn': } }
	if ! defined(Accounts::Wanted['mwalker']) { accounts::wanted { 'mwalker': } }
	if ! defined(Accounts::Wanted['pgehres']) { accounts::wanted { 'pgehres': } }

	Class['admins::fr-tech'] -> Class['accounts::all']
}

class admins::fr-civicrm {
	if ! defined(Accounts::Wanted['mhernandez']) { accounts::wanted { 'mhernandez': } }
	if ! defined(Accounts::Wanted['pcoombe']) { accounts::wanted { 'pcoombe': } }
	if ! defined(Accounts::Wanted['sahar']) { accounts::wanted { 'sahar': } }
	if ! defined(Accounts::Wanted['zexley']) { accounts::wanted { 'zexley': } }

	Class['admins::fr-civicrm'] -> Class['accounts::all']
}
	
class admins::parsoid {
	if ! defined(Accounts::Wanted['catrope']) { accounts::wanted { 'catrope': } }
	if ! defined(Accounts::Wanted['gwicke']) { accounts::wanted { 'gwicke': } }
	if ! defined(Accounts::Wanted['ssastry']) { accounts::wanted { 'ssastry': } }          # RT 5512

	Class['admins::parsoid'] -> Class['accounts::all']
}

class admins::analytics {
	if ! defined(Accounts::Wanted['abaso']) { accounts::wanted { 'abaso': } }           # RT 5273
	if ! defined(Accounts::Wanted['dartar']) { accounts::wanted { 'dartar': } }
	if ! defined(Accounts::Wanted['diederik']) { accounts::wanted { 'diederik': } }
	if ! defined(Accounts::Wanted['dsc']) { accounts::wanted { 'dsc': } }
	if ! defined(Accounts::Wanted['erik']) { accounts::wanted { 'erik': } }
	if ! defined(Accounts::Wanted['erosen']) { accounts::wanted { 'erosen': } }
	if ! defined(Accounts::Wanted['halfak']) { accounts::wanted { 'halfak': } }         # RT 5233
	if ! defined(Accounts::Wanted['olivneh']) { accounts::wanted { 'olivneh': } }
	if ! defined(Accounts::Wanted['otto']) { accounts::wanted { 'otto': } }
	if ! defined(Accounts::Wanted['maryana']) { accounts::wanted { 'maryana': } }       # RT 5017
	if ! defined(Accounts::Wanted['milimetric']) { accounts::wanted { 'milimetric': } }
	if ! defined(Accounts::Wanted['qchris']) { accounts::wanted { 'qchris': } }         # RT 5403
	if ! defined(Accounts::Wanted['ram']) { accounts::wanted { 'ram': } }               # RT 5059
	if ! defined(Accounts::Wanted['spetrea']) { accounts::wanted { 'spetrea': } }  	    # RT 4402
	if ! defined(Accounts::Wanted['tnegrin']) { accounts::wanted { 'tnegrin': } }       # RT 5391
	if ! defined(Accounts::Wanted['yurik']) { accounts::wanted { 'yurik': } }           # RT 5158

	Class['admins::analytics'] -> Class['accounts::all']
}

class admins::stat1 {
	if ! defined(Accounts::Wanted['abartov']) { accounts::wanted { 'abartov': } }            # RT 4106
	if ! defined(Accounts::Wanted['aengels']) { accounts::wanted { 'aengels': } }
	if ! defined(Accounts::Wanted['akhanna']) { accounts::wanted { 'akhanna': } }
	if ! defined(Accounts::Wanted['awight']) { accounts::wanted { 'awight': } }              # RT 5048
	if ! defined(Accounts::Wanted['bsitu']) { accounts::wanted { 'bsitu': } }                # RT 4959
	if ! defined(Accounts::Wanted['dartar']) { accounts::wanted { 'dartar': } }
	if ! defined(Accounts::Wanted['declerambaul']) { accounts::wanted { 'declerambaul': } }
	if ! defined(Accounts::Wanted['diederik']) { accounts::wanted { 'diederik': } }
	if ! defined(Accounts::Wanted['dsc']) { accounts::wanted { 'dsc': } }
	if ! defined(Accounts::Wanted['ebernhardson']) { accounts::wanted { 'ebernhardson': } }  # RT 4959
	if ! defined(Accounts::Wanted['ezachte']) { accounts::wanted { 'ezachte': } }
	if ! defined(Accounts::Wanted['fschulenburg']) { accounts::wanted { 'fschulenburg': } }  # RT 4475
	if ! defined(Accounts::Wanted['giovanni']) { accounts::wanted { 'giovanni': } }          # RT 3460
	if ! defined(Accounts::Wanted['halfak']) { accounts::wanted { 'halfak': } }
	if ! defined(Accounts::Wanted['howief']) { accounts::wanted { 'howief': } }              # RT 3576
	if ! defined(Accounts::Wanted['ironholds']) { accounts::wanted { 'ironholds': } }
	if ! defined(Accounts::Wanted['jdlrobson']) { accounts::wanted { 'jdlrobson': } }
	if ! defined(Accounts::Wanted['jforrester']) { accounts::wanted { 'jforrester': } }      # RT 5302
	if ! defined(Accounts::Wanted['jgonera']) { accounts::wanted { 'jgonera': } }
	if ! defined(Accounts::Wanted['jmorgan']) { accounts::wanted { 'jmorgan': } }
	if ! defined(Accounts::Wanted['kaldari']) { accounts::wanted { 'kaldari': } }            # RT 4959
	if ! defined(Accounts::Wanted['lwelling']) { accounts::wanted { 'lwelling': } }          # RT 4959
	if ! defined(Accounts::Wanted['maryana']) { accounts::wanted { 'maryana': } }            # RT 3517
	if ! defined(Accounts::Wanted['mflaschen']) { accounts::wanted { 'mflaschen': } }        # RT 4796
	if ! defined(Accounts::Wanted['mgrover']) { accounts::wanted { 'mgrover': } }            # RT 4600
	if ! defined(Accounts::Wanted['milimetric']) { accounts::wanted { 'milimetric': } }      # RT 3540
	if ! defined(Accounts::Wanted['mlitn']) { accounts::wanted { 'mlitn': } }                # RT 4959
	if ! defined(Accounts::Wanted['mwalker']) { accounts::wanted { 'mwalker': } }            # RT 5038
	if ! defined(Accounts::Wanted['olivneh']) { accounts::wanted { 'olivneh': } }            # RT 3451
	if ! defined(Accounts::Wanted['otto']) { accounts::wanted { 'otto': } }
	if ! defined(Accounts::Wanted['qchris']) { accounts::wanted { 'qchris': } }              # RT 5474
	if ! defined(Accounts::Wanted['reedy']) { accounts::wanted { 'reedy': } }
	if ! defined(Accounts::Wanted['rfaulk']) { accounts::wanted { 'rfaulk': } }              # RT 5040
	if ! defined(Accounts::Wanted['spage']) { accounts::wanted { 'spage': } }
	if ! defined(Accounts::Wanted['spetrea']) { accounts::wanted { 'spetrea': } }            # RT 3584
	if ! defined(Accounts::Wanted['swalling']) { accounts::wanted { 'swalling': } }          # RT 3653
	if ! defined(Accounts::Wanted['tnegrin']) { accounts::wanted { 'tnegrin': } }            # RT 5391
	if ! defined(Accounts::Wanted['yurik']) { accounts::wanted { 'yurik': } }                # RT 4835

	Class['admins::stat1'] -> Class['accounts::all']
}

class admins::stat1001 {
	if ! defined(Accounts::Wanted['diederik']) { accounts::wanted { 'diederik': } }
	if ! defined(Accounts::Wanted['dsc']) { accounts::wanted { 'dsc': } }
	if ! defined(Accounts::Wanted['erosen']) { accounts::wanted { 'erosen': } }           # RT 5161
	if ! defined(Accounts::Wanted['ezachte']) { accounts::wanted { 'ezachte': } }
	if ! defined(Accounts::Wanted['milimetric']) { accounts::wanted { 'milimetric': } }
	if ! defined(Accounts::Wanted['otto']) { accounts::wanted { 'otto': } }
	if ! defined(Accounts::Wanted['qchris']) { accounts::wanted { 'qchris': } }           # RT 5474
	if ! defined(Accounts::Wanted['rfaulk']) { accounts::wanted { 'rfaulk': } }           # RT 4258
	if ! defined(Accounts::Wanted['tnegrin']) { accounts::wanted { 'tnegrin': } }         # RT 5391
	if ! defined(Accounts::Wanted['ypanda']) { accounts::wanted { 'ypanda': } }           # RT 4687

	Class['admins::stat1001'] -> Class['accounts::all']
}

class admins::owa {
	if ! defined(Accounts::Wanted['darrell']) { accounts::wanted { 'darrell': } }
	if ! defined(Accounts::Wanted['john']) { accounts::wanted { 'john': } }
	if ! defined(Accounts::Wanted['orion']) { accounts::wanted { 'orion': } }
	if ! defined(Accounts::Wanted['smerritt']) { accounts::wanted { 'smerritt': } }

	Class['admins::owa'] -> Class['accounts::all']
}

class admins::analytics::logging::allhosts {
	if ! defined(Accounts::Wanted['milimetric']) { accounts::wanted { 'milimetric': } }
	if ! defined(Accounts::Wanted['tnegrin']) { accounts::wanted { 'tnegrin': } } # RT 5391

	Class['admins::analytics::logging::allhosts'] -> Class['accounts::all']
}

class admins::analytics::logging::oxygen {
	if ! defined(Accounts::Wanted['awjrichards']) { accounts::wanted { 'awjrichards': } }
	if ! defined(Accounts::Wanted['datasets']) { accounts::wanted { 'datasets': } }
	if ! defined(Accounts::Wanted['dsc']) { accounts::wanted { 'dsc': } }
	if ! defined(Accounts::Wanted['diederik']) { accounts::wanted { 'diederik': } }
	if ! defined(Accounts::Wanted['manybubbles']) { accounts::wanted { 'manybubbles': } }   # RT 4312

	Class['admins::analytics::logging::oxygen'] -> Class['accounts::all']
}

class admins::analytics::logging::locke {
	if ! defined(Accounts::Wanted['datasets']) { accounts::wanted { 'datasets': } }
	if ! defined(Accounts::Wanted['dsc']) { accounts::wanted { 'dsc': } }
	if ! defined(Accounts::Wanted['tstarling']) { accounts::wanted { 'tstarling': } }

	Class['admins::analytics::logging::locke'] -> Class['accounts::all']
}

class admins::gerrit {
	if ! defined(Accounts::Wanted['demon']) { accounts::wanted { 'demon': } }

	Class['admins::gerrit'] -> Class['accounts::all']
}

class admins::robhtestbed {
	if ! defined(Accounts::Wanted['robh']) { accounts::wanted { 'robh': } }

	Class['admins::robhtestbed'] -> Class['accounts::all']
}

class admins::file_mover {
	if ! defined(Accounts::Wanted['file_mover']) { accounts::wanted { 'file_mover': } }

	Class['admins::file_mover'] -> Class['accounts::all']
}

class admins::webstatsrsync {
	if ! defined(Accounts::Wanted['datasets']) { accounts::wanted { 'datasets': } }

	Class['admins::webstatsrsync'] -> Class['accounts::all']
}

class admins::admintoolsdb {
	if ! defined(Accounts::Wanted['pgehres']) { accounts::wanted { 'pgehres': } }

	Class['admins::admintoolsdb'] -> Class['accounts::all']
}

class admins::bastion::fenari::others {
	if ! defined(Accounts::Wanted['erosen']) { accounts::wanted { 'erosen': } }

	Class['admins::bastion::fenari::others'] -> Class['accounts::all']
}

class admins::elasticsearch {
	if ! defined(Accounts::Wanted['demon']) { accounts::wanted { 'demon': } }
	if ! defined(Accounts::Wanted['manybubbles']) { accounts::wanted { 'manybubbles': } }
	if ! defined(Accounts::Wanted['ssastry']) { accounts::wanted { 'ssastry': } }          # RT 5512

	Class['admins::elasticsearch'] -> Class['accounts::all']
}
