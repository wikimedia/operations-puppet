#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse

import json
import os
import pathlib
import subprocess


def block_dev_dict():
    jsonblocks = subprocess.getoutput(
        "/bin/lsblk --json -o NAME,FSTYPE,MOUNTPOINT,UUID"
    )
    blockdict = json.loads(jsonblocks)
    annotateddict = {}
    for dev in blockdict["blockdevices"]:
        dev["canformat"] = True
        dev["canmount"] = True
        dev["caption"] = "new volume, will be formatted before mounting"

        if dev.get("mountpoint", ""):
            dev["canmount"] = False
            dev["canformat"] = False
            dev["caption"] = " (already mounted)"
        elif dev["name"] == "vda" or dev["name"] == "sda":
            dev["canmount"] = False
            dev["canformat"] = False
            dev["caption"] = " (the primary volume containing /)"
        elif "children" in dev:
            dev["canmount"] = False
            dev["canformat"] = False
            dev["caption"] = "already partitioned"
        elif "fstype" in dev and dev["fstype"] is not None:
            dev["canformat"] = False
            dev["caption"] = "formatted as %s, can be mounted" % dev["fstype"]

        annotateddict[dev["name"]] = dev

    return annotateddict


def devs_string(devdict):
    rstring = ""
    for name, dev in devdict.items():
        rstring += "    %s: %s\n" % (name, dev["caption"])

    return rstring


def validate_mountpoint(devdict, mountpoint, force=False):
    for dev in devdict.values():
        if "mountpoint" in dev and dev["mountpoint"] == mountpoint:
            print("Mount point %s already assigned to %s" % (mountpoint, dev["name"]))
            return False
        for child in dev.get("children", []):
            if "mountpoint" in child and child["mountpoint"] == mountpoint:
                print(
                    "Mount point %s already assigned to %s"
                    % (mountpoint, child["name"])
                )
                return False

    with open("/etc/fstab") as fstab:
        for _cnt, line in enumerate(fstab):
            if len(line.split()) > 1 and line.split()[1] == mountpoint:
                print(
                    "Mountpoint %s appears in /etc/fstab:\n\n"
                    "%s\n\nYou will need to use a different mountpoint "
                    "or edit /etc/fstab by hand before using this script."
                    % (mountpoint, line)
                )
                return False

    if os.path.isdir(mountpoint) and os.listdir(mountpoint) and not force:
        print(
            "Mount point %s already contains files. Continuing "
            "would hide those files.\nSelect a different mountpoint or "
            "remove those files by hand.\n" % mountpoint
        )
        return False

    return True


def get_args(devdict, args):
    print("This tool will partition, format, and mount a block storage device.\n\n")

    dev_choices = [dev["name"] for dev in devdict.values() if dev["canmount"]]

    print("Attached storage devices:\n\n%s" % devs_string(devdict))

    while not args.device:
        if len(dev_choices) == 1:
            print(
                "The only block device device available to mount is %s.  Selecting.\n"
                % dev_choices[0]
            )
            args.device = dev_choices[0]
            break

        dev = input("What device would you like to mount? <%s> " % dev_choices[0])
        if not dev:
            dev = dev_choices[0]
        if dev in dev_choices:
            args.device = dev
        else:
            print("Must be one of: %s" % ", ".join(dev_choices))

    while not args.mountpoint:
        mountpoint = input("Where would you like to mount it? </srv> ")
        if not mountpoint:
            mountpoint = "/srv"
        if not mountpoint.startswith("/"):
            print('Please specify an absolute path beginning with / (e.g. "/srv")')
        else:
            if validate_mountpoint(devdict, mountpoint):
                args.mountpoint = mountpoint

    confirm = input(
        "Ready to prepare and mount %s on %s. OK to continue? <Y|n>"
        % (args.device, args.mountpoint)
    )
    if confirm and not confirm.lower().startswith("y"):
        exit("Cancelled!")

    return args


def format_volume(args):
    devpath = "/dev/%s" % args.device

    # Filesystem
    print("Formatting as ext4...")
    subprocess.run(["mkfs.ext4", devpath])
    print("Done.")


def mount_volume(args):
    devpath = "/dev/%s" % args.device

    # Ensure mountpoint exists
    pathlib.Path(args.mountpoint).mkdir(parents=True, exist_ok=True)

    # Set mode. We can't use the 'mode' arg in mkdir because that's combined with
    #  the current umask.
    octalmode = int(args.mountmode, 8)
    os.chmod(args.mountpoint, octalmode)

    if args.device.startswith("sd") and "discard" not in args.options:
        # We're using scsi drivers and can set discard in mount options
        mount_options = "discard,%s" % args.options
    else:
        mount_options = args.options

    print("Mounting on %s..." % args.mountpoint)
    subprocess.run(["mount", "-o", mount_options, devpath, args.mountpoint])
    # readjust the permissions
    os.chmod(args.mountpoint, octalmode)

    updated_devdict = block_dev_dict()
    uuid = updated_devdict[args.device]["uuid"]

    fstabline = "UUID=%s %s %s %s 0 2\n" % (
        uuid,
        args.mountpoint,
        updated_devdict[args.device]["fstype"],
        mount_options,
    )
    print("Updating fstab with %s..." % fstabline)
    with open("/etc/fstab", "a") as myfile:
        myfile.write(fstabline)

    print("Done.")


if __name__ == "__main__":
    if os.geteuid() != 0:
        exit(
            "You need to have root privileges to run this script.\n"
            "Please try again, this time using 'sudo'.\n"
        )

    devdict = block_dev_dict()

    parser = argparse.ArgumentParser(
        description="Partition, format, and mount a block device",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    dev_choices = [dev["name"] for dev in devdict.values() if dev["canmount"]]
    if not dev_choices:
        exit(
            "%s\nNo block devices are available to format or mount.\n"
            "To start, create and attach a volume with Horizon.\n"
            % devs_string(devdict)
        )

    parser.add_argument(
        "--device", choices=dev_choices, help="which device to format and mount"
    )
    parser.add_argument(
        "--options",
        default="nofail,x-systemd.device-timeout=2s",
        help="Mount options.  Should be a single comma-delimited string. "
        "If scsi drivers are enabled, 'discard' will always be included "
        "to reduce Ceph usage.",
    )
    parser.add_argument(
        "--mountmode",
        default="755",
        help="Mount mode: a string containing the octal mode",
    )
    parser.add_argument("--mountpoint", help="Where to  mount the volume, e.g. /srv")
    parser.add_argument(
        "--force", action="store_true", help="Run without user interaction"
    )
    args = parser.parse_args()

    if args.force:
        if not args.device or not args.mountpoint:
            exit("In noninteractive mode you must specify --device and --mountpoint")
        if not validate_mountpoint(devdict, args.mountpoint, args.force):
            exit("Invalid mountpoint")
    else:
        args = get_args(devdict, args)

    if devdict[args.device]["canformat"]:
        format_volume(args)

    mount_volume(args)
