# Generates the table at
# https://meta.wikimedia.org/wiki/System_administrators#List
# Alex Monk, April 2015

from __future__ import print_function
from bs4 import BeautifulSoup
import json
import yaml

try:
    from urllib import request as urllib
except:
    import urllib2 as urllib

parsoidUrl = "https://meta.wikimedia.org/api/rest_v1" + \
             "/page/html/System_administrators"
bs = BeautifulSoup(urllib.urlopen(parsoidUrl).read())
oldUserData = {}
for tr in bs.find_all('tr')[2:]:
    if not tr.get('data-mw'):
        continue
    for part in json.loads(tr.get('data-mw'))['parts']:
        if 'template' not in part:
            continue
        params = part['template']['params']
        oldUserData[params['name']['wt']] = {
            'ircnick': params['ircnick']['wt'],
            'link': params['link']['wt'],
            'affiliation': params['affiliation']['wt']
        }

d = yaml.safe_load(open("../data/data.yaml").read())
groups = {}

for groupName, groupData in d['groups'].items():
    groups[groupName] = groupData['members']

sysadmins = groups['ops'] + groups['deployment'] + groups['restricted']

defaultHeader = "{{MediaWiki:Group-sysadmin{{#translation:}}}}"
print(
    "{| class=\"wikitable plainlinks sortable\" " +
    "style=\"margin-left: auto; margin-right: auto;\"\n" +
    "|+ style=\"font-size: larger; font-weight: bold;\" | " +
    "{{{System administrators|" + defaultHeader + "}}}" +
    """
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
    if userName in groups['absent'] or userData['ensure'] == 'absent':
        continue
    if len(userData['ssh_keys']) == 0 or userName not in sysadmins:
        continue
    realName = userData['realname']
    link, ircnick, affiliation, groupWikitext = '', '', '', ''
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

ops = sorted(dataOut["ops"].items())
deployers = sorted(dataOut["deployment"].items())
restricted = sorted(dataOut["restricted"].items())

for k, v in ops + deployers + restricted:
    print(v)

print('|}')
