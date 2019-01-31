#!/usr/bin/python
"""

Copy a VM from one region to another.

The actual way we do this is terrible: we create a new
VM in the destination region, and then supplant it with the
contents of the source VM.  This has the advantage of
being much faster and using less disk space than the
traditional VM->snapshot->image->VM path that's documented
elsewhere.

Actually copying a VM's state in nova from the database
turns out to be a tangled web as well; much simpler to just
let nova create us a new vessel.

This script assumes that both regions share the same
glance and keystone, and that there are ssh keys set
up between the source and destination hypervisor.

The target hypervisor will be selected by the nova scheduler
running in the target region.

- activate glance image if needed
- create new dummy VM, determine its location
- stop dummy VM
- copy source VM files over dummy files
- update a few nova database entries
- restart dummy VM
- deactivate glance image
"""

import configparser
import argparse
import json
import requests
import subprocess
import time

from designateclient.v2 import client as designateclient
import glanceclient
from keystoneclient.auth.identity import generic
from keystoneclient import session as keystone_session
from keystoneclient.v3 import client as keystoneclient
from neutronclient.v2_0 import client as neutronclient
from novaclient import client as novaclient


class NovaInstance(object):

    def __init__(self,
                 instance_id,
                 common_config,
                 source_config,
                 dest_config):

        self.dnsdomain = common_config['dnsdomain']
        self.instance_id = instance_id
        self.source_config = source_config
        self.dest_config = dest_config
        self.common_config = common_config

        source_auth = generic.Password(
            auth_url=self.common_config['keystone_url'],
            username=self.common_config['user'],
            password=self.common_config['password'],
            user_domain_name='Default',
            project_domain_name='Default',
            project_name='admin')
        source_session = keystone_session.Session(auth=source_auth)
        self.source_novaclient = novaclient.Client('2', session=source_session,
                                                   region_name=source_config['region'])

        self.refresh_instance()
        self.project_id = self.source_instance.tenant_id
        self.user_id = self.source_instance.user_id

        project_auth = generic.Password(
            auth_url=self.common_config['keystone_url'],
            username=self.common_config['user'],
            password=self.common_config['password'],
            user_domain_name='Default',
            project_domain_name='Default',
            project_name=self.project_id)
        project_session = keystone_session.Session(auth=project_auth)
        self.designateclient = designateclient.Client(session=project_session,
                                                      region_name=source_config['region'])

        self.novaclient_projectscope = novaclient.Client('2', session=project_session,
                                                         region_name=dest_config['region'])

        wmflabs_auth = generic.Password(
            auth_url=self.common_config['keystone_url'],
            username=self.common_config['user'],
            password=self.common_config['password'],
            user_domain_name='Default',
            project_domain_name='Default',
            project_name='wmflabsdotorg')
        wmflabs_session = keystone_session.Session(auth=wmflabs_auth)
        self.wmflabsdesignateclient = designateclient.Client(session=wmflabs_session,
                                                             region_name=source_config['region'])

        dest_auth = generic.Password(
            auth_url=self.common_config['keystone_url'],
            username=self.common_config['user'],
            password=self.common_config['password'],
            user_domain_name='Default',
            project_domain_name='Default',
            project_name='admin')
        self.dest_session = keystone_session.Session(auth=dest_auth)

        self.dest_novaclient = novaclient.Client('2', session=self.dest_session,
                                                 region_name=dest_config['region'])
        self.dest_neutronclient = neutronclient.Client(session=self.dest_session,
                                                       region_name=dest_config['region'])
        self.dest_keystoneclient = keystoneclient.Client(session=self.dest_session,
                                                         region_name=dest_config['region'])
        self.proxy_endpoint = self.get_proxy_endpoint(self.dest_keystoneclient, dest_config['region'])

    # Returns True if the status changed, otherwise False
    @staticmethod
    def activate_image(dest_session, image_id, deactivate=False):
        token = dest_session.get_token()

        glanceendpoint = dest_session.get_endpoint(service_type='image')
        gclient = glanceclient.Client('1', glanceendpoint, token=token)
        image = gclient.images.get(image_id)

        # Because the glance devs can't be bothered to update their python
        #  bindings when new features are added, we have to do this the
        #  old-fashioned way.
        if deactivate:
            action = 'deactivate'
            if image.status == 'deactivated':
                # Nothing to do
                return False
            print("deactivating image %s" % image_id)
        else:
            action = 'reactivate'
            if image.status == 'active':
                # Nothing to do
                return False
            print("activating image %s" % image_id)

        url = "%s/v2/images/%s/actions/%s" % (glanceendpoint, image_id, action)

        resp = requests.post(url, headers={'X-Auth-Token': token})
        if resp:
            return True
        else:
            raise Exception("Image manipulation got status: " + resp.status_code)

    def dns_test(self, source=True, accept_multiples=False):
        if source:
            instance = self.source_instance
            target_ip = self.get_fixed_ip(instance)
        else:
            instance = self.dest_instance
            target_ip = instance.addresses[self.dest_config['network_name']][0]['addr']

        nameserver = self.common_config['dns_server']
        fqdn = "%s.%s.%s" % (instance.name, self.project_id, self.common_config['vps_domain'])

        digargs = ["dig", "@%s" % nameserver, "+short", fqdn]
        try:
            r = subprocess.check_output(digargs)
        except:
            print("exception caught while attempting dig for %s" % fqdn)
            return False

        ips = r.strip().split('\n')
        if accept_multiples:
            if target_ip not in ips:
                print("Got wrong ip %s for %s, should include %s" % (r, fqdn, target_ip))
                return False
        else:
            if len(ips) > 1:
                print("Got multiple IPs for %s" % fqdn)
                return False

        if target_ip not in ips:
            print("Got wrong ip %s for %s, should be %s" % (r, fqdn, target_ip))
            return False

        return True

    def get_fixed_ip(self, instance):
        for address in instance.addresses['public']:
            if address['OS-EXT-IPS:type'] == 'fixed':
                return address['addr']

        print "WARNING: no fixed IP found for instance %s" % instance.name

    def get_floating_ips(self, instance):
        floating = []
        for address in instance.addresses['public']:
            if address['OS-EXT-IPS:type'] == 'floating':
                floating.append(address['addr'])

        return floating

    def get_proxy_endpoint(self, keystoneclient, region):
        services = keystoneclient.services.list()
        for service in services:
            if service.type == 'proxy':
                serviceid = service.id
                break

        endpoints = keystoneclient.endpoints.list(service=serviceid,
                                                  region=region)
        for endpoint in endpoints:
            if endpoint.interface == 'public':
                return endpoint.url

        print("Can't find the public proxy service endpoint.")

    def migrate_security_groups(self):

        # For unclear reasons, modifying security groups has to happen within
        #  project scope.
        scoped_dest_instance = self.novaclient_projectscope.servers.get(self.dest_instance_id)

        source_groups = self.source_instance.security_groups
        for source_group in source_groups:
            scoped_dest_instance.add_security_group(source_group['name'])

    def migrate_proxies(self, source_ip, dest_ip):
        endpoint = self.proxy_endpoint
        requrl = endpoint.replace("$(tenant_id)s", self.project_id)
        resp = requests.get(requrl + '/mapping')
        if resp.status_code == 400 and resp.text == 'No such project':
            return []
        elif not resp:
            raise Exception("Proxy service request got status " +
                            str(resp.status_code))
        project_proxies = resp.json()['routes']

        for proxy in project_proxies:
            if len(proxy['backends']) > 1:
                print("This proxy record has multiple backends. "
                      "That's unexpected and not handled, "
                      "we may be leaking proxy records.")
            elif proxy['backends'][0].split(":")[1].strip('/') == source_ip:
                port = proxy['backends'][0].split(":")[2].strip('/')
                # found match.  Delete and recreate.
                print("Updating proxy record %s" % proxy)
                requrl = endpoint.replace("$(tenant_id)s", self.project_id)
                req = requests.delete(requrl + '/mapping/' + proxy['domain'])
                req.raise_for_status()

                proxy['backends'] = ['http://%s:%s' % (dest_ip, port)]

                req = requests.put(requrl + '/mapping', data=json.dumps(proxy))
                req.raise_for_status()

    def migrate_dns(self, source_ip, dest_ip):
        for client in [self.designateclient, self.wmflabsdesignateclient]:
            zones = client.zones.list()
            for zone in zones:
                recordsets = client.recordsets.list(zone['id'])
                for recordset in recordsets:
                    if source_ip in recordset['records']:
                        recordset['records'][recordset['records'].index(source_ip)] = dest_ip
                        print("updating dns record to %s" % recordset['records'])
                        client.recordsets.update(zone['id'],
                                                 recordset['id'],
                                                 {"records": recordset['records']})

    def ssh_test(self, source=True, command='hostname'):
        if source:
            instance = self.source_instance
            target_ip = self.get_fixed_ip(instance)
            proxy = self.source_config['proxy']
        else:
            instance = self.dest_instance
            target_ip = instance.addresses[self.dest_config['network_name']][0]['addr']
            proxy = self.dest_config['proxy']

        if instance.status != 'ACTIVE':
            print ("We can't test ssh to an instance with state %s" % instance.status)
            return False

        rootkeyfile = self.common_config['ssh_root_key_path']

        sshargs = ["ssh", "-i", rootkeyfile, "-oStrictHostKeyChecking=no",
                   '-oProxyCommand=/usr/bin/ssh -i %s -a -W %%h:%%p root@%s' % (rootkeyfile, proxy),
                   "root@%s" % target_ip, command]
        try:
            r = subprocess.check_output(sshargs)
        except:
            print("exception caught while attempting ssh to %s" % target_ip)
            return False

        if command == 'hostname':
            if r.strip().lower() != instance.name.lower():
                print("ssh test to %s failed.  Returned hostname %s but expected %s" %
                      (target_ip, r.strip().lower(), instance.name.lower()))
                return False
            else:
                print("verified ssh for %s, returned hostname %s" % (target_ip, r))

        return True

    def refresh_instance(self, source=True):
        if source:
            self.source_instance = self.source_novaclient.servers.get(self.instance_id)
        else:
            self.dest_instance = self.dest_novaclient.servers.get(self.dest_instance_id)

    def wait_for_status(self, desiredstatus, source=True):
        oldstatus = ""
        if source:
            watched_instance = self.source_instance
        else:
            watched_instance = self.dest_instance

        while watched_instance.status != desiredstatus:
            if watched_instance.status != oldstatus:
                oldstatus = watched_instance.status
                print("Current status for %s is %s; waiting for it to change to %s." % (
                    watched_instance.id, watched_instance.status, desiredstatus))

            time.sleep(1)
            self.refresh_instance(source)
            if source:
                watched_instance = self.source_instance
            else:
                watched_instance = self.dest_instance

    def assign_floating_ip_to_destination_vm(self):

        ports = []
        all_ports = self.dest_neutronclient.list_ports()
        for port in all_ports['ports']:
            if port['device_id'] == self.dest_instance.id:
                ports.append(port)

        if len(ports) > 1:
            print("Got the wrong number of ports for the dest VM.")
            exit(1)

        port = ports[0]

        resp = self.dest_neutronclient.create_floatingip(
            {'floatingip':
             {'tenant_id': self.project_id,
              'floating_network_id': self.dest_config['floating_ip_network_id'],
              'port_id': port['id']}})

        return resp['floatingip']['floating_ip_address']

    def make_destination_vm(self, name, image_id, flavor_id):
        # we need a project-scoped session to create the VM in the right project
        create_auth = generic.Password(
            auth_url=self.common_config['keystone_url'],
            username=self.common_config['user'],
            password=self.common_config['password'],
            user_domain_name='Default',
            project_domain_name='Default',
            project_name=self.project_id)
        create_session = keystone_session.Session(auth=create_auth)
        self.create_novaclient = novaclient.Client('2', session=create_session,
                                                   region_name=self.dest_config['region'])

        nics = [{"net-id": self.dest_config['network_id'], "v4-fixed-ip": ''}]
        inst = self.create_novaclient.servers.create(name, image_id, flavor_id, nics=nics)
        self.dest_instance_id = inst.id

        self.refresh_instance(False)
        self.wait_for_status('ACTIVE', source=False)
        self.dest_host = self.dest_instance._info['OS-EXT-SRV-ATTR:host']

        print("dest_instance_id: %s on %s" % (self.dest_instance_id, self.dest_host))

    def migrate(self):
        source_host = self.source_instance._info['OS-EXT-SRV-ATTR:host']
        print("Source instance %s is now on host %s with state %s" % (
            self.instance_id,
            source_host,
            self.source_instance.status))

        name = self.source_instance.name
        image_id = self.source_instance.image['id']
        flavor_id = self.source_instance.flavor['id']

        floating_ips = self.get_floating_ips(self.source_instance)

        if len(floating_ips) > 1:
            print("This VM has more than one floating IP -- this case is not supported.")
            exit(1)
        elif len(floating_ips) == 1:
            self.source_floating_ip = floating_ips[0]
        else:
            self.source_floating_ip = None

        # Make sure that our dns tests are working
        if not self.dns_test():
            print("DNS test failed, bailing out")
            exit(1)

        if self.source_instance.status == 'ACTIVE':
            # Verify that we can connect to this VM, then shut it off.

            if not self.ssh_test():
                print("Failed to ssh to source VM.")
                exit(1)

            try:
                self.source_instance.stop()
            except:
                print("exception caught while stopping source VM")
                exit(1)
        elif self.source_instance.status == 'SHUTOFF':
            print("Source VM is already shut off.")
        else:
            print("Source VM has status %s" % self.source_instance.status)

        activated_image = self.activate_image(self.dest_session, image_id)

        self.make_destination_vm(name, image_id, flavor_id)

        if activated_image:
            self.activate_image(self.dest_session, image_id, deactivate=True)

        self.migrate_security_groups()

        source_ip = self.get_fixed_ip(self.source_instance)
        target_ip = self.dest_instance.addresses[self.dest_config['network_name']][0]['addr']
        self.migrate_proxies(source_ip, target_ip)

        if self.source_floating_ip:
            self.dest_floating_ip = self.assign_floating_ip_to_destination_vm()
            print("dest_floating_ip is %s" % self.dest_floating_ip)
            self.migrate_dns(self.source_floating_ip, self.dest_floating_ip)

        # Make sure we have a working key for copying instances
        sshargs = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
                   "nova@%s.%s" % (self.dest_host, self.dnsdomain), "true"]
        r = subprocess.call(sshargs)
        if r:
            print("Remote execution failed; this whole enterprise is doomed.")
            print("We leaked a VM with ID %s" % self.dest_instance_id)
            exit(1)

        self.dest_instance.stop()

        self.wait_for_status('SHUTOFF', source=True)
        self.wait_for_status('SHUTOFF', source=False)

        # There might be a race here where kvm is still writing to the
        #  dest VM after it's stopped.  Take a nap and see if that helps.
        # (The symptom is rsync failing to validate the dest file after copying.)
        time.sleep(10)

        instancebasedir = "/var/lib/nova/instances"
        source_instancedir = "%s/%s" % (instancebasedir, self.instance_id)
        dest_instancedir = "%s/%s" % (instancebasedir, self.dest_instance_id)

        # ssh to the source host, and rsync from there to the dest
        #  using the shared nova key.
        #
        # Don't bother to rsync the console log.  Nova can't read
        #  it, and we don't need it.
        args = ["ssh", "-i", "/root/.ssh/compute-hosts-key",
                "nova@%s.%s" % (source_host, self.dnsdomain),
                "/usr/bin/rsync -S -avz -e \"ssh -o StrictHostKeyChecking=no "
                "-o UserKnownHostsFile=/dev/null -i "
                "/var/lib/nova/.ssh/id_rsa\" --progress "
                "--exclude=console.log "
                "%s/* nova@%s.%s:%s" %
                (source_instancedir, self.dest_host, self.dnsdomain, dest_instancedir)]
        print(" ".join(args))
        r = subprocess.call(args)
        if r:
            print("rsync to new host failed.")
            return(1)

        print("Instance copied.  Now updating nova db...")
        host_moved = True

        args = ["mysql", "--user=%s" % self.dest_config['db_username'],
                "--password=%s" % self.dest_config['db_password'],
                "--host", self.dest_config['db_hostname'], self.dest_config['db_name'],
                "-e",
                "update instances set user_id=\"%s\" "
                "where uuid=\"%s\";" %
                (self.user_id, self.dest_instance_id)]
        r = subprocess.call(args)

        if r:
            print("Failed to update the instance's db record.")

        self.dest_instance.start()
        self.wait_for_status('ACTIVE', source=False)

        print("Waiting for the copied VM to boot and adjust to the new ip")
        time.sleep(60)

        print("Rebooting to acquire the new hostname")
        self.dest_instance.reboot()
        self.wait_for_status('ACTIVE', source=False)

        for i in xrange(11):
            if self.ssh_test(source=False):
                break
            else:
                print("Failed to ssh to new VM. Retrying after a wait...")
                time.sleep(30)

        if i == 10:
            print("all ssh tests failed, giving up.  Leaks abound.")
            exit(1)

        # Check that the new VM is showing up in dns
        for i in xrange(21):
            if self.dns_test(source=False, accept_multiples=True):
                break

            time.sleep(30)

        if i == 20:
            print("The new instance isn't appearing in DNS")
            exit(1)

        if host_moved:
            self.source_instance.delete()
            pass
        else:
            # we need to do some kind of clever cleanup here
            pass

        for i in xrange(11):
            if self.dns_test(source=False):
                break
            else:
                print("waiting to recheck DNS")
                time.sleep(30)

        if i == 10:
            print("all dns tests failed, giving up.  We probably leaked a DNS record for the source VM.")
            exit(1)

        # Fix up the IP in /etc/hosts
        self.ssh_test(source=False, command="sed -i s/%s/%s/g /etc/hosts" % (source_ip, target_ip))

        print("Instance %s is now on host %s with status %s" % (
            self.dest_instance_id,
            self.dest_instance._info['OS-EXT-SRV-ATTR:host'],
            self.dest_instance.status))


if __name__ == "__main__":
    config = configparser.ConfigParser()
    config.read('region-migrate.conf')
    if 'source' not in config.sections():
        print("config requires a 'source' section")
        exit(1)
    if 'dest' not in config.sections():
        print("config requires a 'dest' section")
        exit(1)

    argparser = argparse.ArgumentParser('region-migrate',
                                        description="Move an instance to a "
                                        "different region")
    argparser.add_argument(
        'instanceid',
        help='instance id to migrate',
    )
    args = argparser.parse_args()

    instance = NovaInstance(args.instanceid,
                            config['common'],
                            config['source'],
                            config['dest'])
    instance.migrate()
