#!/usr/bin/pytest-3
#
#  Test selected openstack access policies.
#
#  This should be invoked with sudo
#
#  All of these tests are premised on the existence of the following
#   role assigments in the 'policy-test-project' project:
#
#   novaadmin: projectadmin
#   osscanary: user
#   novaobserver: reader
#
#  In general we permit any role to read anything in any project; these
#   tests are mostly here to make sure that reader or user roles
#   cannot create or destroy things.
#
import time
import uuid
from functools import reduce

import pytest

import keystoneauth1
import mwopenstackclients
from cinderclient import exceptions as cinderexceptions
from designateclient import exceptions as designateexceptions
from neutronclient.common import exceptions as neutronexceptions
from novaclient import exceptions as novaexceptions
from troveclient import exceptions as troveexceptions

POLICY_TEST_PROJECT = "policy-test-project"

# Novaadmin: has project-admin rights in every project
adminclients = mwopenstackclients.clients("/etc/novaadmin.yaml")

# Novaobserver: has read-only rights everywhere, should not be able to change anythin
observerclients = mwopenstackclients.clients("/etc/novaobserver.yaml")

# osstackcanary: has rights in select projects
canaryclients = mwopenstackclients.clients("/etc/oss-canary.yaml")


# Helper function to find a small, public flavor
def smallflavor():
    if smallflavor.flavor:
        return smallflavor.flavor

    novaclient = observerclients.novaclient(project=POLICY_TEST_PROJECT)

    # Find a flavor with a small RAM footprint
    def smallestflavor(flavor1, flavor2):
        if flavor1 and flavor2.ram > flavor1.ram:
            return flavor1
        return flavor2

    smallflavor.flavor = reduce(smallestflavor, novaclient.flavors.list(), None)
    return smallflavor.flavor


smallflavor.flavor = None


# Helper function to find the instance network
def instancenetwork():
    if instancenetwork.network:
        return instancenetwork.network

    neutronclient = observerclients.neutronclient(project=POLICY_TEST_PROJECT)

    def instance_network(net1, net2):
        if "instance" in net2["name"]:
            return net2
        else:
            return net1

    instancenetwork.network = reduce(
        instance_network, neutronclient.list_networks()["networks"], None
    )
    return instancenetwork.network


instancenetwork.network = None


# Helper function to find the instance network
def instanceimage():
    if instanceimage.image:
        return instanceimage.image

    glanceclient = observerclients.glanceclient(project=POLICY_TEST_PROJECT)

    def activeimage(image1, image2):
        if image2.status == "active":
            return image2
        return image1

    instanceimage.image = reduce(activeimage, glanceclient.images.list(), None)
    return instanceimage.image


instanceimage.image = None


