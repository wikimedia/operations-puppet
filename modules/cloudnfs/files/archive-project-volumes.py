#!/usr/bin/python3

#####################################################################
# THIS FILE IS MANAGED BY PUPPET
# puppet:///modules/labstore/archive-project-volumes
#####################################################################
"""
 Sometimes labs projects are deleted.  When this happens,
 orphaned volumes are left on the nfs server.

 The complete list of active volumes is stored in a yaml file,
 /etc/nfs-mounts.yaml.

 This script will explicitly archive a volume if specified.
 Otherwise it compares nfs-mounts.yaml with with the actually
 present project volumes to generate a list of orphans.

 In either case, it then makes a tarball of each orphaned
 volume, sets it aside, and removes the original.

 The general rule of thumb is that archives can be removed after
 6 months; this script leaves them there forever.
"""

import logging
import os
import shutil
import subprocess
from optparse import OptionParser

import yaml


class VolumeArchiver:
    def __init__(self):
        self.base_dir = '/srv/others/'
        self.active_volumes_file = '/etc/nfs-mounts.yaml'
        self.archive_dir = os.path.join(self.base_dir, 'orphan-volumes')

    def archive(self, volpath):
        if not os.path.isdir(self.base_dir):
            logging.error("Unable to locate %s" % self.base_dir)
            return False

        if not os.path.isdir(volpath):
            logging.error("Unable to locate %s" % volpath)
            return False

        if not os.path.isdir(self.archive_dir):
            os.mkdir(self.archive_dir)

        volname = os.path.basename(volpath)

        n = 0
        maxn = 200
        archivepath = os.path.join(self.archive_dir, "%s.tgz" % volname)
        while os.path.isfile(archivepath):
            archivepath = os.path.join(self.archive_dir, "%s-%s.tgz" %
                                       (volname, str(n)))
            n += 1
            if (n > maxn):
                logging.error("Something terrible is happening. "
                              "We have more than %s archives for "
                              " a volume named %s." % (str(maxn), volname))
                return False

        args = ['tar', '-cpzf', archivepath, volname]
        rval = subprocess.call(args, cwd=self.base_dir)
        if rval:
            logging.info("Failed to archive %s with exit code %s. "
                         "Command was: %s" % (volpath, rval, ' '.join(args)))
            return False
        else:
            logging.info("Archived %s to %s" % (volpath, archivepath))

        logging.info("Archive complete; removing %s" % volpath)
        shutil.rmtree(volpath)

        return True

    def run(self):
        parser = OptionParser(conflict_handler="resolve")
        parser.set_usage('archive-project-volumes [options]')

        parser.add_option("--logfile", dest="logfile",
                          help="Write output to the specified log file. "
                               "(default: stdout)")

        parser.add_option("--volume", dest="volume",
                          help="Volume to archive (default: all orphans)")
        (options, args) = parser.parse_args()

        if options.logfile:
            logging.basicConfig(filename=options.logfile, level=logging.DEBUG)
        else:
            logging.basicConfig(level=logging.DEBUG)

        if options.volume:
            vol_list = [options.volume]
        else:
            with open(self.active_volumes_file, 'r') as f:
                y = yaml.safe_load(f)
                projects_in_yaml = y['private']

                projects_on_disk = os.listdir(self.base_dir)
                vol_list = [vol for vol in projects_on_disk if vol not in
                            list(projects_in_yaml.keys())]

        for volname in vol_list:
            vol = os.path.join(self.base_dir, volname)
            # Exclude things that are clearly not project volumes
            if not os.path.isdir(vol):
                continue
            if volname == "lost+found":
                continue
            if volname == "orphan-volumes":
                continue
            # And, just to be safe... make sure it's empty
            # or has a 'home' or 'project' subdir

            if (not os.path.isdir(vol)):
                logging.error("Volume directory %s not found. " % vol)
                return 1

            if (os.path.isdir(os.path.join(vol, 'home'))
                    or os.path.isdir(os.path.join(vol, 'project'))
                    or not os.listdir(vol)):
                logging.info("Archiving %s" % vol)
                if not self.archive(vol):
                    logging.error("Archive failed, giving up.")

        return 0


def main():
    archiver = VolumeArchiver()
    archiver.run()


if __name__ == "__main__":
    main()
