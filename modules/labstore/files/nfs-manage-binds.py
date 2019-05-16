#!/usr/bin/python3
import argparse
import os
import logging
import sys
import subprocess
import yaml


def ensure_dir(dir, recurse=False):
    """ create directories on disk (or ensure they exist)
    :param dir: str
    :param recurse: bool
    """
    try:
        if not os.path.exists(dir):
            logging.info("mkdir %s" % dir)
        if recurse:
            os.makedirs(dir)
        else:
            os.mkdir(dir)
    except OSError:
        if not os.path.exists(dir):
            raise


def is_mount(path):
    """ confirm a path is a mountpoint
    :param src: str
    """
    try:
        cmd = ["/bin/findmnt", path]
        logging.debug(" ".join(cmd))
        with open(os.devnull, "w") as null:
            subprocess.check_call(["/bin/findmnt", path], stdout=null)
        return True
    except subprocess.CalledProcessError:
        return False


def bind_mount(src, dst):
    """ bind mount two paths on disk
    :param src: str
    :param dst: str
    """

    if is_mount(dst):
        logging.debug("%s is already a mountpoint" % src)
        return

    try:
        bind = ["/bin/mount", "--bind", src, dst]
        logging.debug(" ".join(bind))
        subprocess.check_call(bind)
    except subprocess.CalledProcessError:
        logging.error("bind mount %s %s failed" % (src, dst))


def create_binding(target, export, force=False, mounts=[]):
    """ manage bind state on disk (with possible inline creations)
    :param target: str
    :param export: str
    :param force: bool
    """

    ensure_dir(export, recurse=True)

    if force:
        ensure_dir(target)
        if "home" in mounts:
            ensure_dir("%s/home" % target)
        if "project" in mounts:
            ensure_dir("%s/project" % target)
    if os.path.exists(target):
        bind_mount(target, export)
    else:
        logging.warning("no bind on %s as %s does not exist" % (export, target))


def get_binds():
    """ find all bindmounts under /exp
    :note: we assume /exp is the root for exported binds
    :returns: list
    """

    cmd = ["/bin/findmnt", "-n", "-r", "-o", "target"]
    logging.debug(" ".join(cmd))
    mnt_targets = subprocess.check_output(cmd).decode()
    bind_mounts = []
    for mnt in mnt_targets.split():
        if mnt.startswith("/exp"):
            bind_mounts.append(mnt.strip())
    return bind_mounts


def main():

    argparser = argparse.ArgumentParser()

    argparser.add_argument(
        "-f",
        action="store_true",
        help="New project directories (not /exp directories) need -f to be created.",
    )

    argparser.add_argument(
        "-disk_path",
        default="/srv",
        help="Path on disk under which to setup the share tree",
    )

    argparser.add_argument(
        "-debug", help="Turn on debug logging", action="store_true"
    )

    argparser.add_argument(
        "-binds",
        help="Display active binds (this operation will exit post)",
        action="store_true",
    )

    args = argparser.parse_args()

    logging.basicConfig(
        format="%(asctime)s %(levelname)s %(message)s",
        level=logging.DEBUG if args.debug else logging.INFO,
    )

    if os.getuid() != 0:
        logging.error("Needs to be run as root")
        sys.exit(1)

    if args.f:
        logging.warning("forcing creation for new project directories")

    try:
        with open("/etc/nfs-mounts.yaml") as f:
            config = yaml.safe_load(f)
    except Exception:
        logging.exception(
            "Could not load projects config file from %s", args.config_path
        )
        sys.exit(1)

    if args.binds:
        binds = get_binds()
        if not binds:
            sys.exit(1)
        for b in binds:
            print(b)
        sys.exit(0)

    srv_root = args.disk_path
    # get dict of path_on_disk:share_name to create in descending order
    public_inverse = {v.split(" ")[0]: k for k, v in config["public"].items()}
    for k in sorted(public_inverse, key=len, reverse=False):
        path = k
        if public_inverse[k] == "root":
            exp_root = os.path.join("/", path)
            if not os.path.exists(exp_root):
                logging.error("The root export path does not exist")
                sys.exit(1)
            continue

        base = os.path.basename(path)
        exp = os.path.join(exp_root, base)
        srv = os.path.join(srv_root, base)
        create_binding(srv, exp, force=args.f)

    device_path_default = "/srv/misc"
    device_paths = {"tools": "/srv/tools", "maps": "/srv/maps"}

    for project in sorted(config["private"]):
        # Find which mounts should be made available for project
        # This is useful to create home and project dirs for new projects
        mount_config = config["private"][project].get("mounts", {})
        mounts = [mount for mount in mount_config.keys() if mount_config[mount]]

        srv_device = device_paths.get(project, device_path_default)
        srv = os.path.join(srv_device, "shared", project)
        exp = os.path.join("/exp/project", project)
        create_binding(srv, exp, force=args.f, mounts=mounts)


if __name__ == "__main__":
    main()
