#!/usr/bin/python

"""
2016 Andrew Bogott

Check that a given keystone project has a specific set
of roles in all projects.

If a project has no roles at all (presumably due to the
project being created out-of-band) raise a warning.

If a project has the wrong roles, return critical.  This
is a possible security issue as a read-only account (novaobserver)
might have actual user or projectadmin roles.

Example for user 'novaadmin' and roles 'projectadmin' and 'user':

check_keystone_roles novaadmin projectadmin user

"""
import argparse
import sys

import mwopenstackclients

SpecialProjects = ['admin', 'wmflabsdotorg']

OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3


def check_roles(user, requiredroles, all_projects=True):
    clients = mwopenstackclients.clients('/etc/novaobserver.yaml')
    keystoneclient = clients.keystoneclient()

    # test observer roles
    roledict = {role.name: role.id for role in keystoneclient.roles.list()}
    roledictdecode = {role.id: role.name
                      for role in keystoneclient.roles.list()}
    requiredset = set()
    for role in requiredroles:
        requiredset.add(roledict[role])

    assignments = keystoneclient.role_assignments.list(user=user)

    assignmentdict = {}
    for assignment in assignments:
        project = assignment.scope['project']['id']
        if project not in assignmentdict:
            assignmentdict[project] = set()
        assignmentdict[project].add(assignment.role['id'])

    for project in assignmentdict:
        if project in SpecialProjects:
            continue
        if assignmentdict[project] != requiredset:
            # Make a human-readable list of role names for reporting purposes
            namelist = [roledictdecode[roleid]
                        for roleid in assignmentdict[project]]

            rstring = ("In %s, user %s should have roles %s but has %s" %
                       (project, user, requiredroles, namelist))
            return (CRITICAL, rstring)

    if all_projects:
        allprojects = clients.allprojects()
        allprojectslist = [project.name for project in allprojects]

        # these will always be weird; don't check them
        for project in SpecialProjects:
            allprojectslist.remove(project)

        leftovers = set(allprojectslist) - set(assignmentdict.keys())
        if leftovers:
            rstring = ("Roles for %s are not set in these projects: %s" %
                       (user, leftovers))
            return (WARNING, rstring)

    rstring = ("%s has the correct roles in all projects." % user)
    return (OK, rstring)


def handle_args():
    parser = argparse.ArgumentParser(
        description='Check keystone roles in all projects')
    parser.add_argument(
        'user',
        help='User id to check',
        action='store')
    parser.add_argument(
        'requiredroles',
        nargs='+',
        help='List of roles required for user',
        action='store')
    args = parser.parse_args()
    return vars(args)


def main():
    args = handle_args()
    user = args['user']
    required_roles = args['requiredroles']

    state, text = check_roles(user, required_roles)

    print text
    sys.exit(state)


if __name__ == '__main__':
    main()
