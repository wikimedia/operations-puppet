#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0

import argparse
import rados
import rbd
import uuid


def recursive_delete(image_name: str, rbd_inst: rbd.RBD, ioctx: rados.Ioctx):
    print("recursively deleting image %s" % image_name)
    img = rbd.Image(ioctx, image_name)
    for snap in img.list_snaps():
        print("deleting snapshot %s" % snap["name"])
        img.set_snap(snap["name"])
        for child in img.list_children():
            recursive_delete(child["name"], rbd_inst, ioctx)
        img.remove_snap(snap["name"])

    img.close()
    rbd_inst.remove(ioctx, image_name)


if __name__ == "__main__":
    argparser = argparse.ArgumentParser(
        "rbd-empty-trash",
        description="Methodically, relentlessly destroy everything in a "
        "given rbd trash bin. This is needed because some of our backup "
        "processes (using backy2) involve snapshotting; rbd can't really "
        "copy with recursive deletion of volumes with snapshots, so we we "
        "have to do it ourselves."
        "\n"
        "USE WITH CAUTION!",
    )
    argparser.add_argument("pool", help="Ceph pool to act on (e.g. eqiad1-cinder)")

    args = argparser.parse_args()

    cluster = rados.Rados(conffile="/etc/ceph/ceph.conf")
    cluster.connect()
    ioctx = cluster.open_ioctx(args.pool)
    rbd_inst = rbd.RBD()

    trash_list = rbd_inst.trash_list(ioctx)

    for todelete in rbd_inst.trash_list(ioctx):
        print("found in trash: %s" % todelete["name"])
        restored_name = f"{todelete['name']}_from_trash_{uuid.uuid4()}"
        rbd_inst.trash_restore(ioctx, todelete["id"], restored_name)
        recursive_delete(restored_name, rbd_inst, ioctx)
