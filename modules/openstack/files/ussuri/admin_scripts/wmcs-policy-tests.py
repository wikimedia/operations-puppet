#!/usr/bin/pytest-3
#
#  Test selected openstack access policies.
#
#  This should be invoked with sudo
#
from functools import reduce
import pytest
import time

from cinderclient import exceptions as cinderexceptions
import keystoneauth1
from novaclient import exceptions as novaexceptions

import mwopenstackclients

POLICY_TEST_PROJECT = "policy-test-project"

# Novaadmin: has project-admin rights in every project
adminclients = mwopenstackclients.clients("/etc/novaadmin.yaml")

# Novaobserver: has read-only rights everywhere, should not be able to change anythin
observerclients = mwopenstackclients.clients("/etc/novaobserver.yaml")

# osstackcanary: has rights in select projects
canaryclients = mwopenstackclients.clients("/etc/oss-canary.yaml")


class TestKeystone:
    def test_keystone_adminclients(self):
        keystoneclient = adminclients.keystoneclient(project="admin")
        projects = keystoneclient.projects.list()
        assert len(projects) > 0

        keystoneclient.projects.create('policy-test-creation', domain='default')
        keystoneclient.projects.delete('policy-test-creation')

        rolelist = keystoneclient.roles.list()
        for role in rolelist:
            if role.name == "user":
                userroleid = role.id
        keystoneclient.roles.grant(
            userroleid, user="osstackcanary", project=POLICY_TEST_PROJECT
        )

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
        neutronclient = adminclients.neutronclient(project=POLICY_TEST_PROJECT)
        glanceclient = adminclients.glanceclient(project=POLICY_TEST_PROJECT)

        # Find a flavor with a small RAM footprint
        def smallestflavor(flavor1, flavor2):
            if flavor1 and flavor2.ram > flavor1.ram:
                return flavor1
            return flavor2

        cls.flavor = reduce(smallestflavor, novaclient.flavors.list(), None)

        # Find an enabled image, we don't care which. This will fail if none are found.
        def activeimage(image1, image2):
            if image2.status == "active":
                return image2
            return image1

        cls.image = reduce(activeimage, glanceclient.images.list(), None)

        # find an instance network
        def instancenetwork(net1, net2):
            print("net1 is %s" % net1)
            print("net2 is %s" % net2)
            if "instance" in net2["name"]:
                return net2
            else:
                return net1

        cls.network = reduce(
            instancenetwork, neutronclient.list_networks()["networks"], None
        )

        nics = [{"net-id": cls.network["id"]}]
        cls.testserver = novaclient.servers.create(
            "policy-test-server", flavor=cls.flavor.id, image=cls.image.id, nics=nics
        )

    @classmethod
    def teardown_class(cls):
        novaclient = adminclients.novaclient(project=POLICY_TEST_PROJECT)
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

    def test_nova_canaryclients(self):
        novaclient = canaryclients.novaclient(project=POLICY_TEST_PROJECT)
        servers = novaclient.servers.list()
        assert len(servers) > 0

        with pytest.raises(novaexceptions.NotFound):
            novaclient.servers.delete("thisservertotallydoesnotexist")
        with pytest.raises(novaexceptions.Forbidden):
            novaclient.servers.delete(self.testserver.id)


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


class TestNeutron:
    def test_neutron(self):
        neutronclient = observerclients.neutronclient(project=POLICY_TEST_PROJECT)
        networks = neutronclient.list_networks()
        assert len(networks) > 0


TestNova.setup_class()
