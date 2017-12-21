#! /usr/bin/python3
# -*- coding: utf-8 -*-

import subprocess
import sys
import argparse
import os
import logging

if os.geteuid() != 0:
    print("Needs to be run as root")
    sys.exit(1)

logging.basicConfig(filename='/var/log/wmf-auto-restarts.log',
                    format='%(levelname)s: %(asctime)s : %(message)s',
                    level=logging.INFO)

logger = logging.getLogger('servicerestart')


def check_restart(service_name, dry_run):
    false_positives = ['/dev/zero']

    try:
        del_files = subprocess.check_output(["/usr/bin/lsof", "+c", "15", "-nXd", "DEL"],
                                            universal_newlines=True)
    except subprocess.CalledProcessError as e:
        logger.info("Could not query the PID of " + service_name, e.returncode)

    logger.debug("All references to deleted files: " + del_files)

    try:
        rc = subprocess.call(["/bin/systemctl", "is-active", service_name],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError as e:
        logger.info("Could not query the status of " + service_name, e.returncode)

    logger.debug("systemctl is-active check returnd " + str(rc))

    if rc:
        logger.info("Service " + service_name + " not present or not running")
        return 1

    try:
        pid_query = subprocess.check_output(["/bin/systemctl", "show", "-p", "MainPID",
                                             service_name], universal_newlines=True)
    except subprocess.CalledProcessError as e:
        logger.info("Could not query the PID of " + service_name, e.returncode)
        return 1

    logger.debug("pid query for MainPID returned " + pid_query)

    detect_service_pid = str(pid_query.strip()).split("=")[1]

    if detect_service_pid == "0":  # Service using legacy init script and systemd-sysv-generator
        pid_query = subprocess.check_output(["/bin/pidof", service_name], universal_newlines=True)
        service_pids = pid_query.split()
        native_systemd_unit = False
    else:
        native_systemd_unit = True
        service_pids = [detect_service_pid]

    logger.debug("service pids " + str(service_pids))

    restart_needed = False
    for line in del_files.splitlines():
        cols = line.split()
        try:
            if len(cols) == 8:
                command, pid, filename = [cols[x] for x in (0, 1, 7)]
                if filename in false_positives:
                    continue

                if pid in service_pids:
                    restart_needed = True
                    logger.info("Detected necessary restart for service " + service_name +
                                " (" + pid + ")")
                    if not native_systemd_unit:
                        logger.info("Service " + service_name +
                                    " uses a legacy sysvinit script, consider using a systemd unit")

                    if dry_run:
                        logger.info("Skipping restart since --dry-run was specified")
                    else:
                        cmd = ["/bin/systemctl", "restart", service_name]
                        try:
                            restart_output = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
                            logger.info("Restarted service " + service_name)
                            if restart_output:
                                logger.info(restart_output)
                        except subprocess.CalledProcessError as e:
                            logger.error("Failed to restart service " + service_name + ":")
                            logger.error(e.output)
                            return 1

        except ValueError:
            logger.error("Malformed line in lsof output:")
            logger.error(line)
            continue

    if not restart_needed:
        logger.info("No restart necessary for service " + service_name)

    return 0


def main():
    if not os.path.exists('/bin/pidof'):
        logger.error("pidof not found")
        return 1

    if not os.path.exists('/usr/bin/lsof'):
        logger.error("lsof not found")
        return 1

    if not os.path.exists('/bin/systemctl'):
        logger.error("systemctl not found")
        return 1

    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--servicename',
                        help='The name of the service for which a restart should be tested',
                        required=True)
    parser.add_argument('--dry-run', action='store_true', dest="dryrun", default=False,
                        help='Do not actually restart, only print a message')
    parser.add_argument('-d', '--debug', action='store_true',
                        help='Enable debug logging')
    args = parser.parse_args()

    if args.debug:
        logger.setLevel(logging.DEBUG)

    return check_restart(args.servicename, args.dryrun)


if __name__ == "__main__":
    sys.exit(main())