class TestKeystone:
    def test_keystone_adminclients(self):
        keystoneclient = adminclients.keystoneclient(project="admin")
        projects = keystoneclient.projects.list()
        assert len(projects) > 0

        keystoneclient.projects.create("policy-test-creation", domain="default")
        keystoneclient.projects.delete("policy-test-creation")

        rolelist = keystoneclient.roles.list()
        for role in rolelist:
            if role.name == "user":
                userroleid = role.id
        keystoneclient.roles.grant(userroleid, user="osstackcanary", project=POLICY_TEST_PROJECT)

    def test_keystone_observerclients(self):
        keystoneclient = observerclients.keystoneclient(project=POLICY_TEST_PROJECT)
        projects = keystoneclient.projects.list()
        assert len(projects) > 0

        with pytest.raises(keystoneauth1.exceptions.http.Forbidden):
            keystoneclient.projects.create("policy-test-creation", domain="default")

        with pytest.raises(keystoneauth1.exceptions.http.Forbidden):
            keystoneclient.projects.delete("policy-test-creation")

        rolelist = keystoneclient.roles.list()
        for role in rolelist:
            if role.name == "user":
                userroleid = role.id
        with pytest.raises(keystoneauth1.exceptions.http.Forbidden):
            keystoneclient.roles.grant(
                userroleid, user="osstackcanary", project=POLICY_TEST_PROJECT
            )
        with pytest.raises(keystoneauth1.exceptions.http.Forbidden):
            keystoneclient.roles.revoke(
                userroleid, user="osstackcanary", project=POLICY_TEST_PROJECT
            )

    def test_keystone_canaryclients(self):
        keystoneclient = canaryclients.keystoneclient(project=POLICY_TEST_PROJECT)
        projects = keystoneclient.projects.list()
        assert len(projects) > 0

        with pytest.raises(keystoneauth1.exceptions.http.Forbidden):
            keystoneclient.projects.create("policy-test-creation", domain="default")

        with pytest.raises(keystoneauth1.exceptions.http.Forbidden):
            keystoneclient.projects.delete("policy-test-creation")

        rolelist = keystoneclient.roles.list()
        for role in rolelist:
            if role.name == "user":
                userroleid = role.id
        with pytest.raises(keystoneauth1.exceptions.http.Forbidden):
            keystoneclient.roles.grant(
                userroleid, user="osstackcanary", project=POLICY_TEST_PROJECT
            )
        with pytest.raises(keystoneauth1.exceptions.http.Forbidden):
            keystoneclient.roles.revoke(
                userroleid, user="osstackcanary", project=POLICY_TEST_PROJECT
            )


class TestNova:
    @classmethod
    def setup_class(cls):
        # We need a VM to experiment with. This has the side-effect of exercising
        #  a lot of our admin credentials.
        novaclient = adminclients.novaclient(project=POLICY_TEST_PROJECT)

        cls.flavor = smallflavor()
        cls.image = instanceimage()
        cls.network = instancenetwork()

        nics = [{"net-id": cls.network["id"]}]
        cls.testserver = novaclient.servers.create(
            "policy-test-server", flavor=cls.flavor.id, image=cls.image.id, nics=nics
        )

        neutronclient = observerclients.neutronclient(project=POLICY_TEST_PROJECT)

        # Find a non-default security group for future use
        def nondefault(group1, group2):
            if "default" in group2["name"]:
                return group1
            else:
                return group2

        cls.security_group = reduce(
            nondefault, neutronclient.list_security_groups()["security_groups"], None
        )

        # Wait for the test VM to be up before we proceed
        counter = 0
        while cls.testserver.status != "ACTIVE":
            counter += 1
            time.sleep(1)
            cls.testserver = novaclient.servers.get(cls.testserver.id)
            # If this is taking more than a few minutes let's call it a failure
            assert counter < 360

    @classmethod
    def teardown_class(cls):
        novaclient = adminclients.novaclient(project=POLICY_TEST_PROJECT)

        # Unfortunately the number of times that setup_class was run is not
        #  especially deterministic.  Rather than delete the particular
        #  VM in cls.testserver, just go looking for anything we might
        #  want to clean up.
        servers = novaclient.servers.list()
        for server in servers:
            novaclient.servers.delete(server.id)

    def test_nova_adminclients(self):
        novaclient = adminclients.novaclient(project=POLICY_TEST_PROJECT)
        servers = novaclient.servers.list()
        assert len(servers) > 0

        with pytest.raises(novaexceptions.NotFound):
            novaclient.servers.delete("thisservertotallydoesnotexist")

    def test_nova_observerclients(self):
        novaclient = observerclients.novaclient(project=POLICY_TEST_PROJECT)
        servers = novaclient.servers.list()
        assert len(servers) > 0

        with pytest.raises(novaexceptions.NotFound):
            novaclient.servers.delete("thisservertotallydoesnotexist")
        with pytest.raises(novaexceptions.Forbidden):
            novaclient.servers.delete(self.testserver.id)

        secgroups = novaclient.servers.list_security_group(self.testserver.id)
        with pytest.raises(novaexceptions.Forbidden):
            novaclient.servers.remove_security_group(self.testserver.id, secgroups[0].id)
        with pytest.raises(novaexceptions.Forbidden):
            novaclient.servers.add_security_group(self.testserver.id, self.security_group["id"])

    def test_nova_canaryclients(self):
        novaclient = canaryclients.novaclient(project=POLICY_TEST_PROJECT)
        servers = novaclient.servers.list()
        assert len(servers) > 0

        with pytest.raises(novaexceptions.NotFound):
            novaclient.servers.delete("thisservertotallydoesnotexist")
        with pytest.raises(novaexceptions.Forbidden):
            novaclient.servers.delete(self.testserver.id)

        secgroups = novaclient.servers.list_security_group(self.testserver.id)
        with pytest.raises(novaexceptions.Forbidden):
            novaclient.servers.remove_security_group(self.testserver.id, secgroups[0].id)
        with pytest.raises(novaexceptions.Forbidden):
            novaclient.servers.add_security_group(self.testserver.id, self.security_group["id"])


