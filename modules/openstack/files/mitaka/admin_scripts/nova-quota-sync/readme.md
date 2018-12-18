Note:  This script and readme are cribbed from https://github.com/cernops/nova-quota-sync

It can be run on a cloudcontrol node by passing --conf /etc/nova/nova.conf




Nova Quota Sync
===============

What is it?
-----------
It's a small script that compares nova quota usage information with
the actual usage per resource (tenant/user).

It also provides an easy way to synchronize quotas in case of mismatch.


How to use it?
--------------
To see the available options run:

python nova-quota-sync -h

There 5 optional arguments: <br />
--all - show the state of all quota resources <br />
--no_sync - don't perform any synchronization of the mismatch resources <br />
--auto_sync - automatically sync all the resources (no interactive) <br />
--project_id - search only project ID <br />
--config - path for nova.conf or a file with the DB endpoint <br />

If "--no_sync" or "auto_sync" are not used it will run in interactive
mode.


Examples
--------

python nova-quota-sync --config my_nova.conf --all --no_sync

python nova-quota-sync --config my_nova.conf

python nova-quota-sync --auto_sync

python nova-quota-sync --all --no_sync --project_id "d945d5ce-cfb8-11e4-b9d6-1681e6b88ec1"


Nova versions supported
-----------------------
We use it in Havana and now in Icehouse.


Bugs and Disclaimer
-------------------
Bugs? Oh, almost certainly.

This tool was written to be used in the CERN Cloud Infrastructure and
it has been tested only in our environment.

Since it updates nova DB use it with extreme caution.
