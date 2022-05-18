#!/usr/bin/python3

import argparse
import datetime
import smtplib

import mwopenstackclients


def send_nag_email(email, project, instance, age, days_to_delete=0):
    FROM = "do_not_reply@wmcloud.org"
    TO = [email]
    SUBJECT = "Time to delete %s.%s" % (instance, project)

    TEXT = (
        "The virtual machine you created named '%s' in the '%s' project "
        "is now %s days old.  Please delete it soon and free "
        "up space for others to use." % (instance, project, age)
    )
    if days_to_delete:
        TEXT += "\n\nThis VM will be automatically deleted in %s days." % (days_to_delete - age)

    message = """\
From: %s
To: %s
Subject: %s
%s
    """ % (
        FROM,
        ", ".join(TO),
        SUBJECT,
        TEXT,
    )

    server = smtplib.SMTP("localhost")
    server.sendmail(FROM, TO, message)
    server.quit()


def check_instance_ages(project, days_to_nag, days_to_delete):
    clients = mwopenstackclients.clients(envfile="/etc/novaadmin.yaml")

    keystone = clients.keystoneclient(project=project)
    for instance in clients.allinstances(projectid=project, allregions=True):
        created = datetime.datetime.strptime(instance.created, "%Y-%m-%dT%H:%M:%SZ")
        age = (datetime.datetime.now() - created).days
        user = keystone.users.get(instance.user_id)
        print(instance.name, user.email, age)

        if days_to_delete:
            if age > days_to_delete:
                print(
                    "Deleting %s.%s because it is more than %s days old"
                    % (instance.name, project, days_to_delete)
                )
                clients.novaclient(project=project).servers.delete(instance.id)
                continue

        if age > days_to_nag:
            print(
                "Sending warning email about %s.%s because it is %s days old"
                % (instance.name, project, age)
            )
            send_nag_email(user.email, project, instance.name, age, days_to_delete)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Purge old VMs from a project")
    parser.add_argument("--project", help="Project to purge (e.g. sre-sandbox)", action="store")
    parser.add_argument(
        "--days-to-delete",
        default=0,
        type=int,
        help="Delete VMs older than this number of days.  If unspecified then nothing is deleted.",
        action="store",
    )
    parser.add_argument(
        "--days-to-nag",
        required=True,
        type=int,
        help="Nag creators of VMs older than this number of days",
        action="store",
    )
    args = parser.parse_args()

    check_instance_ages(args.project, args.days_to_nag, args.days_to_delete)
