#!/usr/bin/python3

import argparse
import logging
import subprocess
import sys
import tempfile
import time
from contextlib import contextmanager
from enum import Enum, auto
from pathlib import Path
from typing import Any, Callable, Optional

import mwopenstackclients

LOGGER = logging.getLogger("wmcs-image-create")

clients = mwopenstackclients.clients()
nova = clients.novaclient()
glance = clients.glanceclient()


class WrongAnswer(Exception):
    pass


class AskReply(Enum):
    CONTINUE = auto()
    EXIT = auto()
    SKIP = auto()

    @classmethod
    def string_to_reply(cls, raw_str: str):
        if raw_str.strip().lower() in ["c", "cont", "continue"]:
            return AskReply.CONTINUE
        elif raw_str.strip().lower() in ["e", "exit"]:
            return AskReply.EXIT
        elif raw_str.strip().lower() in ["s", "skip"]:
            return AskReply.SKIP

        raise WrongAnswer(f"Unknown anwser: {raw_str}")


def get_with_confirmation(step_by_step: bool) -> Callable:
    @contextmanager
    def with_confirmation(message: Optional[str] = None):
        if message is not None:
            LOGGER.info(message)

        if not step_by_step:
            reply = AskReply.CONTINUE
        else:
            reply = ask_for_confirmation()

        if reply == AskReply.CONTINUE:
            yield reply
        elif reply == AskReply.SKIP:
            LOGGER.info("Skipping...")
            yield reply
        elif reply == AskReply.EXIT:
            raise Exception("Aborting at user's request.")
        else:
            raise Exception(f"This should never happen, unknown reply {reply}")

    return with_confirmation


def ask_for_confirmation() -> AskReply:
    tries = 3
    while True:
        user_input = input("STEP_BY_STEP: Continue, skip or exit? [Cse]") or "continue"
        try:
            return AskReply.string_to_reply(user_input)

        except WrongAnswer:
            tries -= 1
            if tries <= 0:
                raise

            continue

    raise Exception("This should not happen")


def get_run(step_by_step: bool) -> Callable:
    def run(*command: str, **kwargs: Any) -> str:
        with_confirmation = get_with_confirmation(step_by_step)
        with with_confirmation(f"Running command:\n    {command}\n    options: {kwargs}") as reply:
            if reply == AskReply.CONTINUE:
                subprocess.check_output(command, **kwargs)
            elif reply == AskReply.SKIP:
                return

    return run


if False:
    # codfw1dev
    flavorid = "74307309-258b-435c-a1b0-3d684bb0062c"
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


def parse_args():
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

    argparser.add_argument(
        "--step-by-step",
        help="If set, will ask for confirmation on every step.",
        action="store_true",
    )

    argparser.add_argument(
        "--reuse-downloaded-image",
        help=(
            "If set, will not re-download the image if there's one there already (to use with "
            "--workdir)."
        ),
        action="store_true",
    )

    argparser.add_argument(
        "--workdir",
        help="If passed, will use this as the workdir instead of a temporary directory.",
        default=None,
    )

    return argparser.parse_args()


def download_image(upstream_image_path: Path, image_url: str, run: Callable, workdir: Path):
    LOGGER.info("Downloading upstream image...")
    run("wget", image_url, "-O", upstream_image_path)

    if image_url.endswith("tar.xz"):
        # This is probably an archive containing 'disk.raw'
        LOGGER.info("Untarring and looking for disk.raw")
        tarfile = upstream_image_path.with_suffix(".tar.xz")
        run("tar", "xvf", tarfile, cwd=workdir)
        disk_path = workdir / "disk.raw"
        disk_path.rename(upstream_image_path)


def upload_image(image_url: str, upstream_image_path: Path):
    LOGGER.info("Loading the upstream image into glance")
    upstream_image = glance.images.create(
        name="upstream image from %s" % image_url,
        visibility="private",
        container_format="ovf",
        disk_format="raw",
        hw_scsi_model="virtio-scsi",
        hw_disk_bus="scsi",
    )
    glance.images.upload(upstream_image.id, upstream_image_path.open("rb"))

    while glance.images.get(upstream_image.id)["status"] != "active":
        LOGGER.info("Waiting for upstream image status 'active'")
        time.sleep(60)

    return upstream_image


def create_puppetized_vm(upstream_image, network_id, flavor_id):
    LOGGER.info("Launching a vm with the new image")
    nics = [{"net-id": network_id}]
    instance = nova.servers.create(
        name="buildvm-%s" % upstream_image.id,
        image=upstream_image.id,
        flavor=flavor_id,
        nics=nics,
    )
    LOGGER.info("Created temporary VM %s" % instance.id)

    LOGGER.info("Sleeping 5 minutes while we wait for the VM to start up...")
    logtail = ""
    tries = 30
    while not logtail and tries > 0:
        try:
            logtail = nova.servers.get_console_output(instance.id, length=20)
        except Exception:
            pass
            tries -= 1
            time.sleep(10)
        if logtail:
            LOGGER.info("VM seems to be up!")
            break

    while "Execute cloud user/final scripts" not in logtail and "Reached target" not in logtail:
        LOGGER.info("Waiting one minutes for VM to puppetize")
        time.sleep(60)
        logtail = nova.servers.get_console_output(instance.id, length=20)

    LOGGER.info("Stopping the VM")
    logtail = nova.servers.stop(instance.id)
    time.sleep(30)

    return instance


