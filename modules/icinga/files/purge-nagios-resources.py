#!/usr/bin/python

# Script that purges Nagios resources for which the corresponding host entry
# does not exist.

# Written on 2010/08/14 by Mark Bergsma <mark@wikimedia.org>

import os
import os.path
import sys
import tempfile


def readHostsFile(path):
    hosts = set([])

    inDefinition = False
    for line in file(path, 'r'):
        line = line.strip()
        if not inDefinition and line.startswith("define host"):
            inDefinition = True
        elif inDefinition and line.startswith("}"):
            inDefinition = False
        elif inDefinition and line.startswith("host_name"):
            hosts.add(line.split(None, 2)[1])

    return hosts


def filterServices(sourcePath, newFile, hosts):
    inDefinition = False
    purgeResource = False
    buffer = []

    for line in file(sourcePath, 'r'):
        strippedLine = line.strip()

        if not inDefinition and strippedLine.startswith("define "):
            inDefinition = True

        if inDefinition:
            buffer.append(line)
            if strippedLine.startswith("}"):
                inDefinition = False
                if purgeResource:
                    # Comment out
                    buffer = ['#' + l for l in buffer]
                newFile.writelines(buffer)
                buffer = []
                purgeResource = False
            elif strippedLine.startswith("host_name"):
                purgeResource = (strippedLine.split(None, 2)[1] not in hosts)
        else:
            newFile.write(line)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print "\n\tUsage:\n\t\t%s <hosts.cfg> <resources1.cfg> [ <resources2.cfg> ... ]\n" % sys.argv[0]
        sys.exit(0)

    hosts = readHostsFile(sys.argv[1])
    for resourcesPath in sys.argv[2:]:
        tmpfile = tempfile.NamedTemporaryFile(mode='w', dir=os.path.split(resourcesPath)[0])
        filterServices(resourcesPath, tmpfile, hosts)
        os.chmod(tmpfile.name, os.stat(resourcesPath).st_mode)
        os.rename(tmpfile.name, resourcesPath)
        try:
            # Will try to delete the file, which no longer exists
            tmpfile.close()
        except OSError:
            pass
