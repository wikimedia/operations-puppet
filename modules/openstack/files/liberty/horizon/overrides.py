#  --  Tidy up the instance creation panel  --

from  openstack_dashboard.dashboards.project.instances.workflows import create_instance
#  Remove a couple of unwanted tabs from the instance creation panel:
#   PostCreationStep just provides confusing competition with puppet.
#   SetAdvanced provides broken features like configdrive and partitioning.

create_instance.LaunchInstance.default_steps = (create_instance.SelectProjectUser,
                                                create_instance.SetInstanceDetails,
                                                create_instance.SetAccessControls,
                                                create_instance.SetNetwork)
