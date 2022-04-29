#!/usr/bin/python3
'''A conftool discovery discrepancy script'''

import json
import os
import sys

from itertools import filterfalse

# Icinga returns
OK = 0
WARNING = 1
CRITICAL = 2  # Will not be used, but let's be pedantic
UNKNOWN = 3

# Generated with:
# confctl --object-type=discovery select  'tags=.*' get |
# jq --slurp --compact-output '.' |
# python3 -c 'import json, sys; print(json.load(sys.stdin))'
# TODO: Figure out how to obtain this in a better way

DESIRED_STATE = [
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=aqs'},
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=jobrunner'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=jobrunner'},
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=kibana'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=kibana'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=ores'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=ores'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=thumbor'},
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=thumbor'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=eventgate-analytics'},  # noqa
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=eventgate-analytics'},  # noqa
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=logstash'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=cxserver'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=cxserver'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=eventgate-logging-external'},  # noqa
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=eventgate-logging-external'},  # noqa
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=restbase-backend'},
    {'eqiad': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=restbase-backend'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=wikifeeds'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=wikifeeds'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=api-ro'},
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=api-ro'},
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=appservers-rw'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=appservers-rw'},
    # Eventgate-main codfw is currently depooled for https://phabricator.wikimedia.org/T285710
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=eventgate-main'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=eventgate-main'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=restbase-async'},
    {'eqiad': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=restbase-async'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=citoid'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=citoid'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=mathoid'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=mathoid'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=mobileapps'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=mobileapps'},
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=videoscaler'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=videoscaler'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=blubberoid'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=blubberoid'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=wdqs-internal'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=wdqs-internal'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=apertium'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=apertium'},
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=api-rw'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=api-rw'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=echostore'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=echostore'},
    # kartotherian is disabled in codfw temporarily as part of tegola rollout T280767
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=kartotherian'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=kartotherian'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=proton'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=proton'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=schema'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=schema'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=swift'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=swift'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=wdqs'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=wdqs'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=wcqs'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=wcqs'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=sessionstore'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=sessionstore'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=swift-ro'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=swift-ro'},
    # Due to swift replication lag, docker-registry is codfw-only.
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=docker-registry'},
    {'eqiad': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=docker-registry'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=eventstreams'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=eventstreams'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=eventstreams-internal'},  # noqa
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=eventstreams-internal'},  # noqa
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=recommendation-api'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=recommendation-api'},  # noqa
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=termbox'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=termbox'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=search'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=search'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=zotero'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=zotero'},
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=appservers-ro'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=appservers-ro'},
    # TODO: is druid-public-broker needed?
    {'eqiad': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=druid-public-broker'},  # noqa
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=parsoid-php'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=parsoid-php'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=restbase'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=restbase'},
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=swift-rw'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=swift-rw'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=eventgate-analytics-external'},  # noqa
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=eventgate-analytics-external'},  # noqa
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=thanos-query'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=thanos-query'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=thanos-swift'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=thanos-swift'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=helm-charts'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=helm-charts'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=push-notifications'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=push-notifications'},  # noqa
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=releases'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=releases'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=api-gateway'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=api-gateway'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=similar-users'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=similar-users'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=shellbox'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=shellbox'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=shellbox-constraints'},  # noqa
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=shellbox-constraints'},  # noqa
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=linkrecommendation'},  # noqa
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=linkrecommendation'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=puppetdb-api'},
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=puppetdb-api'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=mwdebug'},
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=mwdebug'},
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=k8s-ingress-staging'},  # noqa
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=k8s-ingress-staging'},  # noqa
    {'codfw': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=k8s-ingress-wikikube-ro'},  # noqa
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=k8s-ingress-wikikube-ro'},  # noqa
    {'codfw': {'pooled': False, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=k8s-ingress-wikikube-rw'},  # noqa
    {'eqiad': {'pooled': True, 'references': [], 'ttl': 300}, 'tags': 'dnsdisc=k8s-ingress-wikikube-rw'},  # noqa
]


def fetch_current_state():
    ''' Fetch the current state from conftool '''

    cmd = "confctl --object-type=discovery select 'tags=.*' get"
    output = os.popen(cmd).readlines()
    return [json.loads(line) for line in output]


def diff_states(a, b):
    '''Diff 2 arbitrary conftool states'''

    return list(map(str, filterfalse(lambda x: x in b, a)))


def main():
    '''Main function'''

    current_state = fetch_current_state()

    # First, let's see if all desired things are set
    diff = diff_states(DESIRED_STATE, current_state)
    if diff:
        msg = ('Desired/Current discovery state differ\n'
               'The following objects are not in their desired state:\n\t{}\n'
               'You can safely ignore if this is planned').format('\n\t'.join(diff))
        print(msg)
        # Bail out, no need to see if the current state is richer.
        sys.exit(WARNING)
    # Then, let's see if current state has new objects that haven't been added
    # to the check
    diff = diff_states(current_state, DESIRED_STATE)
    if diff:
        msg = ('Desired/Current discovery state differ\n'
               'The following objects do not have a desired state:\n\t{}\n'
               'Update the config of this script').format('\n\t'.join(diff))
        print(msg + '\nDO NOT ACK THIS\n')
        sys.exit(WARNING)
    print('No discrepancies')


if __name__ == '__main__':
    main()
