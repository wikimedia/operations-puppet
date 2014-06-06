#!/usr/bin/python
#Find and replace utility for strings in files
import fileinput
import sys
import subprocess
import syslog
import socket

def replaceAll(file,searchExp,replaceExp):
    for line in fileinput.input(file, inplace=1):
        if searchExp in line:
            line = line.replace(searchExp,replaceExp)
        sys.stdout.write(line)

def get_files(exp):
    cmd = 'grep -ilR %s *' % (exp)
    pipe = subprocess.Popen(cmd, shell=True, stdout = subprocess.PIPE,stderr = subprocess.PIPE )
    (out, error) = pipe.communicate()
    pipe.wait()
    if error:
        raise CustomException(error)
    return out

old = sys.argv[1]
new = sys.argv[2]
list = filter(None, get_files(old).split())

try:
    list.remove('fixup.py')
except ValueError, e:
    print str(e)

print 'list', list

for i in list:
    replaceAll(i,old,new)
    print "%s renaming %s to %s" % (sys.argv[0], old, new)
