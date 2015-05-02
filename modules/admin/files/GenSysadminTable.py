# Generates the table at https://meta.wikimedia.org/wiki/System_administrators#List
# Alex Monk, April 2015

from bs4 import BeautifulSoup
import urllib2, json, yaml

bs = BeautifulSoup(urllib2.urlopen("http://parsoid-lb.eqiad.wikimedia.org/metawiki/System_administrators").read())
oldUserData = {}
for table in bs.find_all('table')[:-2]:
	for part in json.loads(table.get('data-mw'))['parts']:
		if 'template' not in part:
			continue
		params = part['template']['params']
		oldUserData[params['name']['wt']] = {
			'ircnick': params['ircnick']['wt'],
			'link': params['link']['wt'],
			'affiliation': params['affiliation']['wt']
		}

d = yaml.load(open("../data/data.yaml").read())
groups = {}

for groupName, groupData in d['groups'].items():
	groups[groupName] = groupData['members']

print("""{| class="wikitable plainlinks sortable" style="margin-left: auto; margin-right: auto;"
|+ style="font-size: larger; font-weight: bold;" | {{{System administrators|{{MediaWiki:Group-sysadmin{{#translation:}}}}}}}
|-
! style="text-align: left;" | <translate><!--T:12-->
Name</translate>
! style="text-align: left;" | <translate><!--T:13-->
Wikimedia account</translate>
! style="text-align: left;" | <translate><!--T:14-->
[[IRC]]</translate>
! style="text-align: left;" | Affiliation
! style="text-align: left;" | Ops
! style="text-align: left;" | Deployment
! style="text-align: left;" | Restricted
|-""")

dataOut = {}
for userName, userData in d['users'].items():
	if userName in groups['absent'] or userData['ensure'] == 'absent' or len(userData['ssh_keys']) == 0:
		continue
	if userName not in groups['ops'] + groups['deployment'] + groups['restricted']:
		continue
	realName, link, ircnick, affiliation, groupWikitext = userData['realname'], '', '', '', ''
	if realName in oldUserData:
		ircnick = oldUserData[realName]['ircnick']
		link = oldUserData[realName]['link']
		affiliation = oldUserData[realName]['affiliation']

	if userName in groups['restricted']:
		outGroup = 'restricted'
		groupWikitext += "  | restricted = 1\n"
	if userName in groups['deployment']:
		outGroup = 'deployment'
		groupWikitext += "  | deployment = 1\n"
	if userName in groups['ops']:
		outGroup = 'ops'
		groupWikitext += "  | ops = 1\n"

	if outGroup not in dataOut:
		dataOut[outGroup] = {}
	dataOut[outGroup][realName] = """{{:System administrators/table/row
  | name = %s
  | link = %s
  | ircnick = %s
  | affiliation = %s
%s}}""" % (realName, link, ircnick, affiliation, groupWikitext)

for k, v in sorted(dataOut["ops"].items()) + sorted(dataOut["deployment"].items()) + sorted(dataOut["restricted"].items()):
	print(v.encode('utf-8'))

print('|}')
