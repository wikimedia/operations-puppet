#!/usr/bin/python3

import mwopenstackclients
import argparse
import subprocess
import sys
import tempfile
import time


clients = mwopenstackclients.clients()
nova = clients.novaclient()
glance = clients.glanceclient()

if False:
    # codfw1dev
    flavorid = "d1549480-83ee-4293-8f25-9724a054111d"
    networkid = "05a5494a-184f-4d5c-9e98-77ae61c56daa"
else:
    # eqiad1

    # It saves us time and space to use an extra-tiny VM here.
    # This is the ID of g3.cores1.ram2.disk4.  We could probably
    # fit into 3GB but I'm leaving a little room to grow.
    flavorid = "e4b7a447-c3d6-4f5e-b0b2-4f2ac19670ec"

    # This is the id of the standard VM network.
    # In eqiad1 that's 'lan-flat-cloudinstances2b'
    networkid = "7425e328-560c-4f00-8e99-706f3fb90bb4"

if __name__ == "__main__":
    argparser = argparse.ArgumentParser(
        "wmcs-create-image",
        description="Create a new glance base image based on a snapshot "
        "of a puppetized upstream image",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    argparser.add_argument(
        "--image-url",
        default="https://cdimage.debian.org/cdimage/openstack/"
        "current/debian-10-openstack-amd64.raw",
        help="url for base image"
        "  see: https://cdimage.debian.org/cdimage/openstack/ for Buster,"
        "  https://cdimage.debian.org/cdimage/cloud/ for bullseye or later"
        "  (but ignore the openstack subdir)",
    )
    argparser.add_argument(
        "--new-image-name",
        default="debian-10.0-buster (testing)",
        help="name of final image to create (e.g. 'debian-10.0-buster'",
    )

    argparser.add_argument(
        "--project-owner",
        help="project to own new image.  If unset, the new image will be public cloud-wide.",
        default="",
    )

    args = argparser.parse_args()

    with tempfile.TemporaryDirectory(prefix=sys.argv[0]) as workdir:
        upstream_image_file = "%s/upstreamimage" % workdir
        print("Downloading upstream image...")
        wgetargs = ["wget", args.image_url, "-O", upstream_image_file]
        _output = subprocess.check_output(wgetargs)

        if args.image_url.endswith("tar.xz"):
            # This is probably an archive containing 'disk.raw'
            print("Untarring and looking for disk.raw")
            tarargs = ["tar", "xvf", upstream_image_file]
            _output = subprocess.check_output(tarargs, cwd=workdir)
            upstream_image_file = "%s/disk.raw" % workdir

        print("Loading the upstream image into glance")
        upstream_image = glance.images.create(
            name="upstream image from %s" % args.image_url,
            visibility="private",
            container_format="ovf",
            disk_format="raw",
            hw_scsi_model="virtio-scsi",
            hw_disk_bus="scsi",
        )
        glance.images.upload(upstream_image.id, open(upstream_image_file, "rb"))

        while glance.images.get(upstream_image.id)["status"] != "active":
            print("Waiting for upstream image status 'active'")
            time.sleep(60)

        print("Launching a vm with the new image")
        nics = [{"net-id": networkid}]
        instance = nova.servers.create(
            name="buildvm-%s" % upstream_image.id,
            image=upstream_image.id,
            flavor=flavorid,
            nics=nics,
        )
        print("Created temporary VM %s" % instance.id)

        logtail = ""

        print("Sleeping 5 minutes while we wait for the VM to start up...")
        time.sleep(300)
        while (
            "Execute cloud user/final scripts" not in logtail
            and "Reached target" not in logtail
        ):
            print("Waiting one minutes for VM to puppetize")
            time.sleep(60)
            logtail = nova.servers.get_console_output(instance.id, length=20)

        print("Stopping the VM")
        logtail = nova.servers.stop(instance.id)

        time.sleep(30)

        print("Taking a snapshot of the stopped instance")
        vm_snap = nova.servers.create_image(
            instance.id, "snap for %s" % instance.id, metadata=None
        )

        time.sleep(30)
        print("Creating snapshot %s" % vm_snap)
        while glance.images.get(vm_snap)["status"] != "active":
            print("Waiting for snapshot to finish saving...")
            time.sleep(60)

        print("Grabbing handle to snapshot data")
        snapshot_data = glance.images.data(vm_snap)

        snapshot_file_name = "%s/snapshot.img" % workdir
        image_file = open(snapshot_file_name, "wb+")

        print("Downloading snapshot to %s" % snapshot_file_name)
        for chunk in snapshot_data:
            image_file.write(chunk)

        print("Making snapshot file sparse")
        sparse_snapshot_file_name = "%s/snapshot.img.sparse" % workdir

        sparseargs = [
            "cp",
            "--sparse=always",
            snapshot_file_name,
            sparse_snapshot_file_name,
        ]
        _output = subprocess.check_output(sparseargs)

        final_image = glance.images.create(
            name=args.new_image_name,
            visibility="private",
            container_format="ovf",
            disk_format="raw",
            hw_scsi_model="virtio-scsi",
            hw_disk_bus="scsi",
        )
        print("Creating final image %s" % final_image.id)
        glance.images.upload(final_image.id, open(sparse_snapshot_file_name, "rb"))

        while glance.images.get(final_image.id)["status"] != "active":
            print("Waiting for final image status 'active'")
            time.sleep(10)

        print("Setting image ownership and visibility")
        if args.project_owner:
            glance.images.update(
                final_image.id, owner=args.project_owner, visibility="shared"
            )
        else:
            glance.images.update(final_image.id, visibility="public")

        print("Cleaning up intermediate VM")
        nova.servers.delete(instance.id)
        time.sleep(10)

        print("Cleaning up VM snapshot")
        glance.images.delete(vm_snap)
        time.sleep(10)

        print("Cleaning up upstream image")
        glance.images.delete(upstream_image.id)

        print("Finished creating new image: %s" % final_image.id)
