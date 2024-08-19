#! /usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
# -*- coding: utf-8 -*-

# This script detects the role for every server running in production and
# generates stats for all systems not running the latest OS(es) (it can temporarily
# be two ones if we e.g. test-drive a new Debian release before it's released as
# stable) as to when they are planned to be migrated, how many systems are affected
# and if any systems are behind plan. A report text file is generated.

# noqa: E128

import datetime
import dominate
import os
import sys
import yaml
import configparser
from collections import defaultdict
from pypuppetdb import connect
from dominate import tags as tags
from dominate.util import text


# The version of dominate we have in production doesn't have <main> yet
class main(tags.html_tag):
    pass


datetime_stamp = datetime.datetime.now().strftime("%Y-%m-%d")


def add_header():
    sre_mainpage = 'https://www.mediawiki.org/wiki/Wikimedia_Site_Reliability_Engineering'
    with tags.header().add(tags.div(cls='wm-container')):
        with tags.a(role='banner', href=sre_mainpage):
            tags.em('Wikimedia')
            text(' SRE')


def connect_puppetdb():
    return connect()


def get_servers_running_os(distro_release):
    pdb = connect_puppetdb()
    facts = pdb.facts('lsbdistcodename', distro_release)

    return [fact.node for fact in facts]


# Parse a YAML file with a list of role names which defines meta
# data for the services, e.g:
# role::foo
#  owner: Foo SREs (point of contact) (optional)
#  target-q: 2020-4 (target quarter by which this service will be
#                    fully migrated to the current OS(es)
#  phab-task: 123456 (reference to Phabricator) (optional)
def parse_yaml(yaml_file):
    try:
        with open(yaml_file, "r") as stream:
            yamlfile = yaml.safe_load(stream)

    except IOError:
        print("Error: Could not open {}".format(yaml_file))
        sys.exit(1)

    except yaml.scanner.ScannerError as e:
        print("Invalid YAML file:")
        print(e)
        sys.exit(1)

    return yamlfile