def get_snapshot(instance_id: str, snapshot_path: Path):
    LOGGER.info("Taking a snapshot of the stopped instance")
    vm_snap = nova.servers.create_image(instance_id, f"snap for {instance_id}", metadata=None)
    time.sleep(30)

    while glance.images.get(vm_snap)["status"] != "active":
        LOGGER.info("Waiting for snapshot to finish saving...")
        time.sleep(60)

    LOGGER.info("Grabbing handle to snapshot data")
    snapshot_data = glance.images.data(vm_snap)

    with snapshot_path.open("wb+") as image_file:
        LOGGER.info(f"Downloading snapshot to {snapshot_path}")
        for chunk in snapshot_data:
            image_file.write(chunk)

    return vm_snap


def disable_puppet_on_image(workdir: Path, snapshot_path: Path, run: Callable) -> None:
    LOGGER.info("Disabling the puppet cron on the image")
    run("modprobe", "nbd")
    # make sure it's not being used, will not fail if it's not
    run("qemu-nbd", "--disconnect", "/dev/nbd0")
    run("qemu-nbd", "--format=raw", "--connect=/dev/nbd0", snapshot_path)
    mountpath = workdir / "mnt"
    mountpath.mkdir(parents=True, exist_ok=True)
    # it will guess the filesystem
    run("mount", "/dev/nbd0p1", mountpath)
    puppet_cron_config = mountpath / "etc/cron.d/puppet"
    if not puppet_cron_config.is_file():
        raise Exception(f"Unable to find puppet cron config {puppet_cron_config}, aborting")

    puppet_cron_config.unlink()
    run("umount", mountpath)
    run("qemu-nbd", "--disconnect", "/dev/nbd0")


def sparsify_image(workdir: Path, snapshot_path: Path, run: Callable) -> None:
    LOGGER.info("Making snapshot file sparse")
    sparse_snapshot_path = workdir / "snapshot.img.sparse"
    run(
        "cp",
        "--sparse=always",
        snapshot_path,
        sparse_snapshot_path,
    )
    return sparse_snapshot_path


def create_and_upload_image(new_image_name: str, sparse_snapshot_path: Path, project_owner: str):
    final_image = glance.images.create(
        name=new_image_name,
        visibility="private",
        container_format="ovf",
        disk_format="raw",
        hw_scsi_model="virtio-scsi",
        hw_disk_bus="scsi",
    )
    glance.images.upload(final_image.id, open(sparse_snapshot_path, "rb"))

    while glance.images.get(final_image.id)["status"] != "active":
        LOGGER.info("Waiting for final image status 'active'")
        time.sleep(10)

    LOGGER.info("Setting image ownership and visibility")
    if project_owner:
        glance.images.update(final_image.id, owner=project_owner, visibility="shared")
    else:
        glance.images.update(final_image.id, visibility="public")

    return final_image


def cleanup(vm_snap: str, instance_id: str, upstream_image_id: str) -> None:
    LOGGER.info("Cleaning up intermediate VM")
    nova.servers.delete(instance_id)
    time.sleep(10)

    LOGGER.info("Cleaning up VM snapshot")
    glance.images.delete(vm_snap)
    time.sleep(10)

    LOGGER.info("Cleaning up upstream image")
    glance.images.delete(upstream_image_id)


def main(args: argparse.Namespace) -> None:
    with_confirmation = get_with_confirmation(step_by_step=args.step_by_step)
    run = get_run(step_by_step=args.step_by_step)

    with tempfile.TemporaryDirectory(prefix=sys.argv[0]) as workdir_path:
        if args.workdir:
            workdir = Path(args.workdir)
        else:
            workdir = Path(workdir_path)

        upstream_image_path = workdir / "upstreamimage"
        snapshot_path = workdir / "snapshot.img"

        if not args.reuse_downloaded_image or not upstream_image_path.is_file():
            download_image(
                upstream_image_path=upstream_image_path,
                image_url=args.image_url,
                run=run,
                workdir=workdir,
            )

        with with_confirmation("Creating a VM from the image and downloading a snapshot.") as reply:
            if reply == AskReply.CONTINUE:
                upstream_image = upload_image(
                    image_url=args.image_url, upstream_image_path=upstream_image_path
                )
                instance = create_puppetized_vm(upstream_image=upstream_image)
                vm_snap = get_snapshot(instance_id=instance.id, snapshot_path=snapshot_path)

        disable_puppet_on_image(workdir=workdir, snapshot_path=snapshot_path, run=run)

        sparse_snapshot_path = sparsify_image(snapshot_path=snapshot_path, workdir=workdir, run=run)

        with with_confirmation("Creating final image") as reply:
            if reply == AskReply.CONTINUE:
                final_image = create_and_upload_image(
                    new_image_name=args.new_image_name,
                    sparse_snapshot_path=sparse_snapshot_path,
                    project_owner=args.project_owner,
                )

        with with_confirmation(
            "Cleaning up (removing instances, snapshots and temporary images)"
        ) as reply:
            if reply == AskReply.CONTINUE:
                cleanup(
                    instance_id=instance.id,
                    vm_snap=vm_snap,
                    upstream_image_id=upstream_image.id,
                )

        LOGGER.info("Finished creating new image: %s" % final_image.id)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    args = parse_args()
    main(args)
