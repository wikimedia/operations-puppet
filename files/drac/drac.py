#!/usr/bin/python

import sys
import re
import getpass
import paramiko
import socket

from optparse import OptionParser

def main():
    parser = OptionParser(conflict_handler="resolve")
    parser.set_usage("drac [options] <server>")
    parser.add_option("-p", action="store_true", dest="changepassword", help="Change the DRAC password")
    parser.add_option("--passwordfile", dest="passwordfile", help="Read current password from the specified file")
    parser.add_option("--newpasswordfile", dest="newpasswordfile", help="Read new password from the specified file")
    parser.add_option("--action", dest="action", help="Run the specified server action via the DRAC")
    parser.add_option("--getmacfornic", dest="nicnumber", help="Get the MAC for the given NIC number (1, 2, 3, etc.)")
    (options, args) = parser.parse_args()
    server = args[0]
    username = "root"
    if options.passwordfile:
        f = open(options.passwordfile)
        password = (f.read()).strip()
    else:
        password = getpass.getpass("Password: ")
    if options.changepassword:
        if options.newpasswordfile:
            f = open(options.newpasswordfile)
            newpassword = (f.read()).strip()
        else:
            while True:
                newpassword = getpass.getpass("New Password: ")
                retrypassword = getpass.getpass("Repeat New Password: ")
                if newpassword == retrypassword:
                    break
                else:
                    print "Passwords didn't match, please try again."
        command = "racadm config -g cfgUserAdmin -o cfgUserAdminPassword -i 2 %s" % (newpassword)
        output = run_command(server, username, password, command)
        if output:
            for line in output:
                line = line.strip()
                print line
            print "Successfully changed password for %s" % (server)
            sys.exit(0)
        else:
            print "Failed to change password for %s" % (server)
            sys.exit(1)
    if options.action:
        command = "racadm serveraction %s" % (options.action)
        output = run_command(server, username, password, command)
        if output:
            for line in output:
                line = line.strip()
                print line
            print "Successfully ran %s on %s" % (options.action, server)
            sys.exit(0)
        else:
            print "Failed to run %s on %s" % (options.action, server)
            sys.exit(1)
    if options.nicnumber:
        command = "racadm getsysinfo"
        output = run_command(server, username, password, command)
        if output:
            for line in output:
                linearr = line.split('=')
                if len(linearr) > 1:
                    nic = linearr[0]
                    mac = linearr[1]
                    if re.search('^NIC', nic) and (nic.strip().split()[0][3] == options.nicnumber):
                        print mac.strip()
                        sys.exit(0)
            # We didn't find a NIC, this is an error
            sys.exit(1)
        else:
            # We didn't get any output, this is an error
            sys.exit(1)

def run_command(server, username, password, command):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            ssh.connect(server, username=username, password=password)
        except (paramiko.SSHException, socket.error):
            print "Failed to connect to %s." % server
            return
        stdin, stdout, stderr = ssh.exec_command(command)
        return stdout.readlines()
    except Exception:
        print "Couldn't connect to %s" % (server)
        return

if __name__ == "__main__":
    main()