def get_current_quarter():
    today = datetime.datetime.now()

    return "{}-{}".format(today.year, (today.month-1)//3+1)


# Fetch all roles and return a dictionary of rolename[fqdn]
def get_roles():

    db = connect()
    pql = """
resources [tags, certname]{
    type = 'Class' and
    title ~ 'Role'
}
"""

    fqdns_roles = {}
    resources = db.pql(pql)
    for resource in resources:
        role = [r for r in resource['tags'] if r.startswith('role::')][0]
        fqdns_roles[resource['certname']] = role

    return fqdns_roles


# Returns True if the target quarter is within the current quarter or the future
# current_quarter, target_quarter are strings like "2020-3"
def quarter_in_plan(current_quarter, target_quarter):
    current_year = current_quarter.split("-")[0]
    current_quarter = current_quarter.split("-")[1]
    target_year = target_quarter.split("-")[0]
    target_quarter = target_quarter.split("-")[1]

    if current_year > target_year:
        return False

    elif current_year == target_year:
        if current_quarter > target_quarter:
            return False

    return True


def unroll_result_list(entries):
    return '\n'.join(sorted(entries))


def prepare_report(datafile, owners, roles, distro, hosts, uptodate_os,
                   target_dir, eol_date):
    status_log = []
    owners_to_contact_plan = defaultdict(set)
    owners_to_contact_delayed = defaultdict(set)
    hosts_needdata = []
    hosts_current_count = 0
    hosts_needplan_count = 0
    hosts_needdata_count = 0
    hosts_needowner_count = 0
    hosts_delayed_count = 0
    deprecated_count = 0
    need_owners = []
    role_count = defaultdict(int)

    distro_data = parse_yaml(datafile)
    current_quarter = get_current_quarter()

    targets = defaultdict(list)

    for current_distro in uptodate_os:
        hosts_current_count += len(get_servers_running_os(current_distro))

    deprecated_count = len(get_servers_running_os(distro))

    for host in hosts:

        if host not in roles:
            status_log.append("Malformed entry for {}, no role found".format(host))
            continue

        role = roles[host]
        role_count[role] += 1

        if not distro_data.get(role, None):
            hosts_needdata.append(host)
            hosts_needdata_count += 1
            continue

        if not owners.get(role, None):
            need_owners.append("{} running role {} has no defined owner".format(host, role))
            hosts_needowner_count += 1
            continue

        # On the Puppet/Hiera level a role can have multiple owners, but for tracking we only
        # use the primarily responsible team
        owner = owners.get(role)[0]

        target_quarter = distro_data.get(role, None).get('target-q', 'TBD')
        if target_quarter == 'TBD':
            owners_to_contact_plan[owner].add(role)
            hosts_needplan_count += 1
            continue

        targets[target_quarter].append((host, role))

        if not quarter_in_plan(current_quarter, target_quarter):
            owners_to_contact_delayed[owner].add(role)
            hosts_delayed_count += 1

    file_name = os.path.join(target_dir, 'os-report-{}-{}.html'.format(datetime_stamp, distro))

    with dominate.document(title='OS deprecation report for {}'.format(distro)) as html_report:
        with html_report.head:
            tags.link(rel='stylesheet', href='base.css')
        add_header()
        with main(role='main').add(tags.div(cls='wm-container')).add(tags.article()):
            tags.h1("Summary")
            with tags.div().add(tags.ul()):

                eol = datetime.datetime.fromisoformat(eol_date)
                today = datetime.datetime.now()

                if today > eol:
                    lapsed = (today-eol).days
                    tags.li("{} is behind designated EOL date by {} days".
                            format(distro, lapsed), cls="important")
                else:
                    remainder = (eol-today).days
                    tags.li("{} remaining days until {} reaches designated EOL date".
                            format(remainder, distro))

                tags.li("A total of {} hosts are running {}".format(deprecated_count, distro))
                tags.li("A total of {} hosts are running a more recent OS".
                        format(hosts_current_count))
                tags.li("A total of {} hosts are being migrated and lagging behind plan".
                        format(hosts_delayed_count))
                tags.li("A total of {} hosts need further migration data".
                        format(hosts_needdata_count))
                tags.li("A total of {} hosts don't have a designated migration date".
                        format(hosts_needplan_count))
                tags.li("A total of {} hosts don't have a designated owner".
                        format(hosts_needowner_count))

                todo_filename = 'os-report-todo-{}-{}.html'.format(datetime_stamp, distro)
                tags.li(tags.a("Per-team breakdown of open migrations for {}".format(distro),
                               href=todo_filename))

            if owners_to_contact_delayed:
                tags.h1("The following hosts are lagging behind the current migration plan",
                        cls="important")
                for owner in owners_to_contact_delayed:
                    tags.h2(owner)
                    with tags.div().add(tags.ul()):
                        for service in owners_to_contact_delayed[owner]:
                            tags.li("  {} ({} host(s))\n".format(service, role_count[service]))
            else:
                tags.h1("No migration is delayed")

            if owners_to_contact_plan:
                tags.h1("The following roles are missing a migration date", cls="important")
                for owner in owners_to_contact_plan:
                    tags.h2(owner)
                    with tags.div().add(tags.ul()):
                        for service in owners_to_contact_plan[owner]:
                            tags.li("  {} ({} host(s))\n".format(service, role_count[service]))

            else:
                tags.h1("All roles are covered with a migration date")

            tags.h1("These hosts don't have owner information attached", cls="important")
            with tags.div(id='header').add(tags.ul()):
                for i in need_owners:
                    tags.li(i)

            if hosts_needdata:
                tags.h1("The following hosts are missing in the migration data", cls="important")
                with tags.div().add(tags.ul()):
                    for i in hosts_needdata:
                        tags.li(i)
            else:
                tags.h1("All hosts are covered by existing migration data")

            if status_log:
                tags.h1("The following errors were reported (malformed data)", cls="important")
                with tags.div().add(tags.ul()):
                    for i in status_log:
                        tags.li(i)
            else:
                tags.h1("No errors were reported in the data files")

    with open(file_name, 'w') as report_html:
        report_html.write(html_report.render())

    latest = os.path.join(target_dir, '{}.html'.format(distro))
    with open(latest, 'w') as latest_html:
        latest_html.write(html_report.render())


def prepare_todo_report(owners, roles, hosts, distro, target_dir):
    hosts_todo = defaultdict(list)

    for host in hosts:

        if host not in roles:
            # Hosts without a role are flagged in the central report
            continue

        role = roles[host]
        # Roles without an owner are flagged in the central report
        if owners.get(role, None):
            # On the Puppet/Hiera level a role can have multiple owners, but for tracking we only
            # use the primarily responsible team
            owner = owners.get(role)[0]

        hosts_todo[owner].append(host)

    with dominate.document(title='Per-team breakdown of open migrations for {}'.
                           format(distro)) as html_report:
        with html_report.head:
            tags.link(rel='stylesheet', href='base.css')
        add_header()
        with main(role='main').add(tags.div(cls='wm-container')).add(tags.article()):
            tags.h1("Per-SRE team breakdown of open migrations for {}".format(distro),
                    href='os-report-todo-{}-{}.html'.format(datetime_stamp, distro))

            for team in hosts_todo:
                if hosts_todo[team]:
                    tags.h2("The following hosts need to be migrated by {} ({} in total)".
                            format(team, len(hosts_todo[team])), cls="important")
                    with tags.div().add(tags.ul()):
                        for host in sorted(hosts_todo[team]):
                            tags.ol("{}".format(host))
                else:
                    tags.h2("No hosts need to be migrated by SRE sub team {}".format(team))

    file_name = os.path.join(target_dir, 'os-report-todo-{}-{}.html'.format(datetime_stamp, distro))
    with open(file_name, 'w') as report_html:
        report_html.write(html_report.render())


def prepare_overview(distros, target_dir):
    with dominate.document(title='OS deprecation reports') as overview_report:
        with overview_report.head:
            tags.link(rel='stylesheet', href='base.css')
        add_header()
        with main(role='main').add(tags.div(cls='wm-container')).add(tags.article()):
            tags.h1("Overview of OS reports")

            for distro in distros:
                tags.a(distro, href="{}.html".format(distro))

    overview_file = os.path.join(target_dir, "index.html")
    with open(overview_file, 'w') as overview_html:
        overview_html.write(overview_report.render())


def main_function():
    cfg = configparser.ConfigParser()
    cfg.read("/etc/wikimedia/os-updates/os-updates-tracking.cfg")
    sections = cfg.sections()
    distros = []

    if 'general' not in sections:
        print("Malformed config file, no [general] section found")
        sys.exit(1)

    if 'owners' not in cfg.options('general'):
        print("Malformed config file, no owners file configured")
        sys.exit(1)

    if 'target_directory' not in cfg.options('general'):
        print("Malformed config file, target directory specified")
        sys.exit(1)

    owners = parse_yaml(cfg.get('general', 'owners'))

    if 'additional-owners' in cfg.options('general'):
        owners.update(parse_yaml(cfg.get('general', 'additional-owners')))

    for distro in sections:
        if distro == 'general':
            continue

        if 'end-of-life' not in cfg.options(distro):
            print("Malformed config file, no end of life quarter configured")
            sys.exit(1)

        if 'datafile' not in cfg.options(distro):
            print("Malformed config file, no YAML file with target dates configured")
            sys.exit(1)

        if not os.path.exists(cfg.get(distro, 'datafile')):
            print("Malformed config file, no YAML file with target dates configured")
            sys.exit(1)

        if 'current' not in cfg.options(distro):
            print("Malformed config file, no current distros specified")
            sys.exit(1)

        uptodate_os = [i.strip() for i in cfg.get(distro, 'current').split(",")]

        target_directory = cfg.get('general', 'target_directory')
        roles = get_roles()
        hosts = get_servers_running_os(distro)

        prepare_report(cfg.get(distro, 'datafile'),
                       owners,
                       roles,
                       distro,
                       hosts,
                       uptodate_os,
                       target_directory,
                       cfg.get(distro, 'end-of-life'),
                       )
        distros.append(distro)

        if distro not in uptodate_os:
            prepare_todo_report(owners,
                                roles,
                                hosts,
                                distro,
                                target_directory,
                                )

    prepare_overview(distros, cfg.get('general', 'target_directory'))
    sys.exit(0)


if __name__ == '__main__':
    main_function()
