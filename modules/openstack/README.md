openstack
=========

#### Table of Contents

1. [Overview - What is the openstack module?](#overview)
2. [Module Description - What does the module do?](#module-description)
3. [Setup - The basics of getting started with cinder](#setup)
4. [Implementation - An under-the-hood peek at what the module is doing](#implementation)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Getting Involved - How to go deaper](#involved)
7. [Development - Guide for contributing to the module](#development)
8. [Contributors - Those with commits](#contributors)
9. [Release Notes - Notes on the most recent updates to the module](#release-notes)

Overview
--------

The Openstack Puppet Modules are a flexible Puppet implementation capable of configuring the core [Openstack](http://docs.openstack.org/) services:

* [nova](http://nova.openstack.org/)         (compute service)
* [glance](http://glance.openstack.org/)     (image database)
* [swift](http://swift.openstack.org/)       (object store)
* [keystone](http://keystone.openstack.org/) (authentication/authorization)
* [horizon](http://horizon.openstack.org/)   (web front end)
* [cinder](http://cinder.openstack.org/)     (block storage exporting)

[Puppet Modules](http://docs.puppetlabs.com/learning/modules1.html#modules) are a collection of related contents that can be used to model the configuration of a discrete service.

These Puppet modules are based on the [openstack documentation](http://docs.openstack.org/).

Module Description
------------------

There are a lot of moving pieces in Openstack, consequently there are several Puppet modules needed to cover all these pieces.  Each module is then made up of several class definitions, resource declarations, defined resources, and custom types/providers.  A common pattern to reduce this complexity in Puppet is to create a composite module that bundles all these component type modules into a common set of configurations.  The openstack module is doing this compositing and exposing a set of variables needed to be successful in getting a functional stack up and running.  Multiple companies and individuals contributed to this module with the goal of producing a quick way to build single and multi-node installations that was based off documented Openstack best practices.

**Pre-module Dependencies**

* [Puppet](http://docs.puppetlabs.com/puppet/) 2.7.12 or greater
* [Facter](http://www.puppetlabs.com/puppet/related-projects/facter/) 1.6.1 or greater (versions that support the osfamily fact)

**Platforms**

* These modules have been fully tested on Ubuntu Precise and Debian Wheezy and RHEL 6.
* The instructions in this document have only been verified on Ubuntu Precise.  For instructions of how to use these modules on Debian, check out this excellent [link](http://wiki.debian.org/OpenStackPuppetHowto)

Setup
-----

**What the openstack module affects**

* The entirety of Openstack!

### Installing Puppet

Puppet Labs provides two tools for getting started with managing configuration modeling with Puppet, Puppet Enterprise or its underlying opensource projects, i.e. Puppet and MCollective.

* [Puppet Enterprise](http://docs.puppetlabs.com/#puppet-enterprisepelatest) is a complete configuration management platform, with an optimized set of components proven to work well together.  Is free up to 10 nodes so if you're just using Puppet for Openstack management this might just work perfectly.  It will come configured with a handful of extra components that make for a richer experience, like a web interface for managing the orchestration of Puppet and certificate management.
* [Puppet](http://docs.puppetlabs.com/#puppetpuppet) manages your servers: you describe machine configurations in an easy-to-read declarative language, and Puppet will bring your systems into the desired state and keep them there.  This is the opensource version of Puppet and should be available in your operating system's package repositories but it is generally suggested you use the [yum](http://yum.puppetlabs.com) or [apt](http://apt.puppetlabs.com) repositories from Puppet Labs if possible.

Consult the documentation linked above to help you make your decision but don't fret about the choice to much, opensource Puppet agents are compatible with Puppet Enterprise Puppet masters.

### Optional Puppet features

The swift portions of this module needs Puppet's [exported resources](http://docs.puppetlabs.com/puppet/3/reference/lang_exported.html).  Exported resources leverages the PuppetDB to export and share data across other Puppet managed nodes.

### Installing openstack

    puppet module install puppetlabs/openstack

### Installing latest unstable openstack module from source

    cd /etc/puppet/modules
    git clone git://github.com/stackforge/puppet-openstack.git openstack
    cd openstack
    gem install librarian-puppet
    librarian-puppet install --path ../

**Pre-puppet setup**

The things that follow can be handled by Puppet but are out of scope of this document and are not included in the openstack module.

### Networking

* Each of the machines running the Openstack services should have a minimum of 2 NICS.
  * One for the public/internal network
    - This nic should be assigned an IP address
  * One of the virtual machine network
    - This nic should not have an ipaddress assigned
* If machines only have one NIC, it is necessary to manually create a bridge called br100 that bridges into the ip address specified on that NIC.
* All interfaces that are used to bridge traffic for the internal network need to have promiscuous mode set.
* Below is an example of setting promiscuous mode on an interface on Ubuntu.

```
#/etc/network/interfaces
auto eth1
iface eth1 inet manual
    up ifconfig $IFACE 0.0.0.0 up
    up ifconfig $IFACE promisc
```
### Volumes

Every node that is configured to be a cinder volume service must have a volume group called `cinder-volumes`.

### Compute nodes

* Compute nodes should be deployed onto physical hardware.
* If compute nodes are deployed on virtual machines for testing, the `libvirt_type` parameter for the `openstack::compute` class should probably be configured as `qemu`.  This is because most virtualization technologies do not pass the virtualization CPU extensions through to their virtual machines.

```puppet
class { 'openstack::compute':
  libvirt_type => 'qemu'
}
```

**or**

```puppet
class { 'openstack::all':
  libvirt_type => 'qemu'
}
```

### Beginning with openstack

Utlization of this module can come in many forms.  It was designed to be capable of deploying all services to a single node or distributed across several.  This is not an exhaustive list, we recommend you consult and understand all the manifests included in this module and the [core openstack](http://docs.openstack.org) documentation.

**Defining an all in one configuration**

The `openstack::all` class provides a single configuration interface that can be
used to deploy all Openstack services on a single host.

This is a great starting place for people who are just kicking the tires with
Openstack or with Puppet deployed OpenStack environments.

```puppet
class { 'openstack::all':
  public_address       => '192.168.1.12',
  public_interface     => 'eth0',
  private_interface    => 'eth1',
  admin_email          => 'some_admin@some_company',
  admin_password       => 'admin_password',
  keystone_admin_token => 'keystone_admin_token',
  keystone_db_password => 'keystone_db_password',
  cinder_db_password   => 'cinder_db_password',
  cinder_user_password => 'cinder_user_password',
  nova_user_password   => 'nova_user_password',
  nova_db_password     => 'nova_db_password',
  glance_user_password => 'glance_user_password',
  glance_db_password   => 'glance_db_password',
  rabbit_password      => 'rabbit_password',
  rabbit_user          => 'rabbit_user',
  libvirt_type         => 'kvm',
  fixed_range          => '10.0.0.0/24',
  secret_key           => '12345',
  neutron              => false,
  mysql_root_password  => 'mysql_root_password',
}
```

For more information on the parameters, check out the inline documentation in the [manifest](https://github.com/stackforge/puppet-openstack/blob/master/manifests/all.pp).

**Defining a controller configuration**

The `openstack::controller` class is intended to provide basic support for multi-node Openstack deployments.

There are two roles in this basic multi-node Openstack deployment:
  * controller - deploys all of the central management services
  * compute    - deploys the actual hypervisor on which VMs are deployed.

The `openstack::controller` class deploys the following Openstack services:
  * keystone
  * horizon
  * glance
  * nova (ommitting the nova compute service and, when multi_host is enabled,
    the nova network service)
  * mysql
  * rabbitmq

```puppet
class { 'openstack::controller':
  public_address          => '192.168.101.10',
  public_interface        => 'eth0',
  private_interface       => 'eth1',
  internal_address        => '192.168.101.10',
  floating_range          => '192.168.101.64/28',
  fixed_range             => '10.0.0.0/24',
  multi_host              => false,
  network_manager         => 'nova.network.manager.FlatDHCPManager',
  admin_email             => 'root@localhost',
  admin_password          => 'admin_password',
  cinder_db_password      => 'cinder_db_password',
  cinder_user_password    => 'cinder_user_password',
  keystone_admin_token    => 'keystone_admin_token',
  keystone_db_password    => 'keystone_db_password',
  glance_user_password    => 'glance_user_password',
  glance_db_password      => 'glance_db_password',
  nova_db_password        => 'nova_db_password',
  nova_user_password      => 'nova_user_password',
  rabbit_password         => 'rabbit_password',
  rabbit_user             => 'rabbit_user',
  secret_key              => '12345',
  neutron                 => false,
}
```

For more information on the parameters, check out the inline documentation in the [manifest](https://github.com/stackforge/puppet-openstack/blob/master/manifests/controller.pp)

**Defining a compute configuration**

The `openstack::compute` class is used to manage the underlying hypervisor.  A typical multi-host Openstack installation would consist of a single `openstack::controller` node and multiple `openstack::compute` nodes (based on the amount of resources being virtualized)

The `openstack::compute` class deploys the following services:
  * nova
    - compute service (libvirt backend)
    - optionally, the nova network service (if multi_host is enabled)
    - optionally, the nova api service (if multi_host is enabled)
    - optionally, the nova volume service if it is enabled

```puppet
class { 'openstack::compute':
  private_interface  => 'eth1',
  internal_address   => $::ipaddress_eth0,
  libvirt_type       => 'kvm',
  fixed_range        => '10.0.0.0/24',
  network_manager    => 'nova.network.manager.FlatDHCPManager',
  multi_host         => false,
  rabbit_host        => '192.168.101.10',
  rabbit_password    => 'rabbit_password',
  cinder_db_password => 'cinder_db_password',
  glance_api_servers => '192.168.101.10:9292',
  nova_db_password   => 'nova_db_password',
  nova_user_password => 'nova_user_password',
  vncproxy_host      => '192.168.101.10',
  vnc_enabled        => true,
  manage_volumes     => true,
  neutron            => false,
}
```

For more information on the parameters, check out the inline documentation in the [manifest](https://github.com/stackforge/puppet-openstack/blob/master/manifests/compute.pp)

Implementation
--------------

### Creating your deployment scenario

So far, classes have been discussed as configuration interfaces used to deploy the openstack roles. This section explains how to apply these roles to actual nodes using a puppet site manifest.

The default file name for the site manifest is `site.pp`. This file should be contained in the puppetmaster's manifestdir:

* open source puppet - /etc/puppet/manifests/site.pp
* Puppet Enterprise - /etc/puppetlabs/puppet/manifests/site.pp

Node blocks are used to map a node's certificate name to the classes that should be assigned to it.

[Node blocks](http://docs.puppetlabs.com/guides/language_guide.html#nodes) can match specific hosts:

```puppet
node my_explicit_host { }
```

Or they can use regular expression to match sets of hosts

```puppet
node /my_similar_hosts/ { }
```

Inside the `site.pp` file, Puppet resources declared within node blocks are applied to those specified nodes. Resources specified at top-scope are applied to all nodes.

### Deploying an Openstack all-in-one environment

The easiest way to get started with the `openstack::all` class is to use the file

    <module_dir>/openstack/tests/site.pp

There is a node entry for

```puppet
node /openstack_all/ { }
```

that can be used to deploy a simple nova all-in-one environment.

You can explicitly target this node entry by specifying a matching certname and targeting the manifest explicitly with:

    puppet apply /etc/puppet/modules/openstack/tests/site.pp --certname openstack_all

You could also update `site.pp` with the hostname of the node on which you wish to perform an all-in-one installation:

```puppet
node /<my_node>/ { }
```
If you wish to provision an all-in-one host from a remote puppetmaster, you can run the following command:

    puppet agent -td

### Deploying an Openstack multi-node environment

A Puppet Master should be used when deploying multi-node environments.

The example modules and `site.pp` should be installed on the Master.

This file contains entries for:

```puppet
node /openstack_controller/ { }

node /openstack_compute/ { }
```
Which can be used to assign the respective roles.

(As above, you can replace these default certificate names with the hostnames of your nodes)

The first step for building out a multi-node deployment scenario is to choose the IP address of the controller node.

Both nodes will need this configuration parameter.

In the example `site.pp`, replace the following line:

```puppet
$controller_node_address = <your_node_ip>
```
with the IP address of your controller.

It is also possible to use store configs in order for the compute hosts to automatically discover the address of the controller host. Documentation for this may not be available until a later release of the openstack modules.

Once everything is configured on the master, you can configure the nodes using:

    puppet agent -t <--certname ROLE_CERTNAME>

It is recommended that you first configure the controller before configuring your compute nodes:

    openstack_controller> puppet agent -t --certname openstack_controller
    openstack_compute1>   puppet agent -t --certname openstack_compute1
    openstack_compute2>   puppet agent -t --certname openstack_compute2

### Verifying an OpenStack deployment

Once you have installed openstack using Puppet (and assuming you experience no errors), the next step is to verify the installation:

### openstack::auth_file

The `openstack::auth_file` class creates the file:

    /root/openrc

which stores environment variables that can be used for authentication of openstack command line utilities.

#### Usage Example:

```puppet
class { 'openstack::auth_file':
  admin_password       => 'my_admin_password',
  controller_node      => 'my_controller_node',
  keystone_admin_token => 'my_admin_token',
}
```
### Verification Process

  1. Ensure that your authentication information is stored in /root/openrc.  This assumes that the class `openstack::auth_file` had been applied to this node.
  2. Ensure that your authenthication information is in the user's environment.

        source /root/openrc

  3. Verify that all of the services for nova are operational:

        > nova-manage service list
        Binary           Host          Zone   Status     State Updated_At
        nova-volume      <your_host>   nova   enabled    :-)   2012-06-06 22:30:05
        nova-consoleauth <your_host>   nova   enabled    :-)   2012-06-06 22:30:04
        nova-scheduler   <your_host>   nova   enabled    :-)   2012-06-06 22:30:05
        nova-compute     <your_host>   nova   enabled    :-)   2012-06-06 22:30:02
        nova-network     <your_host>   nova   enabled    :-)   2012-06-06 22:30:07
        nova-cert        <your_host>   nova   enabled    :-)   2012-06-06 22:30:04

  4. Ensure that the test script has been deployed to the node.

    ```puppet
    include openstack::test_file
    ```
  5. Run the test script.

        bash /tmp/test_nova.sh

    This script will verify that an image can be inserted into glance, and that that image can be used to fire up a virtual machine instance.

  6. Log into horizon on port 80 of your controller node and walk through a few operations:

         - fire up a VM
         - create a volume
         - attach that volume to the VM
         - allocate a floating IP address to a VM instance.
         - verify that voluem is actually attached to the VM and that
           it is reachable by its floating ip address (which will require
           some security groups)

### Building your own custom deployment scenario for Openstack

The classes included in the Openstack module are implemented using a number of other modules. These modules can be used directly to create a customized openstack deployment.

The full list of modules, their source locations, as well as the revisions that have been tested are available in the file .fixtures.yaml.

These building block modules have been written to support a wide variety of specific configuration and deployment use cases. They also provide a lot of configuration options not available with the more constrained puppetlabs-openstack modules.

The manifests in the Openstack module can serve as an example of how to use these base building block to compose custom deployments.

    <module_path>/openstack/manifests/{all,controller,compute}.pp

These files contain examples of how to deploy the following services:

* nova
  * api
  * scheduler
  * volumes
  * compute
  * network
* keystone
* glance
  * api
  * registry
* horizon
* database
  * examples only exist for Mysql and Sqlite (there is work underway for postgresql)
* message queue
  * examples currently only exist for rabbitmq

Once you have selected which services need to be combined on which nodes, you should review the modules for all of these services and figure out how you can configure things like the pipelines and back-ends for these individual services.

This information should then be used to compose your own custom `site.pp`

## Deploying swift

In order to deploy swift, you should use the example manifest that comes with the swift modules (tests/site.pp)

In this example, the following nodes are specified:

* swift_proxy
  - used as the ringbuilder + proxy node
* swift_storage_1
  - used as a storage node
* swift_storage_2
  - used as a storage node
* swift_storage_3
  - used as a storage node

This swift configuration requires both a puppetmaster with storeconfigs enabled.

To fully configure a Swift environment, the nodes must be configured in the following order:

* First the storage nodes need to be configured. This creates the storage services (object, container, account) and exports all of the storage endpoints for the ring builder into storeconfigs. (The replicator service fails to start in this initial configuration)
* Next, the ringbuild and swift proxy must be configured. The ringbuilder needs to collect the storage endpoints and create the ring database before the proxy can be installed. It also sets up an rsync server which is used to host the ring database.  Resources are exported that are used to rsync the ring database from this server.
* Finally, the storage nodes should be run again so that they can rsync the ring databases.

This configuration of rsync create two loopback devices on every node. For more realistic scenarios, users should deploy their own volumes in combination with the other classes.

Better examples of this will be provided in a future version of the module.

Limitations
-----------

* Deploys only with rabbitmq and mysql RPC/data backends.
* Not backwards compatible with pre-2.x release of the openstack modules.

### Upgrade warning

The current version of the code is intended for the 2.x series of the openstack modules and has the following known backwards incompatible breaking changes from 1.x.

* The cinder parameter has been removed (b/c support for nova-volumes has been removed).  The manage_volumes parameter indicates if cinder volumes should be managed.
* The names of the sql connection parameters of the `openstack::compute` class have changed from sql_connetion to individual parameters for the db user,name,password,host.

Getting Involved
----------------

Need a feature? Found a bug? Let me know!

We are extremely interested in growing a community of OpenStack experts and users around these modules so they can serve as an example of consolidated best practices of how to deploy openstack.

The best way to get help with this set of modules is to email the group associated with this project:

  puppet-openstack@puppetlabs.com

Issues should be opened here:

  https://launchpad.net/puppet-openstack

The process for contributing code is as follows:

* stackforge/puppet-openstack uses Gerrit for code review.
* Please visit http://wiki.openstack.org/GerritWorkflow and follow the instructions there to upload your change to Gerrit.
* Please add rspec tests for your code if applicable

Development
-----------

Developer documentation for the entire puppet-openstack project.

* https://wiki.openstack.org/wiki/Puppet-openstack#Developer_documentation

Contributors
------------

* https://github.com/stackforge/puppet-openstack/graphs/contributors

Release Notes
-------------

**2.2.0**

* Added support for syslog.
* Added passing keystone_host to controller class to support non-local keystone server.
* Added parameter for memcached_servers to support multiple memcache servers.
* Fixed bug to make vncserver_listen default to internal_address if not set.
* Added force_config_drive to openstack::all.
* Added support for rdb volumes.
* Added support for rdb as glance backend.
* Added ovs network provider.
* Added support for keystone token_format and token_driver.
* Fixed reference to 'quantum' repository to reflect upstream change to puppet-neutron.
* Added support for security_group_api.
* Fixed swift keystone authentication endpoints.
* Fixed selinux logic for horizon.

**2.1.0**

* Added support for Neutron OVS VLAN networking.
* Added Neutron firewall driver at top scope parameter.
* Added support for Glance Registry MySQL Idle Timeout
* Added support for debug logging.
* Added rdb/ceph backend support to Glance.
* Added rdb/ceph backend support to Cinder.
* Added support for splitting proxy and storage networks.
* Added support for memcached.
* Added support for RabbitMQ clustering.
* Added support for Nova API Bind Address.
* Added support for SQL Idle Timeout.
* Added suport for debug logging.
* Added support for RabbitMQ mirrored queues.
* Added support for RDO setup on additional RedHat based systems.
* Added swift_public_address.
* Added configuration for Swift auth in controller.
* Reintroduces support for provider networks.
* Propogates both internal and admin addresses to services.
* Passes through neutron core plugin.
* Exposes public_protocol parameter in openstack::controller.
* Exposes Glance registry_host parameter.
* Fixed authentication host parameter bug to use real_keystone_host.
* Fixed selinux Horizon bug.
* Fixed Keystone 'token-get' bug.
* Removed unneeded ovs_local_ip error message.
* Disabled dhcp on provisioned public subnet.
* Allows ovs_enable_tunneling to be passed through.
* Pinned module dependencies.
* Various lint and bug fixes.

**2.0.0**

* Upstream is now part of stackfoge.
* Initial support for the utilization of the neutron module.
* Ability to set vncproxy host.
* Refactors of db connections for compute.
* Refactor of glance and cinder related classes.
* Nova-conductor added.
* Various cleanups and bug fixes.
* Removes Puppet 3.2 deprecation warnings in templates.
* Adds the option to automatically set up RedHat or Ubuntu supplemental repositories.
* Class['openstack::all'] refactor that adds support of future compute nodes to be added.
* The cinder-volume logical volume group is no longer a requirement.
* Swift can use the disk storage_type