class TestCinder:
    @classmethod
    def setup_class(cls):
        cinderclient = adminclients.cinderclient(project=POLICY_TEST_PROJECT)
        volume = cinderclient.volumes.create(
            size=2, name="policy test volume", project_id=POLICY_TEST_PROJECT
        )
        cls.testvolume_id = volume.id
        time.sleep(2)

    @classmethod
    def teardown_class(cls):
        cinderclient = adminclients.cinderclient(project=POLICY_TEST_PROJECT)
        cinderclient.volumes.delete(cls.testvolume_id)

    def test_cinder_observerclients(self):
        cinderclient = observerclients.cinderclient(project=POLICY_TEST_PROJECT)
        volumes = cinderclient.volumes.list()
        assert len(volumes) > 0

        with pytest.raises(cinderexceptions.Forbidden):
            cinderclient.volumes.delete(self.testvolume_id)

        with pytest.raises(cinderexceptions.Forbidden):
            cinderclient.volumes.create(size=2, name="policy test forbidden volume")

    def test_cinder_canaryclients(self):
        cinderclient = canaryclients.cinderclient(project=POLICY_TEST_PROJECT)
        volumes = cinderclient.volumes.list()
        assert len(volumes) > 0

        with pytest.raises(cinderexceptions.Forbidden):
            cinderclient.volumes.delete(self.testvolume_id)

        with pytest.raises(cinderexceptions.Forbidden):
            cinderclient.volumes.create(size=2, name="policy test forbidden volume")


class TestNeutron:
    networkname = "policytestnetwork"

    @classmethod
    def setup_class(cls):
        neutronclient = adminclients.neutronclient(project="admin")
        network = {
            "name": cls.networkname,
            "admin_state_up": False,
            "router:external": False,
            "provider:network_type": "vxlan",
            "shared": True,
        }
        cls.testnetwork = neutronclient.create_network({"network": network})

    @classmethod
    def teardown_class(cls):
        neutronclient = adminclients.neutronclient(project="admin")
        networks = neutronclient.list_networks()
        for network in networks["networks"]:
            if network["name"] == cls.networkname:
                neutronclient.delete_network(network["id"])

    def test_neutron_observerclients(self):
        neutronclient = observerclients.neutronclient(project=POLICY_TEST_PROJECT)
        networks = neutronclient.list_networks()
        assert len(networks) > 0

        with pytest.raises(neutronexceptions.Forbidden):
            neutronclient.delete_network(self.testnetwork["network"]["id"])

    def test_neutron_canaryclients(self):
        neutronclient = canaryclients.neutronclient(project=POLICY_TEST_PROJECT)
        networks = neutronclient.list_networks()
        assert len(networks) > 0

        with pytest.raises(neutronexceptions.Forbidden):
            neutronclient.delete_network(self.testnetwork["network"]["id"])


