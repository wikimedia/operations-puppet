#!/usr/bin/python
"""
2016 Andrew Bogott

Miscellaneous keystone state monitoring:

- Ensure that certain utility projects ('admin,' 'observer')
  exist

- Make sure that all projects have their name == their id.  Various
  of our tools depend on this, but if projects are created out of
  band (e.g. via a direct commandline action) a uuid might be assigned
  instead, which can cause bad things

"""
import sys
import mwopenstackclients

OK = 0
WARNING = 1
CRITICAL = 2
UNKNOWN = 3


def main():
    clients = mwopenstackclients.clients('/etc/novaobserver.yaml')
    allprojects = clients.allprojects()
    allprojectslist = [project.name for project in allprojects]

    requiredprojects = ['admin', 'observer']
    for project in requiredprojects:
        if project not in allprojectslist:
            print("%s project missing from Keystone." % project)
            sys.exit(WARNING)

    for project in allprojects:
        if project.id != project.name:
            print("Keystone project with name %s has mismatched key %s" %
                  (project.name, project.id))
            sys.exit(WARNING)

    print "Keystone projects exist and have matching names and ids."
    sys.exit(OK)

if __name__ == '__main__':
    main()