class TestDesignate:
    @classmethod
    def setup_class(cls):
        # Generate an arbitrary zone to test with
        designateclient = adminclients.designateclient(project=POLICY_TEST_PROJECT)
        existingzones = designateclient.zones.list()
        cls.zonename = "policytest%s.%s" % (str(uuid.uuid4()), existingzones[0]["name"])
        cls.zone = designateclient.zones.create(cls.zonename, email="root@wmcloud.org")
        cls.recordset = designateclient.recordsets.create(
            cls.zone["id"], str(uuid.uuid4()), "A", ["192.168.0.1"]
        )
        time.sleep(2)

    @classmethod
    def teardown_class(cls):
        designateclient = adminclients.designateclient(project=POLICY_TEST_PROJECT)
        existingzones = designateclient.zones.list()
        for zone in existingzones:
            if zone["name"].startswith("policytest"):
                designateclient.zones.delete(zone["id"])

    def test_designate_observerclients(self):
        designateclient = observerclients.designateclient(project=POLICY_TEST_PROJECT)

        with pytest.raises(designateexceptions.Forbidden):
            designateclient.zones.create("observer.%s" % self.zonename, email="root@wmcloud.org")

        with pytest.raises(designateexceptions.Forbidden):
            designateclient.zones.delete(self.zone["id"])

        with pytest.raises(designateexceptions.Forbidden):
            designateclient.recordsets.create(
                self.zone["id"], str(uuid.uuid4()), "A", ["192.168.0.1"]
            )

    def test_designate_canaryclients(self):
        designateclient = canaryclients.designateclient(project=POLICY_TEST_PROJECT)

        with pytest.raises(designateexceptions.Forbidden):
            designateclient.zones.create("observer.%s" % self.zonename, email="root@wmcloud.org")

        with pytest.raises(designateexceptions.Forbidden):
            designateclient.zones.delete(self.zone["id"])

        with pytest.raises(designateexceptions.Forbidden):
            designateclient.recordsets.create(
                self.zone["id"], str(uuid.uuid4()), "A", ["192.168.0.1"]
            )


class TestTrove:
    @classmethod
    def setup_class(cls):
        cls.flavor = smallflavor()

        cls.flavor = smallflavor()
        cls.network = instancenetwork()
        nics = [{"net-id": cls.network["id"]}]

        databases = [{"name": "my_db"}]
        users = [{"name": "jsmith", "password": "12345", "databases": [{"name": "my_db"}]}]

        troveclient = adminclients.troveclient(project=POLICY_TEST_PROJECT)

        datastores = troveclient.datastores.list()
        datastoreversions = troveclient.datastore_versions.list(datastores[0].id)

        instance = troveclient.instances.create(
            name="trove-test-instance",
            flavor_id=cls.flavor.id,
            databases=databases,
            volume={"size": 1},
            nics=nics,
            users=users,
            datastore=datastores[0].id,
            datastore_version=datastoreversions[0].id,
        )

        cls.testinstance = instance

        counter = 0
        while cls.testinstance.status == "BUILD":
            counter += 1
            time.sleep(1)
            cls.testinstance = troveclient.instances.get(cls.testinstance.id)
            # If this is taking more than a few minutes let's call it a failure
            assert counter < 360

    @classmethod
    def teardown_class(cls):
        troveclient = adminclients.troveclient(project=POLICY_TEST_PROJECT)
        troveclient.instances.delete(cls.testinstance.id)

    def test_trove_observerclients(self):
        troveclient = observerclients.troveclient(project=POLICY_TEST_PROJECT)

        with pytest.raises(troveexceptions.Forbidden):
            troveclient.instances.delete(self.testinstance.id)

        # These APIs should be public for everyone
        datastores = troveclient.datastores.list()
        assert len(datastores) > 0

        instances = troveclient.instances.list()
        assert len(instances) > 0

    def test_trove_canaryclients(self):
        troveclient = canaryclients.troveclient(project=POLICY_TEST_PROJECT)

        with pytest.raises(troveexceptions.Forbidden):
            troveclient.instances.delete(self.testinstance.id)

        # These APIs should be public for everyone
        datastores = troveclient.datastores.list()
        assert len(datastores) > 0

        instances = troveclient.instances.list()
        assert len(instances) > 0
