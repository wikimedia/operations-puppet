#!/usr/bin/perl
# ============================================================================
# ============================== INFO ========================================
# ============================================================================
# Version	: 0.7
# Date		: February 21 2011
# Author	: Michiel Timmers ( michiel.timmers AT gmx.net)
# Based on	: "check_snmp_env" plugin (version 1.3) from Patrick Proy
# Licence 	: GPL - summary below
#
# ============================================================================
# ============================== SUMMARY =====================================
# ============================================================================
# This plugin is an enhancement on the "check_snmp_env" plugin (version 1.3) 
# from Patrick Proy. The basic function of this script is to check various 
# hardware based information, like power supply's, fans, cards, modules etc.
# Although some of the checks in this plugin are also in the "check_snmp_env"
# I strongly suggest using this version as some of the checks in 
# "check_snmp_env" aren't efficient or don't give alarms. 
#
# The default SNMP version has been changed from SNMPv1 to SNMPv2c because 
# of the use of SNMP Bulk option which is more efficient. SNMPv3 also 
# uses SNMP Bulk.
#
# This scrip supports IPv6. You can use the "-6" switch for this.
#
# ============================================================================
# ============================== SUPPORTED CHECKS ============================
# ============================================================================
# The following check are supported: 
#
# NOTE(!!): There are several Cisco checks, on many Cisco devices multiple 
# Cisco checks will functions.
#
# cisco __________: Cisco Systems : Fan, power-supply, voltage, temperature
# ciscoSW ________: Cisco Systems : Card and module status check
# ciscoNEW _______: Cisco Systems : Sensor check for devices that have 
#		    the CISCO-ENTITY-SENSOR-MIB
# nokia __________: Nokia IP : Fan, power-supply
# bc _____________: Blue Coat Systems : Fan, power-supply, voltage, disk
# iron ___________: IronPort : Fan, power-supply, temperature
# foundry ________: Foundry Network : power supply, temperature
# linux __________: lm-sensors : Fan, voltage, temperature, misc
# extremeSW ______: Extreme Networks : Slot, power-supply, fan, temperature
# juniper ________: Juniper Networks : Component status check
# procurve _______: HP ProCurve : Fan, power-supply, temperature
# netscreen ______: NetScreen : Slot, fan, power-supply
# citrix _________: Citrix NetScaler : Fan, , voltage, temperture, 
#		    HA state, SSL engine
# transmode ______: Transmode Systems : Check alarm table that is 
#		    not deactivated and not acknowledged
#
# Check the http://exchange.nagios.org website for new versions.
# For comments, questions, problems and patches send me an 
# e-mail (michiel.timmmers AT gmx.net). 
#
# ============================================================================
# ============================== TODO ========================================
# ============================================================================
# - cisco / ciscoSW and ciscoNEW needs to be checked regarding OID's
# - Make use of "set_status" subroutine for all checks
# - "linux" check does nothing (need all possible values of lm-sensors 
#   to implement). Perhaps IPMI support, currently lacks general MIB
# - "cisco","nokia","ironport","foundry","linux" needs clean up, need 
#   snmpwalks for this
# - Make more use of verbose output
# - utils.pm will become deprecated. Replacement with Nagios::Plugin?
#   What are the effects of switching to Nagios::Plugin?
#
# ============================================================================
# ============================== VERSIONS ====================================
# ============================================================================
# version 0.2 : - juniper: Ignores a "Unknown" PCMCIA card
#		- Juniper: Standby(7) wasn't defined correctly  
#		- juniper: Instance id's longer than 7 characters were failing
# version 0.3 : - ciscoSW: Corrected the modules OID for Cisco
#		- ciscoSW: Standby cards don't generate critical status anymore 
# version 0.4 : - extreme: Added support for devices from Extreme Networks
# version 0.5 : - juniper: J series routers now supported
# version 0.6 : - general: Added support for IPv6 communication
# version 0.7 : - ciscoNEW: Support for Cisco with CISCO-ENTITY-SENSOR-MIB
#		- procurve: Support for HP ProCurve
#		- netscreen: Support for Netscreen
#		- citrix: Support for Citrix Netscaler
#		- transmode: Support for Transmode
#		- extreme: Added checks for power-supply, fans and temperature
#		- juniper: 
#		- bc: Blue Coat check wasn't working properly 
#		- general: Default SNMP version is now SNMPv2c
#		- general: Switch default SNMPv3 from md5/des to sha/aes
#		- general: Lots of small fixes
#
# ============================================================================
# ============================== LICENCE =====================================
# ============================================================================
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# ============================================================================
# ============================== HELP ========================================
# ============================================================================
# Help : ./check_snmp_environment.pl --help
#
# ============================================================================

use warnings;
use strict;
use Net::SNMP;
use Getopt::Long;
#use lib "/usr/local/nagios/libexec";
#use utils qw(%ERRORS $TIMEOUT);


# ============================================================================
# ============================== NAGIOS VARIABLES ============================
# ============================================================================

my $TIMEOUT 				= 15;	# This is the global script timeout, not the SNMP timeout
my %ERRORS				= ('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);
my @Nagios_state 			= ("UNKNOWN","OK","WARNING","CRITICAL"); # Nagios states coding


# ============================================================================
# ============================== OID VARIABLES ===============================
# ============================================================================

# System description 
my $sysdescr				= "1.3.6.1.2.1.1.1.0";			# Global system description

# CISCO-ENVMON-MIB
my $ciscoEnvMonMIB			= "1.3.6.1.4.1.9.9.13"; 		# Cisco env base table
my %CiscoEnvMonState 			= (1,"normal",2,"warning",3,"critical",4,"shutdown",5,"notPresent",6,"notFunctioning"); # Cisco states
my %CiscoEnvMonNagios 			= (1,1 ,2,2 ,3,3 ,4,3 ,5,0, 6,3); 	# Nagios states returned for CIsco states (coded see @Nagios_state).
my $ciscoVoltageTable 			= $ciscoEnvMonMIB.".1.2.1"; 		# Cisco voltage table
my $ciscoVoltageTableIndex 		= $ciscoVoltageTable.".1"; 		#Index table
my $ciscoVoltageTableDesc 		= $ciscoVoltageTable.".2"; 		#Description
my $ciscoVoltageTableValue 		= $ciscoVoltageTable.".3"; 		#Value
my $ciscoVoltageTableState 		= $ciscoVoltageTable.".7"; 		#Status

my $ciscoTempTable 			= $ciscoEnvMonMIB.".1.3.1"; 		# Cisco temprature table
my $ciscoTempTableIndex 		= $ciscoTempTable.".1"; 		#Index table
my $ciscoTempTableDesc 			= $ciscoTempTable.".2"; 		#Description
my $ciscoTempTableValue 		= $ciscoTempTable.".3"; 		#Value
my $ciscoTempTableState 		= $ciscoTempTable.".6"; 		#Status

my $ciscoFanTable 			= $ciscoEnvMonMIB.".1.4.1"; 		# Cisco fan table
my $ciscoFanTableIndex 			= $ciscoFanTable.".1"; 			#Index table
my $ciscoFanTableDesc 			= $ciscoFanTable.".2"; 			#Description
my $ciscoFanTableState 			= $ciscoFanTable.".3";			#Status

my $ciscoPSTable 			= $ciscoEnvMonMIB.".1.5.1";	 	# Cisco power supply table
my $ciscoPSTableIndex 			= $ciscoPSTable.".1"; 			#Index table
my $ciscoPSTableDesc			= $ciscoPSTable.".2"; 			#Description
my $ciscoPSTableState 			= $ciscoPSTable.".3"; 			#Status

# Nokia env mib 
my $nokia_temp_tbl			= "1.3.6.1.4.1.94.1.21.1.1.5";
my $nokia_temp				= "1.3.6.1.4.1.94.1.21.1.1.5.0";
my $nokia_fan_table			= "1.3.6.1.4.1.94.1.21.1.2";
my $nokia_fan_status			= "1.3.6.1.4.1.94.1.21.1.2.1.1.2";
my $nokia_ps_table			= "1.3.6.1.4.1.94.1.21.1.3";
my $nokia_ps_temp			= "1.3.6.1.4.1.94.1.21.1.3.1.1.2";
my $nokia_ps_status			= "1.3.6.1.4.1.94.1.21.1.3.1.1.3";

# Bluecoat env mib
my @bc_SensorCode			= ("","ok","unknown","not-installed","voltage-low-warning","voltage-low-critical",
					"no-power","voltage-high-warning","voltage-high-critical","voltage-high-severe",
					"temperature-high-warning","temperature-high-critical","temperature-high-severe",
					"fan-slow-warning","fan-slow-critical","fan-stopped"); # BC element status returned by MIB
my @bc_status_code			= (3,0,3,3,1,2,2,1,2,2,1,2,2,1,2,2); 	# nagios status equivallent to BC status
my @bc_SensorStatus			= ("","ok","unavailable","nonoperational"); # ok(1),unavailable(2),nonoperational(3)
my @bc_status_sensor			= (3,0,1,2); 				# nagios status equivallent to BC status
my @bc_mesure				= ("","","","Enum","volts","celsius","rpm");
my $bc_sensor_table			= "1.3.6.1.4.1.3417.2.1.1.1.1.1"; 	# sensor table
my $bc_sensor_Units 			= "1.3.6.1.4.1.3417.2.1.1.1.1.1.3"; 	# cf bc_mesure
my $bc_sensor_Scale 			= "1.3.6.1.4.1.3417.2.1.1.1.1.1.4"; 	# * 10^value
my $bc_sensor_Value 			= "1.3.6.1.4.1.3417.2.1.1.1.1.1.5"; 	# value
my $bc_sensor_Code 			= "1.3.6.1.4.1.3417.2.1.1.1.1.1.6"; 	# bc_SensorCode
my $bc_sensor_Status 			= "1.3.6.1.4.1.3417.2.1.1.1.1.1.7"; 	# bc_SensorStatus
my $bc_sensor_Name 			= "1.3.6.1.4.1.3417.2.1.1.1.1.1.9"; 	# name
my $bc_dsk_table 			= "1.3.6.1.4.1.3417.2.2.1.1.1.1";	# disk table
my $bc_dsk_status 			= "1.3.6.1.4.1.3417.2.2.1.1.1.1.3"; 	# bc_DiskStatus - present(1), initializing(2), inserted(3), offline(4), removed(5), not-present(6), empty(7), bad(8), unknown(9
my $bc_dsk_vendor 			= "1.3.6.1.4.1.3417.2.2.1.1.1.1.5"; 	# bc_DiskStatus
my $bc_dsk_product 			= "1.3.6.1.4.1.3417.2.2.1.1.1.1.6"; 	# bc_DiskStatus
my $bc_dsk_serial 			= "1.3.6.1.4.1.3417.2.2.1.1.1.1.8"; 	# bc_DiskStatus
my @bc_DiskStatus			= ("","present","initializing","inserted","offline","removed","not-present","empty","bad","unknown");
my @bc_dsk_status_nagios		= (3,0,1,1,1,1,0,0,2,3);
		
# Iron Port env mib
my $iron_ps_table 			= "1.3.6.1.4.1.15497.1.1.1.8"; 		# power-supply table
my $iron_ps_status 			= "1.3.6.1.4.1.15497.1.1.1.8.1.2"; 	#powerSupplyNotInstalled(1), powerSupplyHealthy(2), powerSupplyNoAC(3), powerSupplyFaulty(4)
my @iron_ps_status_name			= ("","powerSupplyNotInstalled","powerSupplyHealthy","powerSupplyNoAC","powerSupplyFaulty");
my @iron_ps_status_nagios		= (3,3,0,2,2);
my $iron_ps_ha 				= "1.3.6.1.4.1.15497.1.1.1.8.1.3"; 	# ps redundancy status- powerSupplyRedundancyOK(1), powerSupplyRedundancyLost(2)
my @iron_ps_ha_name			= ("","powerSupplyRedundancyOK","powerSupplyRedundancyLost");
my @iron_ps_ha_nagios			= (3,0,1);
my $iron_ps_name 			= "1.3.6.1.4.1.15497.1.1.1.8.1.4"; 	# ps name
my $iron_tmp_table			= "1.3.6.1.4.1.15497.1.1.1.9"; 		# temp table
my $iron_tmp_celcius			= "1.3.6.1.4.1.15497.1.1.1.9.1.2"; 	# temp in celcius
my $iron_tmp_name			= "1.3.6.1.4.1.15497.1.1.1.9.1.3"; 	# name
my $iron_fan_table			= "1.3.6.1.4.1.15497.1.1.1.10"; 	# fan table
my $iron_fan_rpm			= "1.3.6.1.4.1.15497.1.1.1.10.1.2"; 	# fan speed in RPM
my $iron_fan_name			= "1.3.6.1.4.1.15497.1.1.1.10.1.3"; 	# fan name

# Foundry BigIron Router Switch (FOUNDRY-SN-AGENT-MIB)
my $foundry_temp 			= "1.3.6.1.4.1.1991.1.1.1.1.18.0"; 	# Chassis temperature in Deg C *2
my $foundry_temp_warn 			= "1.3.6.1.4.1.1991.1.1.1.1.19.0"; 	# Chassis warn temperature in Deg C *2
my $foundry_temp_crit 			= "1.3.6.1.4.1.1991.1.1.1.1.20.0"; 	# Chassis warn temperature in Deg C *2
my $foundry_ps_table			= "1.3.6.1.4.1.1991.1.1.1.2.1"; 	# PS table
my $foundry_ps_desc			= "1.3.6.1.4.1.1991.1.1.1.2.1.1.2"; 	# PS desc
my $foundry_ps_status			= "1.3.6.1.4.1.1991.1.1.1.2.1.1.3"; 	# PS status
my $foundry_fan_table			= "1.3.6.1.4.1.1991.1.1.1.3.1"; 	# FAN table
my $foundry_fan_desc			= "1.3.6.1.4.1.1991.1.1.1.3.1.1.2"; 	# FAN desc
my $foundry_fan_status			= "1.3.6.1.4.1.1991.1.1.1.3.1.1.3"; 	# FAN status
my @foundry_status 			= (3,0,2); 				# oper status : 1:other, 2: Normal, 3: Failure 

# lm-sensors
my $linux_env_table 			= "1.3.6.1.4.1.2021.13.16"; 		# Global env table
my $linux_temp				= "1.3.6.1.4.1.2021.13.16.2.1"; 	# temperature table
my $linux_temp_descr			= "1.3.6.1.4.1.2021.13.16.2.1.2"; 	# temperature entry description
my $linux_temp_value			= "1.3.6.1.4.1.2021.13.16.2.1.3"; 	# temperature entry value (mC)
my $linux_fan				= "1.3.6.1.4.1.2021.13.16.3.1"; 	# fan table
my $linux_fan_descr			= "1.3.6.1.4.1.2021.13.16.3.1.2"; 	# fan entry description
my $linux_fan_value			= "1.3.6.1.4.1.2021.13.16.3.1.3"; 	# fan entry value (RPM)
my $linux_volt				= "1.3.6.1.4.1.2021.13.16.4.1"; 	# voltage table
my $linux_volt_descr			= "1.3.6.1.4.1.2021.13.16.4.1.2"; 	# voltage entry description
my $linux_volt_value			= "1.3.6.1.4.1.2021.13.16.4.1.3"; 	# voltage entry value (mV)
my $linux_misc				= "1.3.6.1.4.1.2021.13.16.5.1"; 	# misc table
my $linux_misc_descr			= "1.3.6.1.4.1.2021.13.16.5.1.2"; 	# misc entry description
my $linux_misc_value			= "1.3.6.1.4.1.2021.13.16.5.1.3"; 	# misc entry value

# Cisco switches (catalys & IOS)
my $cisco_chassis_card_descr		= "1.3.6.1.4.1.9.3.6.11.1.3"; 		# Chassis card description
my $cisco_chassis_card_slot		= "1.3.6.1.4.1.9.3.6.11.1.7"; 		# Chassis card slot number
my $cisco_chassis_card_state		= "1.3.6.1.4.1.9.3.6.11.1.9"; 		# operating status of card - 1 : Not specified, 2 : Up, 3: Down, 4 : standby
my @cisco_chassis_card_status_text 	= ("Unknown","Not specified","Up","Down","Standby");
my @cisco_chassis_card_status 		= (2,2,0,2,0);
my $cisco_module_descr			= "1.3.6.1.2.1.47.1.1.1.1.13"; 		# Chassis card description
my $cisco_module_slot			= "1.3.6.1.4.1.9.5.1.3.1.1.25"; 	# Chassis card slot number
my $cisco_module_state			= "1.3.6.1.4.1.9.9.117.1.2.1.1.2"; 	# operating status of card - 	1:unknown, 2:ok, 3:disabled, 4:okButDiagFailed, 5:boot, 6:selfTest, 7:failed, 8:missing, 9:mismatchWithParent, 	
										#				10:mismatchConfig, 11:diagFailed, 12:dormant, 13:outOfServiceAdmin, 14:outOfServiceEnvTemp, 15:poweredDown, 16:poweredUp, 
										#				17:powerDenied, 18:powerCycled, 19:okButPowerOverWarning, 20:okButPowerOverCritical, 21:syncInProgress
my @cisco_module_status_text 		=("Unknown", "unknown", "OK", "Disabled", "OkButDiagFailed", "Boot", 
					"SelfTest", "Failed", "Missing", "MismatchWithParent", "MismatchConfig", 
					"DiagFailed", "Dormant", "OutOfServiceAdmin", "OutOfServiceEnvTemp", "PoweredDown", 
					"PoweredUp", "PowerDenied", "PowerCycled", "OkButPowerOverWarning", 
					"OkButPowerOverCritical", "SyncInProgress");
my @cisco_module_status 		= (3,3,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2);

# Juniper routers (JUNOS)
my $juniper_operating_descr		= "1.3.6.1.4.1.2636.3.1.13.1.5"; 	# Component description
my $juniper_operating_state		= "1.3.6.1.4.1.2636.3.1.13.1.6"; 	# Operating status of component-  Unknown(1), Running(2), Ready(3), Reset(4), RunningAtFullSpeed(5), Down(6), Standby(7)
my @juniper_operating_status_text 	= ("--Invalid--","Unknown","Running","Ready","Reset","RunningAtFullSpeed","Down","Standby");
my @juniper_operating_status	 	= (3,3,0,0,1,0,2,0);

# Extreme switches
my $extreme_slot_table			= "1.3.6.1.4.1.1916.1.1.2.2.1"; 
my $extreme_slot_name			= "1.3.6.1.4.1.1916.1.1.2.2.1.2"; 	# Component description
my $extreme_slot_state			= "1.3.6.1.4.1.1916.1.1.2.2.1.5"; 	# Operating status of component - NotPresent(1), testing(2), mismatch(3), failed(4), operational(5), powerdown(6), unknown(7)
my $extreme_slot_serialnumber		= "1.3.6.1.4.1.1916.1.1.2.2.1.6";
my @extreme_slot_state_text		= ("--Invalid--","NotPresent","Testing","Mismatch","Failed","Operational","Powerdown","Unknown");
my @extreme_slot_nagios 		= (3,0,2,2,2,0,2,3);
my $extreme_ps_table			= "1.3.6.1.4.1.1916.1.1.1.27.1";
my $extreme_ps_status			= "1.3.6.1.4.1.1916.1.1.1.27.1.2";
my @extreme_ps_status_text		= ("--Invalid--","notPresent","presentOK","presentNotOK");
my @extreme_ps_nagios		 	= (3,1,0,2);
my $extreme_fan_table			= "1.3.6.1.4.1.1916.1.1.1.9.1";
my $extreme_fan_number			= "1.3.6.1.4.1.1916.1.1.1.9.1.1";
my $extreme_fan_operational		= "1.3.6.1.4.1.1916.1.1.1.9.1.2";
my @extreme_fan_operational_text	= ("--Invalid--","Operational","Not operational");
my @extreme_fan_nagios		 	= (3,0,2);
my $extreme_temperature_alarm		= "1.3.6.1.4.1.1916.1.1.1.7.0";
my @extreme_temperature_alarm_text	= ("--Invalid--","OverTemperature","OK");
my @extreme_temperature_nagios		= (3,2,0);
my $extreme_temperature_current		= "1.3.6.1.4.1.1916.1.1.1.8.0";


# HP ProCurve switches
my $procurve_operating_descr    	= "1.3.6.1.4.1.11.2.14.11.1.2.6.1.7"; 	# Component description
my $procurve_operating_state    	= "1.3.6.1.4.1.11.2.14.11.1.2.6.1.4"; 	# Operating status of component - Unknown(1), Bad(2), Warning(3), Good(4), NotPresent(5)
my @procurve_operating_status_text 	= ("--Invalid--","Unknown","Bad","Warning","Good","NotPresent");
my @procurve_operating_status 		= (3,3,2,1,0,4);

# Netscreen
my $netscreen_slot_operating_descr     = "1.3.6.1.4.1.3224.21.5.1.2"; 		# Component description
my $netscreen_slot_operating_state     = "1.3.6.1.4.1.3224.21.5.1.3"; 		# Operating status of component - Fail?(0), Good(1)
my @netscreen_slot_operating_status_text = ("Fail","Good");
my @netscreen_slot_operating_status 	= (2,0);
my $netscreen_power_operating_descr     = "1.3.6.1.4.1.3224.21.1.1.3"; 		# Component description
my $netscreen_power_operating_state     = "1.3.6.1.4.1.3224.21.1.1.2"; 		# Operating status of component - Fail(0), Good(1)
my @netscreen_power_operating_status_text = ("Fail","Good");
my @netscreen_power_operating_status	= (2,0);
my $netscreen_fan_operating_descr     	= "1.3.6.1.4.1.3224.21.2.1.3";		# Component description
my $netscreen_fan_operating_state     	= "1.3.6.1.4.1.3224.21.2.1.2"; 		# Operating status of component - Fail(0), Good(1), Not Installed(2)
my @netscreen_fan_operating_status_text = ("Fail","Good","Not Installed");
my @netscreen_fan_operating_status 	= (2,0,4);

# Cisco CISCO-ENTITY-SENSOR-MIB
my $cisco_ios_xe_physicaldescr	    	= "1.3.6.1.2.1.47.1.1.1.1.7";
my $cisco_ios_xe_type     	    	= "1.3.6.1.4.1.9.9.91.1.1.1.1.1"; 
my @cisco_ios_xe_type_text	    	= ("not_specified","other","unknown","voltsAC","voltsDC","amperes","watts","hertz","celsius","percent","rpm","cmm","truthvalue","specialEnum","dBm");
my $cisco_ios_xe_scale     	    	= "1.3.6.1.4.1.9.9.91.1.1.1.1.2"; 
my @cisco_ios_xe_scale_power        	= ("0","-24","-21","-18","-15","12","e-9","e-6","e-3","e0","e3","e6","9","12","15","18","21","24"); 
my $cisco_ios_xe_precision	  	= "1.3.6.1.4.1.9.9.91.1.1.1.1.3"; 
my $cisco_ios_xe_value     	    	= "1.3.6.1.4.1.9.9.91.1.1.1.1.4"; 
my $cisco_ios_xe_status     	 	= "1.3.6.1.4.1.9.9.91.1.1.1.1.5"; 
my @cisco_ios_xe_operating_text		= ("--Invalid--","ok","unavailable","nonoperational");
my @cisco_ios_xe_operating_status   	= (0,1,2,3);
my $cisco_ios_xe_threshold_severity	= "1.3.6.1.4.1.9.9.91.1.2.1.1.2";
my $cisco_ios_xe_threshold_value    	= "1.3.6.1.4.1.9.9.91.1.2.1.1.4";

# Citrix NetScaler
my $citrix_desc     			= "1.3.6.1.4.1.5951.4.1.1.41.7.1.1"; 
my $citrix_value     			= "1.3.6.1.4.1.5951.4.1.1.41.7.1.2"; 
my $citrix_high_availability_state     	= "1.3.6.1.4.1.5951.4.1.1.23.24.0"; 
my @citrix_high_availability_state_text	= ("unknown","init","down","up","partialFail","monitorFail","monitorOk","completeFail","dumb","disabled","partialFailSsl","routemonitorFail");
my $citrix_ssl_engine_state     	= "1.3.6.1.4.1.5951.4.1.1.47.2.0"; 
my @citrix_ssl_engine_state_text	= ("down","up");

# Transmode WDM MIB/OID
my $transmode_table			= "1.3.6.1.4.1.11857.1.1.3.2.1"; 	# Alarm Active Entry table
my $transmode_alarm_rack                = "1.3.6.1.4.1.11857.1.1.3.2.1.2"; 	# Non Acked Alarm rack
my $transmode_alarm_slot                = "1.3.6.1.4.1.11857.1.1.3.2.1.3"; 	# Non Acked Alarm slot
my $transmode_alarm_descr               = "1.3.6.1.4.1.11857.1.1.3.2.1.4"; 	# Non Acked Alarm description
my $transmode_alarm_sev                 = "1.3.6.1.4.1.11857.1.1.3.2.1.5"; 	# Non Acked Alarm severity
my $transmode_alarm_unit                = "1.3.6.1.4.1.11857.1.1.3.2.1.6"; 	# Non Acked Alarm unit
my $transmode_alarm_serial              = "1.3.6.1.4.1.11857.1.1.3.2.1.7"; 	# Non Acked Alarm serial
my $transmode_alarm_time_start          = "1.3.6.1.4.1.11857.1.1.3.2.1.8"; 	# Time of Alarm Start
my $transmode_alarm_time_end            = "1.3.6.1.4.1.11857.1.1.3.2.1.9"; 	# Time of Alarm End
my @transmode_alarm_status_text         = ("Indeterminate","Critical","Major","Minor","Warning");
my @transmode_alarm_status              = (1,2,2,1,1);


# ============================================================================
# ============================== GLOBAL VARIABLES ============================
# ============================================================================

my $Version		= '0.7';	# Version number of this script
my $o_host		= undef; 	# Hostname
my $o_community 	= undef; 	# Community
my $o_port	 	= 161; 		# Port
my $o_help		= undef; 	# Want some help ?
my $o_verb		= undef;	# Verbose mode
my $o_version		= undef;	# Print version
my $o_timeout		= undef; 	# Timeout (Default 5)
my $o_perf		= undef;	# Output performance data
my $o_version1		= undef;	# Use SNMPv1
my $o_version2		= undef;	# Use SNMPv2c
my $o_domain		= undef;	# Use IPv6
my $o_check_type	= "cisco";	# Default check is "cisco"
my @valid_types		= ("cisco","nokia","bc","iron","foundry","linux","ciscoSW","extremeSW","juniper","procurve","netscreen","ciscoNEW","citrix","transmode");	
my $o_temp		= undef;	# Max temp
my $o_fan		= undef;	# Min fan speed
my $o_login		= undef;	# Login for SNMPv3
my $o_passwd		= undef;	# Pass for SNMPv3
my $v3protocols		= undef;	# V3 protocol list.
my $o_authproto		= 'sha';	# Auth protocol
my $o_privproto		= 'aes';	# Priv protocol
my $o_privpass		= undef;	# priv password


# ============================================================================
# ============================== SUBROUTINES (FUNCTIONS) =====================
# ============================================================================

# Subroutine: Print version
sub p_version { 
	print "check_snmp_environment version : $Version\n"; 
}

# Subroutine: Print Usage
sub print_usage {
    print "Usage: $0 [-v] -H <host> [-6] -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>])  [-p <port>] -T (cisco|ciscoSW|ciscoNEW|nokia|bc|iron|foundry|linux|extremeSW|juniper|procurve|netscreen|citrix|transmode) [-F <rpm>] [-c <celcius>] [-f] [-t <timeout>] [-V]\n";
}

# Subroutine: Check number
sub isnnum { # Return true if arg is not a number
	my $num = shift;
	if ( $num =~ /^(\d+\.?\d*)|(^\.\d+)$/ ) { return 0 ;}
	return 1;
}

# Subroutine: Set final status
sub set_status { # Return worst status with this order : OK, unknown, warning, critical 
	my $new_status = shift;
	my $cur_status = shift;
	if ($new_status == 1 && $cur_status != 2) {$cur_status = $new_status;}
	if ($new_status == 2) {$cur_status = $new_status;}
	if ($new_status == 3 && $cur_status == 0) {$cur_status = $new_status;}
	return $cur_status;
}

# Subroutine: Check if SNMP table could be retrieved, otherwise give error
sub check_snmp_result {
	my $snmp_table		= shift;
	my $snmp_error_mesg	= shift;

	# Check if table is defined and does not contain specified error message.
	# Had to do string compare it will not work with a status code
	if (!defined($snmp_table) && $snmp_error_mesg !~ /table is empty or does not exist/) {
		printf("ERROR: ". $snmp_error_mesg . " : UNKNOWN\n");
		exit $ERRORS{"UNKNOWN"};
	}
}

# Subroutine: Print complete help
sub help {
	print "\nSNMP environmental plugin for Nagios\nVersion: ",$Version,"\n\n";
	print_usage();
	print <<EOT;

Options:
-v, --verbose
   Print extra debugging information 
-h, --help
   Print this help message
-H, --hostname=HOST
   Hostname or IPv4/IPv6 address of host to check
-6, --use-ipv6
   Use IPv6 connection
-C, --community=COMMUNITY NAME
   Community name for the host's SNMP agent
-1, --v1
   Use SNMPv1
-2, --v2c
   Use SNMPv2c (default)
-l, --login=LOGIN ; -x, --passwd=PASSWD
   Login and auth password for SNMPv3 authentication 
   If no priv password exists, implies AuthNoPriv 
-X, --privpass=PASSWD
   Priv password for SNMPv3 (AuthPriv protocol)
-L, --protocols=<authproto>,<privproto>
   <authproto> : Authentication protocol (md5|sha : default sha)
   <privproto> : Priv protocole (des|aes : default aes) 
-P, --port=PORT
   SNMP port (Default 161)
-T, --type=cisco|ciscoSW|ciscoNEW|nokia|bc|iron|foundry|linux|extremeSW|juniper|procurve|netscreen|citrix|transmode
   Environmental check : 
	cisco __________: Cisco Systems : Fan, power-supply, voltage, temperature
	ciscoSW ________: Cisco Systems : Card and module status check
	ciscoNEW _______: Cisco Systems : Sensor check for devices that have the CISCO-ENTITY-SENSOR-MIB
	nokia __________: Nokia IP : Fan, power-supply
	bc _____________: Blue Coat Systems : Fan, power-supply, voltage, disk
	iron ___________: IronPort : Fan, power-supply, temperature
	foundry ________: Foundry Network : power supply, temperature
	linux __________: lm-sensors : Fan, voltage, temperature, misc
	extremeSW ______: Extreme Networks : Slot, power-supply, fan, temperature
	juniper ________: Juniper Networks : Component status check
        procurve _______: HP ProCurve : Fan, power-supply, temperature
        netscreen ______: NetScreen : Slot, fan, power-supply (ScreenOS 6.1 and newer)
	citrix _________: Citrix NetScaler : Fan, , voltage, temperture (thresholds are hardcoded), HA state, SSL engine
	transmode ______: Transmode Systems : Check alarm table that is not deactivated and not acknowledged
-F, --fan=<rpm>
   Minimum fan rpm value (only needed for 'iron' & 'linux')
-c, --celcius=<celcius>
   Maximum temp in degree celcius (only needed for 'iron' & 'linux')
-f, --perfparse
   Perfparse compatible output
-t, --timeout=INTEGER
   Timeout for SNMP in seconds (Default: 5)
-V, --version
   Prints version number

Notes:
- Check the http://exchange.nagios.org website for new versions.
- For questions, problems and patches send me an e-mail (michiel.timmmers AT gmx.net).

EOT
}

# Subroutine: Verbose output
sub verb { 
	my $t=shift; 
	print $t,"\n" if defined($o_verb); 
}

# Subroutine: Verbose output
sub check_options {
	Getopt::Long::Configure ("bundling");
	GetOptions(
		'v'	=> \$o_verb,		'verbose'	=> \$o_verb,
	        'h'     => \$o_help,    	'help'        	=> \$o_help,
	        'H:s'   => \$o_host,		'hostname:s'	=> \$o_host,
	        'p:i'   => \$o_port,   		'port:i'	=> \$o_port,
	        'C:s'   => \$o_community,	'community:s'	=> \$o_community,
		'l:s'	=> \$o_login,		'login:s'	=> \$o_login,
		'x:s'	=> \$o_passwd,		'passwd:s'	=> \$o_passwd,
		'X:s'	=> \$o_privpass,	'privpass:s'	=> \$o_privpass,
		'L:s'	=> \$v3protocols,	'protocols:s'	=> \$v3protocols,   
	        't:i'   => \$o_timeout,       	'timeout:i'     => \$o_timeout,
		'V'	=> \$o_version,		'version'	=> \$o_version,
		'6'     => \$o_domain,        	'use-ipv6'      => \$o_domain,
		'1'     => \$o_version1,        'v1'            => \$o_version1,
		'2'     => \$o_version2,        'v2c'           => \$o_version2,
	        'f'     => \$o_perf,            'perfparse'     => \$o_perf,
		'T:s'	=> \$o_check_type,	'type:s'	=> \$o_check_type,
	        'F:i'   => \$o_fan,             'fan:i'     	=> \$o_fan,
	        'c:i'   => \$o_temp,            'celcius:i'     => \$o_temp
	);

	# Check the -T option
	my $T_option_valid=0; 
	foreach (@valid_types) { 
		if ($_ eq $o_check_type) {
			$T_option_valid=1;
		} 
	}
	if ( $T_option_valid == 0 ) {
		print "Invalid check type (-T)!\n"; 
		print_usage(); 
		exit $ERRORS{"UNKNOWN"};
	}

	# Basic checks
	if (defined($o_timeout) && (isnnum($o_timeout) || ($o_timeout < 2) || ($o_timeout > 60))) { 
		print "Timeout must be >1 and <60 !\n";
		print_usage();
		exit $ERRORS{"UNKNOWN"};
	}
	if (!defined($o_timeout)) {
		$o_timeout=5;
	}
	if (defined ($o_help) ) {
		help();
		exit $ERRORS{"UNKNOWN"};
	}

	if (defined($o_version)) { 
		p_version(); 
		exit $ERRORS{"UNKNOWN"};
	}

	# check host and filter 
	if ( ! defined($o_host) ) {
		print_usage();
		exit $ERRORS{"UNKNOWN"};
	}

	# Check IPv6 
	if (defined ($o_domain)) {
		$o_domain="udp/ipv6";
	} else {
		$o_domain="udp/ipv4";
	}

	# Check SNMP information
	if ( !defined($o_community) && (!defined($o_login) || !defined($o_passwd)) ){ 
		print "Put SNMP login info!\n"; 
		print_usage(); 
		exit $ERRORS{"UNKNOWN"};
	}
	if ((defined($o_login) || defined($o_passwd)) && (defined($o_community) || defined($o_version2)) ){ 
		print "Can't mix SNMP v1,v2c,v3 protocols!\n"; 
		print_usage(); 
		exit $ERRORS{"UNKNOWN"};
	}

	# Check SNMPv3 information
	if (defined ($v3protocols)) {
		if (!defined($o_login)) { 
			print "Put SNMP V3 login info with protocols!\n"; 
			print_usage(); 
			exit $ERRORS{"UNKNOWN"};
		}
		my @v3proto=split(/,/,$v3protocols);
		if ((defined ($v3proto[0])) && ($v3proto[0] ne "")) {
			$o_authproto=$v3proto[0];
		}
		if (defined ($v3proto[1])) {
			$o_privproto=$v3proto[1];
		}
		if ((defined ($v3proto[1])) && (!defined($o_privpass))) {
			print "Put SNMP v3 priv login info with priv protocols!\n";
			print_usage(); 
			exit $ERRORS{"UNKNOWN"};
		}
	}
}


# ============================================================================
# ============================== MAIN ========================================
# ============================================================================

check_options();

# Check gobal timeout if SNMP screws up
if (defined($TIMEOUT)) {
	verb("Alarm at ".$TIMEOUT." + ".$o_timeout);
	alarm($TIMEOUT+$o_timeout);
} else {
	verb("no global timeout defined : ".$o_timeout." + 15");
	alarm ($o_timeout+15);
}

# Report when the script gets "stuck" in a loop or takes to long
$SIG{'ALRM'} = sub {
	print "UNKNOWN: Script timed out\n";
	exit $ERRORS{"UNKNOWN"};
};

# Connect to host
my ($session,$error);
if (defined($o_login) && defined($o_passwd)) {
	# SNMPv3 login
	verb("SNMPv3 login");
	if (!defined ($o_privpass)) {
		# SNMPv3 login (Without encryption)
		verb("SNMPv3 AuthNoPriv login : $o_login, $o_authproto");
		($session, $error) = Net::SNMP->session(
		-domain		=> $o_domain,
		-hostname	=> $o_host,
		-version	=> 3,
		-username	=> $o_login,
		-authpassword	=> $o_passwd,
		-authprotocol	=> $o_authproto,
		-timeout	=> $o_timeout
	);  
	} else {
		# SNMPv3 login (With encryption)
		verb("SNMPv3 AuthPriv login : $o_login, $o_authproto, $o_privproto");
		($session, $error) = Net::SNMP->session(
		-domain		=> $o_domain,
		-hostname	=> $o_host,
		-version	=> 3,
		-username	=> $o_login,
		-authpassword	=> $o_passwd,
		-authprotocol	=> $o_authproto,
		-privpassword	=> $o_privpass,
		-privprotocol	=> $o_privproto,
		-timeout	=> $o_timeout
		);
	}
} else {
	if ((defined ($o_version2)) || (!defined ($o_version1))) {
		# SNMPv2 login
		verb("SNMP v2c login");
		($session, $error) = Net::SNMP->session(
		-domain		=> $o_domain,
		-hostname	=> $o_host,
		-version	=> 2,
		-community	=> $o_community,
		-port		=> $o_port,
		-timeout	=> $o_timeout
		);
	} else {
		# SNMPv1 login
		verb("SNMP v1 login");
		($session, $error) = Net::SNMP->session(
		-domain		=> $o_domain,
		-hostname	=> $o_host,
		-version	=> 1,
		-community	=> $o_community,
		-port		=> $o_port,
		-timeout	=> $o_timeout
		);
	}
}

# Check if there are any problems with the session
if (!defined($session)) {
	printf("ERROR opening session: %s.\n", $error);
	exit $ERRORS{"UNKNOWN"};
}

my $exit_val=undef;


# ============================================================================
# ============================== CISCO =======================================
# ============================================================================

if ($o_check_type eq "cisco") {

verb("Checking cisco env");

# Get load table
my $resultat =  $session->get_table(Baseoid => $ciscoEnvMonMIB);
&check_snmp_result($resultat,$session->error);

# Get env data index
my (@voltindex,@tempindex,@fanindex,@psindex)=(undef,undef,undef,undef);
my ($voltexist,$tempexist,$fanexist,$psexist)=(0,0,0,0);
my @oid=undef;
foreach my $key ( keys %$resultat) {
   verb("OID : $key, Desc : $$resultat{$key}");
   if ( $key =~ /$ciscoVoltageTableDesc/ ) { 
      @oid=split (/\./,$key);
      $voltindex[$voltexist++] = pop(@oid);
   }
   if ( $key =~ /$ciscoTempTableDesc/ ) { 
      @oid=split (/\./,$key);
      $tempindex[$tempexist++] = pop(@oid);
   }
   if ( $key =~ /$ciscoFanTableDesc/ ) { 
      @oid=split (/\./,$key);
      $fanindex[$fanexist++] = pop(@oid);
   }
   if ( $key =~ /$ciscoPSTableDesc/ ) { 
      @oid=split (/\./,$key);
      $psindex[$psexist++] = pop(@oid);
   }
}

if ( ($voltexist ==0) && ($tempexist ==0) && ($fanexist ==0) && ($psexist ==0) ) {
  print "No Environemental data found : UNKNOWN \n";
  exit $ERRORS{"UNKNOWN"};
}

my $perf_output="";
# Get the data
my ($i,$cur_status)=(undef,undef); 

my $volt_global=0;
my %volt_status;
if ($fanexist !=0) {
  for ($i=0;$i < $voltexist; $i++) {
    $cur_status=$$resultat{$ciscoVoltageTableState. "." . $voltindex[$i]};
    verb ($$resultat{$ciscoVoltageTableDesc .".".$voltindex[$i]});
    verb ($cur_status);
    if (!defined ($cur_status)) { ### Error TODO
      $volt_global=1;
    } 
    if (defined($$resultat{$ciscoVoltageTableValue."." . $voltindex[$i]})) {
      $perf_output.=" '".$$resultat{$ciscoVoltageTableDesc .".".$voltindex[$i]}."'=" ;
      $perf_output.=$$resultat{$ciscoVoltageTableValue."." . $voltindex[$i]};
    }	
    if ($Nagios_state[$CiscoEnvMonNagios{$cur_status}] ne "OK") {
      $volt_global= 1;
      $volt_status{$$resultat{$ciscoVoltageTableDesc .".".$voltindex[$i]}}=$cur_status;
    }
  }
}


my $temp_global=0;
my %temp_status;
if ($tempexist !=0) {
  for ($i=0;$i < $tempexist; $i++) {
    $cur_status=$$resultat{$ciscoTempTableState . "." . $tempindex[$i]};
    verb ($$resultat{$ciscoTempTableDesc .".".$tempindex[$i]});
    verb ($cur_status);
    if (!defined ($cur_status)) { ### Error TODO
      $temp_global=1;
    }
    if (defined($$resultat{$ciscoTempTableValue."." . $tempindex[$i]})) {
      $perf_output.=" '".$$resultat{$ciscoTempTableDesc .".".$tempindex[$i]}."'=" ;
      $perf_output.=$$resultat{$ciscoTempTableValue."." . $tempindex[$i]};
    }
    if ($Nagios_state[$CiscoEnvMonNagios{$cur_status}] ne "OK") {
      $temp_global= 1;
      $temp_status{$$resultat{$ciscoTempTableDesc .".".$tempindex[$i]}}=$cur_status;
    }
  }
}

                
my $fan_global=0;
my %fan_status;
if ($fanexist !=0) {
  for ($i=0;$i < $fanexist; $i++) {
    $cur_status=$$resultat{$ciscoFanTableState . "." . $fanindex[$i]};
    verb ($$resultat{$ciscoFanTableDesc .".".$fanindex[$i]});
    verb ($cur_status);
    if (!defined ($cur_status)) { ### Error TODO
      $fan_global=1;
    }
    if ($Nagios_state[$CiscoEnvMonNagios{$cur_status}] ne "OK") {
      $fan_global= 1;
      $fan_status{$$resultat{$ciscoFanTableDesc .".".$fanindex[$i]}}=$cur_status;
    }
  }
}

my $ps_global=0;
my %ps_status;
if ($psexist !=0) {
  for ($i=0;$i < $psexist; $i++) {
    $cur_status=$$resultat{$ciscoPSTableState . "." . $psindex[$i]};
    if (!defined ($cur_status)) { ### Error TODO
      $fan_global=1;
    }
    if ($Nagios_state[$CiscoEnvMonNagios{$cur_status}] ne "OK") {
      $ps_global= 1;
      $ps_status{$$resultat{$ciscoPSTableDesc .".".$psindex[$i]}}=$cur_status;
    }
  }
}

my $global_state=0; 
my $output="";

if ($fanexist !=0) {
	if ($fan_global ==0) {
	   $output .= $fanexist." Fan OK";
	   $global_state=1 if ($global_state==0);
	} else {
	  foreach (keys %fan_status) {
	    $output .= "Fan " . $_ . ":" . $CiscoEnvMonState {$fan_status{$_}} ." ";
		if ($global_state < $CiscoEnvMonNagios{$fan_status{$_}} ) {
		  $global_state = $CiscoEnvMonNagios{$fan_status{$_}} ;
		}
	  }
	}
}

if ($psexist !=0) {
	$output .= ", " if ($output ne "");
	if ($ps_global ==0) {
	   $output .= $psexist." ps OK";
	   $global_state=1 if ($global_state==0);
	} else {
	  foreach (keys %ps_status) {
	    $output .= "ps " . $_ . ":" . $CiscoEnvMonState {$ps_status{$_}} ." ";
		if ($global_state < $CiscoEnvMonNagios{$ps_status{$_}} ) {
		  $global_state = $CiscoEnvMonNagios{$ps_status{$_}} ;
		}
	  }
	}
}

if ($voltexist !=0) {
	$output .= ", " if ($output ne "");
	if ($volt_global ==0) {
	   $output .= $voltexist." volt OK";
	   $global_state=1 if ($global_state==0);
	} else {
	  foreach (keys %volt_status) {
	    $output .= "volt " . $_ . ":" . $CiscoEnvMonState {$volt_status{$_}} ." ";
		if ($global_state < $CiscoEnvMonNagios{$volt_status{$_}} ) {
		  $global_state = $CiscoEnvMonNagios{$volt_status{$_}} ;
		}
	  }
	}
}

if ($tempexist !=0) {
	$output .= ", " if ($output ne "");
	if ($temp_global ==0) {
	   $output .= $tempexist." temp OK";
	   $global_state=1 if ($global_state==0);
	} else {
	  foreach (keys %temp_status) {
	    $output .= "temp " . $_ . ":" . $CiscoEnvMonState {$temp_status{$_}} ." ";
		if ($global_state < $CiscoEnvMonNagios{$temp_status{$_}} ) {
		  $global_state = $CiscoEnvMonNagios{$temp_status{$_}} ;
		}
	  }
	}
}

# Clear the SNMP Transport Domain and any errors associated with the object.
$session->close;

#print $output," : ",$Nagios_state[$global_state]," | ",$perf_output,"\n";
print $output," : ",$Nagios_state[$global_state],"\n";
$exit_val=$ERRORS{$Nagios_state[$global_state]};

exit $exit_val;

}


# ============================================================================
# ============================== NOKIA =======================================
# ============================================================================

if ($o_check_type eq "nokia") {

verb("Checking nokia env");

# Define variables
my $resultat;
my ($fan_status,$ps_status,$temp_status)=(0,0,0);
my ($fan_exist,$ps_exist,$temp_exist)=(0,0,0);
my ($num_fan,$num_ps)=(0,0);
my ($num_fan_nok,$num_ps_nok)=(0,0);
my $global_status=0;
my $output="";

# get temp
$resultat =  $session->get_table(Baseoid => $nokia_temp_tbl);

if (defined($resultat)) {
  verb ("temp found");
  $temp_exist=1;
  if ($$resultat{$nokia_temp} != 1) { 
    $temp_status=2;$global_status=1;
	$output="Temp CRITICAL ";
  } else {
    $output="Temp OK ";
  }
}
		
# Get fan table
$resultat =  $session->get_table(Baseoid => $nokia_fan_table);
		
if (defined($resultat)) {
  $fan_exist=1;
  foreach my $key ( keys %$resultat) {
    verb("OID : $key, Desc : $$resultat{$key}");
    if ( $key =~ /$nokia_fan_status/ ) { 
      if ($$resultat{$key} != 1) { $fan_status=1; $num_fan_nok++}      
	  $num_fan++;
    }
  }
  if ($fan_status==0) {
    $output.= ", ".$num_fan." fan OK";
  } else {
    $output.= ", ".$num_fan_nok."/".$num_fan." fan CRITICAL";
	$global_status=2;
  }
}

# Get ps table
$resultat =  $session->get_table(Baseoid => $nokia_ps_table);
		
if (defined($resultat)) {
  $ps_exist=1;
  foreach my $key ( keys %$resultat) {
    verb("OID : $key, Desc : $$resultat{$key}");
    if ( $key =~ /$nokia_ps_status/ ) { 
      if ($$resultat{$key} != 1) { $ps_status=1; $num_ps_nok++;}      
	  $num_ps++;
    }
    if ( $key =~ /$nokia_ps_temp/ ) { 
      if ($$resultat{$key} != 1) { if ($ps_status==0) {$ps_status=2;$num_ps_nok++;} }      
    }	
  }
  if ($ps_status==0) {
    $output.= ", ".$num_ps." ps OK";
  } elsif ($ps_status==2) {
    $output.= ", ".$num_ps_nok."/".$num_ps." ps WARNING (temp)";
	if ($global_status != 2) {$global_status=1;}
  } else {
    $output.= ", ".$num_ps_nok."/".$num_ps." ps CRITICAL";
	$global_status=2;
  }
}

# Clear the SNMP Transport Domain and any errors associated with the object.
$session->close;

verb ("status : $global_status");

if ( ($fan_exist+$ps_exist+$temp_exist) == 0) {
  print "No environemental informations found : UNKNOWN\n";
  exit $ERRORS{"UNKNOWN"};
}

if ($global_status==0) {
  print $output." : all OK\n";
  exit $ERRORS{"OK"};
}

if ($global_status==1) {
  print $output." : WARNING\n";
  exit $ERRORS{"WARNING"};
}

if ($global_status==2) {
  print $output." : CRITICAL\n";
  exit $ERRORS{"CRITICAL"};
}
}


# ============================================================================
# ============================== BLUECOAT ====================================
# ============================================================================

if ($o_check_type eq "bc") {

	verb("Checking bluecoat env");

	# Define variables
	my $final_status	= 0;
	my $output		= "";
	my $output_perf		= "";
	my $tmp_status_sensor;
	my $tmp_status_code;
	my ($num_fan,$num_other,$num_volt,$num_temp,$num_disk)=(0,0,0,0,0);
	my ($num_fan_ok,$num_other_ok,$num_volt_ok,$num_temp_ok,$num_disk_ok)=(0,0,0,0,0);
	my ($sens_name,$sens_status,$sens_scale,$sens_value,$sens_code,$sens_unit)=(undef,undef,undef,undef,undef,undef);

        # Get SNMP table(s) and check the result
        my $resultat_sensor	=  $session->get_table(Baseoid => $bc_sensor_table);
	&check_snmp_result($resultat_sensor,$session->error);
        my $resultat_disk 	=  $session->get_table(Baseoid => $bc_dsk_table);
	&check_snmp_result($resultat_disk,$session->error);
		
	# Check the sensor table
	if (defined($resultat_sensor)) {
		verb ("sensor table found");
		foreach my $key ( keys %$resultat_sensor) {
			if ($key =~ /$bc_sensor_Name/) { 
				$sens_name = $$resultat_sensor{$key};
				$key =~ s/$bc_sensor_Name//;	

				$sens_status	= $$resultat_sensor{$bc_sensor_Status.$key};
				$sens_scale 	= $$resultat_sensor{$bc_sensor_Scale.$key};
				$sens_value	= $$resultat_sensor{$bc_sensor_Value.$key} * 10 ** $sens_scale;
				$sens_code	= $$resultat_sensor{$bc_sensor_Code.$key};
				$sens_unit 	= $$resultat_sensor{$bc_sensor_Units.$key};
				$sens_scale 	= $$resultat_sensor{$bc_sensor_Scale.$key};

				if ($sens_status != 1 || $sens_code != 1) { # check is there is something wrong with either the status or code
					if ($output ne "") { $output.=", ";}
					if ($sens_status != 1 && $sens_code != 1) { # If both the status and code are not reporting "ok" use the following output
						$output .= $sens_name ." sensor ".$bc_SensorStatus[$sens_status].", reports ".$sens_value." ".$bc_mesure[$sens_unit]." (".$bc_SensorCode[$sens_code].")";
					}
					if ($sens_status != 1 && $sens_code == 1) { # If only the status is not reporting "ok"
						$output .= $sens_name ." sensor ".$bc_SensorStatus[$sens_status];
					}
					if ($sens_status == 1 && $sens_code != 1) { # If only the code is not reporting "ok"
						$output .= $sens_name ." reports ".$sens_value." ".$bc_mesure[$sens_unit]." (".$bc_SensorCode[$sens_code].")";
					}

					# Set the status
					$tmp_status_sensor = $bc_status_sensor[$sens_status];
					$tmp_status_code   = $bc_status_code[$sens_code];
					$final_status = &set_status($tmp_status_sensor,$final_status);
					$final_status = &set_status($tmp_status_code,$final_status);
				}

				# If performance data is enabled then output name with value
				if (defined($o_perf)) {
					if ($output_perf ne "") { $output_perf .=" ";}
					$output_perf .= "'".$sens_name."'=";
					my $perf_value = $sens_value;
					$output_perf .= $perf_value;
				}

				# Count fans sensors
				if ($bc_mesure[$sens_unit] eq "rpm") { 
					$num_fan++;
					if ($sens_status == 1 && $sens_code == 1) { $num_fan_ok++; }
				} 

				# Count temperature sensors
				if ($bc_mesure[$sens_unit] eq "celsius") { 
					$num_temp++;
					if ($sens_status == 1 && $sens_code == 1) { $num_temp_ok++; }
				} 

				# Count voltage sensors
				if ($bc_mesure[$sens_unit] eq "volts") { 
					$num_volt++;
					if ($sens_status == 1 && $sens_code == 1) { $num_volt_ok++; }
				} 
				if (!$bc_mesure[$sens_unit] =~ /rpm|celsius|volts/) { 
					$num_other++;
					if ($sens_status == 1 && $sens_code == 1) { $num_other_ok++;}
				}
			}
		} 
	}
			
	# Check the disk table
	if (defined($resultat_disk )) {
		foreach my $key ( keys %$resultat_disk ) {
			my ($dsk_name,$dsk_status)=(undef,undef);
		   	if ( $key =~ /$bc_dsk_status/ ) {
				$num_disk++;
				$dsk_status=$bc_dsk_status_nagios[$$resultat_disk{$key}];
				$key =~ s/$bc_dsk_status//;				

				if ( $dsk_status != 0) {
					if ($output ne "") { $output.=", ";}
					$output .= $$resultat_disk{$bc_dsk_vendor.$key} . "(S/N:".$$resultat_disk{$bc_dsk_serial.$key} ." MODEL:". $$resultat_disk{$bc_dsk_product.$key} . ") - ". $bc_DiskStatus[$$resultat_disk {$bc_dsk_status.$key}];
					$final_status = &set_status($dsk_status,$final_status);
				} else {      
					$num_disk_ok++;
				}
				if($$resultat_disk{$bc_dsk_status.$key} == 6){
					$num_disk--;
					$num_disk_ok--;
				}

			}
		}
	}

	# Clear the SNMP Transport Domain and any errors associated with the object.
	$session->close;

	if ($num_fan+$num_other+$num_volt+$num_temp+$num_disk == 0) {
	  	print "No information found : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}

	if ($output ne "") {$output.=" : ";}

	if ($num_fan!=0) {
		if ($num_fan == $num_fan_ok) {
		  $output.= $num_fan . " fan OK, ";
		} else {
		  $output.= $num_fan_ok . "/" . $num_fan ." fan OK, ";
		}
	}

	if ($num_temp!=0) {
		if ($num_temp == $num_temp_ok) {
		  $output.= $num_temp . " temp OK, ";
		} else {
		  $output.= $num_temp_ok . "/" . $num_temp ." temp OK, ";
		}
	}

	if ($num_volt!=0) {
		if ($num_volt == $num_volt_ok) {
		  $output.= $num_volt . " volt OK, ";
		} else {
		  $output.= $num_volt_ok . "/" . $num_volt ." volt OK, ";
		}
	}

	if ($num_other!=0) {
		if ($num_other == $num_other_ok) {
		  $output.= $num_other . " other OK, ";
		} else {
		  $output.= $num_other_ok . "/" . $num_other ." other OK, ";
		}
	}

	if ($num_disk!=0) {
		if ($num_disk == $num_disk_ok) {
		  $output.= $num_disk . " disk OK";
		} else {
		  $output.= $num_disk_ok . "/" . $num_disk ." disk OK";
		}
	}

	if ($final_status == 3) {
		print $output," : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}
	
	if ($final_status == 2) {
		print $output," : CRITICAL\n";
		exit $ERRORS{"CRITICAL"};
	}

	if ($final_status == 1) {
		print $output," : WARNING\n";
		exit $ERRORS{"WARNING"};
	}
	
	print $output," : OK\n";
	exit $ERRORS{"OK"};
}


# ============================================================================
# ============================== IRONPORT ====================================
# ============================================================================

if ($o_check_type eq "iron") {

verb("Checking Ironport env");

my $resultat;
# status : 0=ok, 1=warn, 2=crit
my ($fan_status,$ps_status,$temp_status)=(0,0,0);
my ($fan_exist,$ps_exist,$temp_exist)=(0,0,0);
my ($num_fan,$num_ps,$num_temp)=(0,0,0);
my ($num_fan_nok,$num_ps_nok,$num_temp_nok)=(0,0,0);
my $global_status=0;
my $output="";
# get temp if $o_temp is defined
if (defined($o_temp)) {
  verb("Checking temp < $o_temp");
  $resultat =  $session->get_table(Baseoid => $iron_tmp_table);

  if (defined($resultat)) {
    verb ("temp found");
    $temp_exist=1;
    foreach my $key ( keys %$resultat) {
      verb("OID : $key, Desc : $$resultat{$key}");
      if ( $key =~ /$iron_tmp_celcius/ ) {
	verb("Status : $$resultat{$key}");
        if ($$resultat{$key} > $o_temp) { 
  	  my @index_oid=split(/\./,$key);
	  my $index_oid_key=pop(@index_oid);
          $output .= ",Temp : ". $$resultat{ $iron_tmp_name.".".$index_oid_key}." : ".$$resultat{$key}." C";
	  $temp_status=2;
	  $num_temp_nok++;
	}
        $num_temp++;
      }
    }
    if ($temp_status==0) {
      $output.= ", ".$num_temp." temp < ".$o_temp." OK";
    } else {
      $output.= ", ".$num_temp_nok."/".$num_temp." temp probes CRITICAL";
      $global_status=2;
    }
  }
}

# Get fan status if $o_fan is defined
if (defined($o_fan)) {
  verb("Checking fan > $o_fan");
  $resultat =  $session->get_table(Baseoid => $iron_fan_table);

  if (defined($resultat)) {
    verb ("fan found");
    $fan_exist=1;
    foreach my $key ( keys %$resultat) {
      verb("OID : $key, Desc : $$resultat{$key}");
      if ( $key =~ /$iron_fan_rpm/ ) {
	verb("Status : $$resultat{$key}");
        if ($$resultat{$key} < $o_fan) {
  	  my @index_oid=split(/\./,$key);
	  my $index_oid_key=pop(@index_oid);
          $output .= ",Fan ". $$resultat{ $iron_fan_name.".".$index_oid_key}." : ".$$resultat{$key}." RPM";
          $fan_status=2;
          $num_fan_nok++;
	}
        $num_fan++;
      }
    }
    if ($fan_status==0) {
      $output.= ", ".$num_fan." fan > ".$o_fan." OK";
    } else {
      $output.= ", ".$num_fan_nok."/".$num_fan." fans CRITICAL";
      $global_status=2;
    }
  }
}

# Get power supply status
  verb("Checking PS");
  $resultat =  $session->get_table(Baseoid => $iron_ps_table);

  if (defined($resultat)) {
    verb ("ps found");
    $ps_exist=1;
    foreach my $key ( keys %$resultat) {
      verb("OID : $key, Desc : $$resultat{$key}");
      if ( $key =~ /$iron_ps_status/ ) {
	verb("Status : $iron_ps_status_name[$$resultat{$key}]");
        if ($iron_ps_status_nagios[$$resultat{$key}] != 0) {
  	  my @index_oid=split(/\./,$key);
	  my $index_oid_key=pop(@index_oid);
          $output .= ",PS ". $$resultat{$iron_ps_name.".".$index_oid_key}." : ".$iron_ps_status_name[$$resultat{$key}];
          $ps_status=2;
          $num_ps_nok++;
	}
        $num_ps++;
      }
    }
    if ($ps_status==0) {
      $output.= ", ".$num_ps." ps OK";
    } else {
      $output.= ", ".$num_ps_nok."/".$num_ps." ps CRITICAL";
      $global_status=2;
    }
  }

# Clear the SNMP Transport Domain and any errors associated with the object.
$session->close;

verb ("status : $global_status");

if ( ($fan_exist+$ps_exist+$temp_exist) == 0) {
  print "No environemental informations found : UNKNOWN\n";
  exit $ERRORS{"UNKNOWN"};
}

$output =~ s/^,//;

if ($global_status==0) {
  print $output." : all OK\n";
  exit $ERRORS{"OK"};
}

if ($global_status==1) {
  print $output." : WARNING\n";
  exit $ERRORS{"WARNING"};
}

if ($global_status==2) {
  print $output." : CRITICAL\n";
  exit $ERRORS{"CRITICAL"};
}
}


# ============================================================================
# ============================== FOUNDRY =====================================
# ============================================================================

if ($o_check_type eq "foundry") {

verb("Checking foundry env");

# Define variables
my $global_status	= 0; 
my $output		= "";
my @foundry_temp_oid=($foundry_temp,$foundry_temp_warn,$foundry_temp_crit);

# Get SNMP table(s) and check the result
my $result_temp = $session->get_request(Varbindlist => \@foundry_temp_oid);

my $temp_found=0;
if (defined($result_temp)) {
  $temp_found=1;
  #Temp found
  $output = "Temp : " . $$result_temp{$foundry_temp} / 2;
  if ($$result_temp{$foundry_temp} > $$result_temp{$foundry_temp_crit}) { # Temp above critical
    $output.= " > ". $$result_temp{$foundry_temp_crit} / 2 . " : CRITICAL";
    $global_status=3;
  } elsif ( $$result_temp{$foundry_temp} > $$result_temp{$foundry_temp_warn}) { # Temp above warning
      $output.= " > ". $$result_temp{$foundry_temp_warn} / 2 . " : WARNING";
      $global_status=2;
  } else {
      $output.= " < ". $$result_temp{$foundry_temp_warn} / 2 . " : OK";
      $global_status=1;
  }
}

# Get PS table (TODO : Bug in FAN table, see with Foundry).

my $result_ps =  $session->get_table(Baseoid => $foundry_ps_table);
&check_snmp_result($result_ps,$session->error);

my $ps_num=0;
if (defined($result_ps)) {
  $output .=", " if defined($output);
  foreach my $key ( keys %$result_ps) {
    verb("OID : $key, Desc : $$result_ps{$key}");
    if ($$result_ps{$key} =~ /$foundry_ps_desc/) {
     $ps_num++;
     my @oid_list = split (/\./,$key); 
     my $index_ps = pop (@oid_list); 
     $index_ps= $foundry_ps_status . "." . $index_ps;
     if (defined ($$result_ps{$index_ps})) {
        if ($$result_ps{$index_ps} == 3) {
	  $output.="PS ".$$result_ps{$key}." : FAILURE";
          $global_status=3;
        } elsif ($$result_ps{$index_ps} == 2) {
  	  $global_status=1 if ($global_status==0);
        } else {
          $output.= "ps ".$$result_ps{$key}." : OTHER";
        }
     } else {
       $output.= "ps ".$$result_ps{$key}." : UNDEFINED STATUS";    
     } 
   }
 }
}


# Clear the SNMP Transport Domain and any errors associated with the object.
$session->close;

if (($ps_num+$temp_found) == 0) {
  print  "No data found : UNKNOWN\n";
  exit $ERRORS{"UNKNOWN"};
}

if ($global_status==1) {
  print $output." : all OK\n";
  exit $ERRORS{"OK"};
}

if ($global_status==2) {
  print $output." : WARNING\n";
  exit $ERRORS{"WARNING"};
}

if ($global_status==3) {
  print $output." : CRITICAL\n";
  exit $ERRORS{"CRITICAL"};
}

print  $output." : UNKNOWN\n";
exit $ERRORS{"UNKNOWN"};

}


# ============================================================================
# ============================== LINUX LM-SENSORS ============================
# ============================================================================

if ($o_check_type eq "linux") {

	verb("Checking linux env");

	# Define variables
	my $output = "";
	my $index;
	my ($sens_name,$sens_status,$sens_value,$sens_unit)=(undef,undef,undef,undef);

        # Get SNMP table(s) and check the result
	my $resultat =  $session->get_table(Baseoid => $linux_env_table);
	&check_snmp_result($resultat,$session->error);
	
	foreach my $key ( keys %$resultat) {
		if ($key =~ /$linux_temp_descr/) {
			$sens_name=$$resultat{$key};
			$index=(split /\./,$key)[-1];
			$sens_value=$$resultat{$linux_temp_value.".".$index}/1000;
			printf("TSensor %s : %.0f\n",$sens_name,$sens_value);
		}
		if ($key =~ /$linux_fan_descr/) {
			$sens_name=$$resultat{$key};
			$index=(split /\./,$key)[-1];
			$sens_value=$$resultat{$linux_fan_value.".".$index};
			printf("FSensor %s : %.0f\n",$sens_name,$sens_value);
		}
		if ($key =~ /$linux_volt_descr/) {
			$sens_name=$$resultat{$key};
			$index=(split /\./,$key)[-1];
			$sens_value=$$resultat{$linux_volt_value.".".$index}/1000;
			printf("VSensor %s : %.2f\n",$sens_name,$sens_value);
		}				
		if ($key =~ /$linux_misc_descr/) {
			$sens_name=$$resultat{$key};
			$index=(split /\./,$key)[-1];
			$sens_value=$$resultat{$linux_misc_value.".".$index};
			printf("MSensor %s : %.2f\n",$sens_name,$sens_value);
		}				
	}
	# Clear the SNMP Transport Domain and any errors associated with the object.
	$session->close;	

	print "Not implemented yet : UNKNOWN\n";
	exit $ERRORS{"UNKNOWN"};
}


# ============================================================================
# ============================== CISCO CARD/MODULE ===========================
# ============================================================================

if ($o_check_type eq "ciscoSW") {

	verb("Checking ciscoSW env");

	# Define variables
	my $output		="";
	my $final_status	=0;
	my $card_output		="";
	my $modules_output	="";
	my $tmp_status;
	my $result_t;
	my $index;
	my @temp_oid;
	my ($num_cards,$num_cards_ok,$num_modules,$num_modules_ok)=(0,0,0,0);

        # Get SNMP table(s) and check the result
	my $resultat_c =  $session->get_table(Baseoid => $cisco_chassis_card_state);
	&check_snmp_result($resultat_c,$session->error);
	my $resultat_m =  $session->get_table(Baseoid => $cisco_module_state);
	&check_snmp_result($resultat_m,$session->error);

	# Check cards
	if (defined($resultat_c)) {	
		foreach my $key ( keys %$resultat_c) {
			if ($key =~ /$cisco_chassis_card_state/) {
				$num_cards++;
				$tmp_status=$cisco_chassis_card_status[$$resultat_c{$key}];
				if ($tmp_status == 0) {
					$num_cards_ok++;
				} else {
					$final_status=2;
					$index=(split /\./,$key)[-1];
					@temp_oid=($cisco_chassis_card_descr.".".$index,$cisco_chassis_card_slot.".".$index);
					$result_t = $session->get_request( Varbindlist => \@temp_oid);				
					if (!defined($result_t)) { $card_output.="Invalid card(UNKNOWN)";}
					else {
						if ($card_output ne "") {$card_output.=", ";}
						$card_output.= "Card slot " . $$result_t{$cisco_chassis_card_slot.".".$index};
						$card_output.= "(" .$$result_t{$cisco_chassis_card_descr.".".$index} ."): "; 
						$card_output.= "status " . $cisco_chassis_card_status_text[$$resultat_c{$key}];
					}
				}
			}
		}
		if ($card_output ne "") {$card_output.=", ";}
	}
	
	# Check modules
	if (defined($resultat_m)) {
		foreach my $key ( keys %$resultat_m) {
			if ($key =~ /$cisco_module_state/) {
				$num_modules++;
				$tmp_status=$cisco_module_status[$$resultat_m{$key}];
				if ($tmp_status == 0) {
					$num_modules_ok++;
				} else {
					my $module_slot_present=0;
					$index=(split /\./,$key)[-1];
					@temp_oid=($cisco_module_slot.".".$index);
                                        $result_t = $session->get_request( Varbindlist => \@temp_oid);
                                        if (defined($result_t)) { 
                                                if ($modules_output ne "") {$modules_output.=", ";}
                                                $modules_output.= "Module slot " . $$result_t{$cisco_module_slot.".".$index};
						$module_slot_present=1;
					}					
					@temp_oid=($cisco_module_descr.".".$index);
					$result_t = $session->get_request( Varbindlist => \@temp_oid);				
					if (defined($result_t)) {
						if ($module_slot_present == 1) {
							$modules_output.= "(" .$$result_t{$cisco_module_descr.".".$index} ."): "; 
						} else {
							if ($modules_output ne "") {$modules_output.=", ";}
							$modules_output.= "Module (" .$$result_t{$cisco_module_descr.".".$index} ."): ";
						}
						$modules_output.= "status " . $cisco_module_status_text[$$resultat_m{$key}];
					 	$module_slot_present=1;	
					}
					if ($module_slot_present == 0) {
						$modules_output.="Invalid module(UNKNOWN) : status " . $cisco_module_status_text[$$resultat_m{$key}];
					}
					if ($tmp_status == 1 && $final_status==0) {
						$final_status=1;
					} else {
						$final_status=2;
					}
				}
			}
		}
	}

	# Clear the SNMP Transport Domain and any errors associated with the object.
	$session->close;

	if ($num_cards==0 && $num_modules==0) {
		print "No cards/modules found : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}
	$output=$card_output . $modules_output;
	if ($output ne "") {$output.=" : ";}
	if ($num_cards!=0) {
		if ($num_cards == $num_cards_ok) {
		  $output.= $num_cards . " cards OK, ";
		} else {
		  $output.= $num_cards_ok . "/" . $num_cards ." cards OK, ";
		  $final_status=2;
		}
	}

	if ($num_modules!=0) {
		if ($num_modules == $num_modules_ok) {
		  $output.= $num_modules . " modules OK ";
		} else {
		  $output.= $num_modules_ok . "/" . $num_modules ." modules OK ";
		  $final_status=2;
		}
	}
	
	if ($final_status == 2) {
		print $output," : CRITICAL\n";
		exit $ERRORS{"CRITICAL"};
	}

	if ($final_status == 1) {
		print $output," : WARNING\n";
		exit $ERRORS{"WARNING"};
	}
	
	print $output," : OK\n";
	exit $ERRORS{"OK"};
}


# ============================================================================
# ============================== JUNIPER =====================================
# ============================================================================

if ($o_check_type eq "juniper") {

	verb("Checking juniper env");	

	# Define variables
	my $output		= "";	
	my $final_status	= 0;
	my $card_output		= "";
	my $ignore		= ": Ignored: ";
	my $tmp_status;
	my $result_t;
	my $index;
	my @temp_oid;
	my ($num_cards,$num_cards_ok)=(0,0);

        # Get SNMP table(s) and check the result
	my $resultat_c =  $session->get_table(Baseoid => $juniper_operating_state);
	&check_snmp_result($resultat_c,$session->error);

	if (defined($resultat_c)) {	
		foreach my $key ( keys %$resultat_c) {
			if ($key =~ /$juniper_operating_state/) {
				$num_cards++;
				$tmp_status=$juniper_operating_status[$$resultat_c{$key}];
				if ($tmp_status == 0) {
					$num_cards_ok++;
				} else {
					$index = $key;
					$index =~ s/^$juniper_operating_state.//;
					@temp_oid=($juniper_operating_descr.".".$index);
					$result_t = $session->get_request( Varbindlist => \@temp_oid);	
					if ($$result_t{$juniper_operating_descr.".".$index} =~ /PCMCIA|USB|Flash|Fan Tray [0-9]$/ && $tmp_status == 3) {
						$ignore.= "(" .$$result_t{$juniper_operating_descr.".".$index} ."),"; 
					}

					else {
						$final_status = &set_status($tmp_status,$final_status);			
						if (!defined($result_t)) { 
							$card_output.="Invalid component(UNKNOWN)";
						}
						else {
							if ($card_output ne "") {$card_output.=", ";}
							$card_output.= "(" .$$result_t{$juniper_operating_descr.".".$index} ."): "; 
							$card_output.= "status " . $juniper_operating_status_text[$$resultat_c{$key}];
						}
					}
				}
			}
		}
		if ($card_output ne "") {$card_output.=", ";}
	}

	# Clear the SNMP Transport Domain and any errors associated with the object.
	$session->close;

	if ($num_cards==0) {
		print "No components found : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}
	$output=$card_output;
	if ($output ne "") {$output.=" : ";}
	if ($num_cards!=0) {
		if ($num_cards == $num_cards_ok) {
		  $output.= $num_cards . " components OK";
		} else {
		  $output.= $num_cards_ok . "/" . $num_cards ." components OK" .$ignore;
		}
	}

	if ($final_status == 3) {
		print $output," : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}
	
	if ($final_status == 2) {
		print $output," : CRITICAL\n";
		exit $ERRORS{"CRITICAL"};
	}

	if ($final_status == 1) {
		print $output," : WARNING\n";
		exit $ERRORS{"WARNING"};
	}
	
	print $output," : OK\n";
	exit $ERRORS{"OK"};
}


# ============================================================================
# ============================== EXTREME =====================================
# ============================================================================

if ($o_check_type eq "extremeSW") {

	verb("Checking extreme env");

	# Define variables
	my $tmp_status;
	my $index;
	my $output			= "";		
	my $final_status		= 0;
	my $slot_output			= "";
	my $ps_output			= "";
	my $fan_output			= "";
	my $temperature_output		= "";
	my ($num_slot,$num_slot_ok)	= (0,0);
	my ($num_ps,$num_ps_ok)		= (0,0);
	my ($num_fan,$num_fan_ok)	= (0,0);
	my ($slot_name,$slot_state,$slot_serialnumber,$slot_state_text)		= (undef,undef,undef,undef);
	my ($ps_status,$ps_status_text)						= (undef,undef);
	my ($fan_number,$fan_operational,$fan_operational_text)			= (undef,undef,undef);
	my ($temperature_state,$temperature_state_text,$temperature_current)	= (undef,undef,undef);

        # Get SNMP table(s) and check the result
	my $resultat_slot =  $session->get_table(Baseoid => $extreme_slot_table);
	&check_snmp_result($resultat_slot,$session->error);
	my $resultat_ps =  $session->get_table(Baseoid => $extreme_ps_table);
	&check_snmp_result($resultat_ps,$session->error);
	my $resultat_fan =  $session->get_table(Baseoid => $extreme_fan_table);
	&check_snmp_result($resultat_fan,$session->error);
	my @extreme_temp_alarm_oid =($extreme_temperature_alarm);
	my $resultat_temp_alarm = $session->get_request( Varbindlist => \@extreme_temp_alarm_oid );	
	my @extreme_temp_current_oid =($extreme_temperature_current);
	my $resultat_temp_current = $session->get_request( Varbindlist => \@extreme_temp_current_oid );

	# Check slot
        if (defined($resultat_slot)) {
                foreach my $key ( keys %$resultat_slot) {
                        if ($key =~ /$extreme_slot_name/) {
				$key =~ s/$extreme_slot_name//;	

				# Set the slot variables
				$slot_name		= $$resultat_slot{$extreme_slot_name.$key};
				$slot_state		= $$resultat_slot{$extreme_slot_state.$key};
				$slot_state_text	= $extreme_slot_state_text[$slot_state];
				$slot_serialnumber	= $$resultat_slot{$extreme_slot_serialnumber.$key};
				$tmp_status		= $extreme_slot_nagios[$slot_state];
				$final_status 		= &set_status($tmp_status,$final_status);

				if ($slot_state != 1){
					$num_slot++;
					if ($tmp_status == 0) {
						$num_slot_ok++;
                                	}

                                	else {
						if ($slot_output ne "") {$slot_output.=", ";}
						$slot_output.= "(Slot: " . $slot_name; 
						$slot_output.= " Status: " . $slot_state_text;
						$slot_output.= " S/N: " . $slot_serialnumber . ")";
                                	}
				}
			}
		}
		if ($slot_output ne "") {$slot_output.=", ";}
	}

	# Check power-supply
        if (defined($resultat_ps)) {
                foreach my $key ( keys %$resultat_ps) {
                        if ($key =~ /$extreme_ps_status/) {
				$num_ps++;
				$key =~ s/$extreme_ps_status//;	

				# Set the slot variables
				$ps_status		= $$resultat_ps{$extreme_ps_status.$key};
				$ps_status_text		= $extreme_ps_status_text[$ps_status];
				$tmp_status		= $extreme_ps_nagios[$ps_status];
				$final_status 		= &set_status($tmp_status,$final_status);

				if ($tmp_status == 0) {
					$num_ps_ok++;
                                }

                                else {
					if ($ps_output ne "") {$ps_output.=", ";}
					$ps_output.= "(Power-supply status: " . $ps_status_text . ")";
                                }
			}
		}
		if ($ps_output ne "") {$ps_output.=", ";}
	}

	# Check fan
        if (defined($resultat_fan)) {
                foreach my $key ( keys %$resultat_fan) {
                        if ($key =~ /$extreme_fan_number/) {
				$num_fan++;
				$key =~ s/$extreme_fan_number//;	

				# Set the slot variables
				$fan_number		= $$resultat_fan{$extreme_fan_number.$key};
				$fan_operational	= $$resultat_fan{$extreme_fan_operational.$key};
				$fan_operational_text	= $extreme_fan_operational_text[$fan_operational];
				$tmp_status		= $extreme_fan_nagios[$fan_operational];
				$final_status 		= &set_status($tmp_status,$final_status);

				if ($tmp_status == 0) {
					$num_fan_ok++;
                                }

                                else {
					if ($fan_output ne "") {$fan_output.=", ";}
					$fan_output.= "(Fan: " . $fan_number; 
					$fan_output.= " Status: " . $fan_operational_text . ")";
                                }
			}
		}
		if ($fan_output ne "") {$fan_output.=", ";}
	}

	# Check temperature
	if (defined($resultat_temp_alarm) && defined($resultat_temp_current)){
		$temperature_state 		= $$resultat_temp_alarm{$extreme_temperature_alarm};
		$temperature_state_text		= $extreme_temperature_alarm_text[$temperature_state];
		$temperature_current		= $$resultat_temp_current{$extreme_temperature_current};

		$tmp_status			= $extreme_temperature_nagios[$temperature_state];
		$final_status 			= &set_status($tmp_status,$final_status);

		$temperature_output.= "Temp: " . $temperature_state_text; 
		$temperature_output.= " (" . $temperature_current . " celcius)";
	}

	# Clear the SNMP Transport Domain and any errors associated with the object.
	$session->close;

	if ($num_slot == 0 && $num_ps == 0 && $num_fan == 0) {
		print "No slot/power-supply/fan found : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}

	$output=$slot_output . $ps_output . $fan_output;

	if ($output ne "") {$output.=": ";}

	if ($num_slot != 0) {
		if ($num_slot == $num_slot_ok) {
		  $output.= $num_slot . " slots OK, ";
		} else {
		  $output.= $num_slot_ok . "/" . $num_slot ." slots OK, ";
		}
	}

	if ($num_ps != 0) {
		if ($num_ps == $num_ps_ok) {
		  $output.= $num_ps . " power-supply OK, ";
		} else {
		  $output.= $num_ps_ok . "/" . $num_ps ." power-supply OK, ";
		}
	}

	if ($num_fan != 0) {
		if ($num_fan == $num_fan_ok) {
		  $output.= $num_fan . " fans OK, ";
		} else {
		  $output.= $num_fan_ok . "/" . $num_fan ." fans OK, ";
		}
	}

	$output.= $temperature_output;

	if ($final_status == 3) {
		print $output," : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}

	if ($final_status == 2) {
		print $output," : CRITICAL\n";
		exit $ERRORS{"CRITICAL"};
	}

	if ($final_status == 1) {
		print $output," : WARNING\n";
		exit $ERRORS{"WARNING"};
	}
	
	print $output," : OK\n";
	exit $ERRORS{"OK"};
}


# ============================================================================
# ============================== HP PROCURVE =================================
# ============================================================================

if ($o_check_type eq "procurve") {

	verb("Checking procurve env");

	# Define variables
	my $output		= "";
	my $final_status	= 0;
	my $power_output	= "";
	my $fan_output		= "";
	my $temp_output		= "";
	my $tmp_status;
	my $index;
	my @temp_oid;
	my ($num_power,$num_power_ok,$num_fan,$num_fan_ok,$num_temp,$num_temp_ok)=(0,0,0,0,0,0);

        # Get SNMP table(s) and check the result
	my $resultat_state 	=  $session->get_table(Baseoid => $procurve_operating_state);
	&check_snmp_result($resultat_state,$session->error);
	my $resultat_descr 	=  $session->get_table(Baseoid => $procurve_operating_descr);
	&check_snmp_result($resultat_descr,$session->error);
			
	if (defined($resultat_state)) {	
		foreach my $key ( keys %$resultat_state) {
			if ($key =~ /$procurve_operating_state/) {

				$tmp_status=$procurve_operating_status[$$resultat_state{$key}];

				$index = $key;
				$index =~ s/^$procurve_operating_state.//;

				my $description = $$resultat_descr{$procurve_operating_descr.".".$index};

				if ($description =~ /Power/ ) {$num_power++;}
				if ($description =~ /Fan/ ) {$num_fan++;}
				if ($description =~ /temperature/ ) {$num_temp++;}

				if ($description =~ /Power/ && $tmp_status == 0) {$num_power_ok++;}
				if ($description =~ /Fan/ && $tmp_status == 0) {$num_fan_ok++;}
				if ($description =~ /temperature/ && $tmp_status == 0) {$num_temp_ok++;}

				if ($tmp_status != 0) {
					if ($description =~ /Power/ && $tmp_status == 4) {$num_power--;}
					if ($description =~ /Fan/ && $tmp_status == 4) {$num_fan--;}
					if ($description =~ /temperature/ && $tmp_status == 4) {$num_temp--;}

					if ($tmp_status != 4) {
						if ($tmp_status == 1 && $final_status != 2) {$final_status=$tmp_status;}
						if ($tmp_status == 2) {$final_status=$tmp_status;}
						if ($tmp_status == 3 && $final_status == 0) {$final_status=$tmp_status;}	

						if ($description =~ /Power/ ) {
							if (!defined($description)) {$power_output.="Invalid power(UNKNOWN)";}
							else {
								if ($power_output ne "") {$power_output.=", ";}
								$power_output.= "(".$description."): "; 
								$power_output.= "status " . $procurve_operating_status_text[$$resultat_state{$key}];
							}
						}

						if ($description =~ /Fan/ ) {
							if (!defined($description)) {$fan_output.="Invalid fan(UNKNOWN)";}
							else {
								if ($fan_output ne "") {$fan_output.=", ";}
								$fan_output.= "(".$description."): "; 
								$fan_output.= "status " . $procurve_operating_status_text[$$resultat_state{$key}];
							}
						}

						if ($description =~ /temperature/ ) {
							if (!defined($description)) {$power_output.="Invalid temp(UNKNOWN)";}
							else {
								if ($temp_output ne "") {$temp_output.=", ";}
								$temp_output.= "(".$description."): "; 
								$temp_output.= "status " . $procurve_operating_status_text[$$resultat_state{$key}];
							}
						}
					}
				}
			}
		}
		if ($power_output ne "") {$power_output.=", ";}
		if ($fan_output ne "") {$fan_output.=", ";}
		if ($temp_output ne "") {$temp_output.=", ";}
	}

	# Clear the SNMP Transport Domain and any errors associated with the object.
	$session->close;

	if ($num_power==0 && $num_fan==0 && $num_temp==0) {
		print "No power/fan/temp found : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}

	$output=$power_output . $fan_output . $temp_output;
	if ($output ne "") {$output.=" : ";}

	if ($num_power!=0) {
		if ($num_power == $num_power_ok) {
		  $output.= $num_power . " power OK, ";
		} else {
		  $output.= $num_power_ok . "/" . $num_power ." power OK, ";
		}
	}

	if ($num_fan!=0) {
		if ($num_fan == $num_fan_ok) {
		  $output.= $num_fan . " fan OK, ";
		} else {
		  $output.= $num_fan_ok . "/" . $num_fan ." fan OK, ";
		}
	}

	if ($num_temp!=0) {
		if ($num_temp == $num_temp_ok) {
		  $output.= $num_temp . " temp OK";
		} else {
		  $output.= $num_temp_ok . "/" . $num_temp ." temp OK";
		}
	}

	if ($final_status == 3) {
		print $output," : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}
	
	if ($final_status == 2) {
		print $output," : CRITICAL\n";
		exit $ERRORS{"CRITICAL"};
	}

	if ($final_status == 1) {
		print $output," : WARNING\n";
		exit $ERRORS{"WARNING"};
	}
	
	print $output," : OK\n";
	exit $ERRORS{"OK"};
}


# ============================================================================
# ============================== NETSCREEN ===================================
# ============================================================================

if ($o_check_type eq "netscreen") {

	verb("Checking netscreen env");

	# Define variables
	my $output		= "";
	my $final_status	= 0;
	my $slot_output		= "";
	my $power_output	= "";
	my $fan_output		= "";
	my $tmp_status;
	my $result_t;
	my $index;
	my @temp_oid;
	my ($num_slot,$num_slot_ok,$num_power,$num_power_ok,$num_fan,$num_fan_ok)=(0,0,0,0,0,0);

        # Get SNMP table(s) and check the result
	my $resultat_s =  $session->get_table(Baseoid => $netscreen_slot_operating_state);
	&check_snmp_result($resultat_s,$session->error);
	my $resultat_p =  $session->get_table(Baseoid => $netscreen_power_operating_state);
	&check_snmp_result($resultat_p,$session->error);
	my $resultat_f =  $session->get_table(Baseoid => $netscreen_fan_operating_state);
	&check_snmp_result($resultat_f,$session->error);	

	# Check if the ScreenOS version is not below 6.1 or 5GT, these are not supported
	my @netscreen_os_oid = ($sysdescr);
	my $netscreen_version = $session->get_request(Varbindlist => \@netscreen_os_oid);
	if( ($$netscreen_version{$sysdescr} !~ /version 6.[1-9]/) || ($$netscreen_version{$sysdescr} =~ /5GT/) ) 
	{
		print "Not checked, ScreenOS version below 6.1 and/or 5GT: OK\n";
		exit $ERRORS{"OK"};
	}

	# Check slots
	if (defined($resultat_s)) {	
		foreach my $key ( keys %$resultat_s) {
			if ($key =~ /$netscreen_slot_operating_state/) {
				$num_slot++;
				$tmp_status	= $netscreen_slot_operating_status[$$resultat_s{$key}];
				$final_status 	= &set_status($tmp_status,$final_status);

				if ($tmp_status == 0) {
					$num_slot_ok++;
				} else {
					$index = $key;
					$index =~ s/^$netscreen_slot_operating_state.//;
					@temp_oid=($netscreen_slot_operating_descr.".".$index);
					$result_t = $session->get_request( Varbindlist => \@temp_oid);	

					if (!defined($result_t)) {$slot_output.="Invalid slot(UNKNOWN)";}

					else {
						if ($slot_output ne "") {$slot_output.=", ";}
						$slot_output.= "(" .$$result_t{$netscreen_slot_operating_descr.".".$index} ."): "; 
						$slot_output.= "status " . $netscreen_slot_operating_status_text[$$resultat_s{$key}];
					}
				}
			}
		}
		if ($slot_output ne "") {$slot_output.=", ";}
	}

	# Check power
	if (defined($resultat_p)) {	
		foreach my $key ( keys %$resultat_p) {
			if ($key =~ /$netscreen_power_operating_state/) {
				$num_power++;
				$tmp_status	= $netscreen_power_operating_status[$$resultat_p{$key}];
				$final_status 	= &set_status($tmp_status,$final_status);

				if ($tmp_status == 0) {
					$num_power_ok++;
				} else {
					$index = $key;
					$index =~ s/^$netscreen_power_operating_state.//;
					@temp_oid=($netscreen_power_operating_descr.".".$index);
					$result_t = $session->get_request( Varbindlist => \@temp_oid);	

					if (!defined($result_t)) {$slot_output.="Invalid power(UNKNOWN)";}

					else {
						if ($power_output ne "") {$power_output.=", ";}
						$power_output.= "(" .$$result_t{$netscreen_power_operating_descr.".".$index} ."): "; 
						$power_output.= "status " . $netscreen_power_operating_status_text[$$resultat_p{$key}];
					}
				}
			}
		}
		if ($power_output ne "") {$power_output.=", ";}
	}

	# Check fans
	if (defined($resultat_f)) {
		foreach my $key ( keys %$resultat_f) {
			if ($key =~ /$netscreen_fan_operating_state/) {
				$num_fan++;
				$tmp_status	= $netscreen_fan_operating_status[$$resultat_f{$key}];
				$final_status 	= &set_status($tmp_status,$final_status);
				if ($tmp_status == 0) {
					$num_fan_ok++;
				} else {
					if($tmp_status == 4) {
						$num_fan--;
					} else {
						$index = $key;
						$index =~ s/^$netscreen_fan_operating_state.//;
						@temp_oid=($netscreen_fan_operating_descr.".".$index);
						$result_t = $session->get_request( Varbindlist => \@temp_oid);	

						if (!defined($result_t)) {$fan_output.="Invalid fan(UNKNOWN)";}

						else {
							if ($fan_output ne "") {$fan_output.=", ";}
							$fan_output.= "(" .$$result_t{$netscreen_fan_operating_descr.".".$index} ."): "; 
							$fan_output.= "status " . $netscreen_fan_operating_status_text[$$resultat_f{$key}];
						}	
					}
				}
			}
		}
		if ($fan_output ne "") {$fan_output.=", ";}
	}

	# Clear the SNMP Transport Domain and any errors associated with the object.
	$session->close;

	if ($num_slot==0 && $num_power==0 && $num_fan==0) {
		print "No slot/power/fan found : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}

	$output=$slot_output . $power_output . $fan_output;
	if ($output ne "") {$output.=" : ";}

	if ($num_slot!=0) {
		if ($num_slot == $num_slot_ok) {
		  $output.= $num_slot . " slots OK, ";
		} else {
		  $output.= $num_slot_ok . "/" . $num_slot ." slots OK, ";
		}
	}

	if ($num_power!=0) {
		if ($num_power == $num_power_ok) {
		  $output.= $num_power . " power OK, ";
		} else {
		  $output.= $num_power_ok . "/" . $num_power ." power OK ";
		}
	}

	if ($num_fan!=0) {
		if ($num_fan == $num_fan_ok) {
		  $output.= $num_fan . " fans OK";
		} else {
		  $output.= $num_fan_ok . "/" . $num_fan ." fans OK";
		}
	}

	if ($final_status == 3) {
		print $output," : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}

	if ($final_status == 2) {
		print $output," : CRITICAL\n";
		exit $ERRORS{"CRITICAL"};
	}

	if ($final_status == 1) {
		print $output," : WARNING\n";
		exit $ERRORS{"WARNING"};
	}
	
	print $output," : OK\n";
	exit $ERRORS{"OK"};
}


# ============================================================================
# ============================== CISCO (CISCO-ENTITY-SENSOR-MIB) =============
# ============================================================================

if ($o_check_type eq "ciscoNEW") {

	verb("Checking Cisco CISCO-ENTITY-SENSOR-MIB env");

	# Define variables
	my $output 		= "";
	my $final_status 	= 0;
	my $sensor_output	= "";						
	my $tmp_status;
	my $result_t;
	my $index;
	my @temp_oid;
	my ($num_sensors,$num_sensors_ok,$num_thresholds,$num_thresholds_ok) = (0,0,0,0);

        # Get SNMP table(s) and check the result
	my $resultat_status 		=  $session->get_table(Baseoid => $cisco_ios_xe_status);
	&check_snmp_result($resultat_status,$session->error);
	my $resultat_type 		=  $session->get_table(Baseoid => $cisco_ios_xe_type);
	&check_snmp_result($resultat_type,$session->error);
	my $resultat_precision 		=  $session->get_table(Baseoid => $cisco_ios_xe_precision);
	&check_snmp_result($resultat_precision,$session->error);
	my $resultat_value 		=  $session->get_table(Baseoid => $cisco_ios_xe_value);
	&check_snmp_result($resultat_value,$session->error);
	my $resultat_threshold_value 	=  $session->get_table(Baseoid => $cisco_ios_xe_threshold_value);
	&check_snmp_result($resultat_threshold_value,$session->error);
	my $resultat_threshold_severity	=  $session->get_table(Baseoid => $cisco_ios_xe_threshold_severity);
	&check_snmp_result($resultat_threshold_severity,$session->error);

	if (defined($resultat_status)) {	
		foreach my $key ( keys %$resultat_status) {
			if ($key =~ /$cisco_ios_xe_status/) {
				$num_sensors++;

				$tmp_status=$cisco_ios_xe_operating_status[$$resultat_status{$key}];

				$index = $key;
				$index =~ s/^$cisco_ios_xe_status.//;

				if ($tmp_status == 1) {
					$num_sensors_ok++;

					# Get sensor TYPE
					my $CiscoType = $$resultat_type{$cisco_ios_xe_type.".".$index};
									
					if ($CiscoType == 8) {

						# Get sensor PRECISION
						my $CiscoPrecision = $$resultat_precision{$cisco_ios_xe_precision.".".$index};	

						if ($CiscoPrecision == 0){

							# Get sensor THRESHOLD VALUE 1
							my $CiscoThreshold_value1 = $$resultat_threshold_value{$cisco_ios_xe_threshold_value.".".$index.".1"};	

							if (defined($CiscoThreshold_value1)){

								# Get sensor VALUE
								my $CiscoValue = $$resultat_value{$cisco_ios_xe_value.".".$index};	
							
								# Get sensor THRESHOLD SEVERITY 2
								my $CiscoThreshold_severity2 = $$resultat_threshold_severity{$cisco_ios_xe_threshold_severity.".".$index.".2"};	

								if ($CiscoThreshold_severity2 ne "noSuchInstance") {
									$num_thresholds++;

									if (($CiscoValue < $CiscoThreshold_value1) || ($CiscoThreshold_severity2 == 10)){
										$num_thresholds_ok++;
									} else {
										$final_status=2;
	
										# Get sensor DESCRIPTION
										@temp_oid=($cisco_ios_xe_physicaldescr.".".$index);
										$result_t = $session->get_request( Varbindlist => \@temp_oid);	
	
										if ($output ne "") {$output.=", ";}
											$output.= "(" .$$result_t{$cisco_ios_xe_physicaldescr.".".$index}.": ".$CiscoValue." Celsius)";
									}
								}
							}
						}
					}
	
				} else {
					$final_status=2;

					# Get sensor DESCRIPTION
					@temp_oid=($cisco_ios_xe_physicaldescr.".".$index);
					$result_t = $session->get_request( Varbindlist => \@temp_oid);	

					if ($tmp_status	== 2){
						if ($output ne "") {$output.=", ";}
						$output.= "(" .$$result_t{$cisco_ios_xe_physicaldescr.".".$index}.": sensor unavailable)";
					}
					if ($tmp_status	== 3){
						if ($output ne "") {$output.=", ";}
						$output.= "(" .$$result_t{$cisco_ios_xe_physicaldescr.".".$index}.": sensor nonoperational)";
					}	
				}
			}
		}
	}

	# Clear the SNMP Transport Domain and any errors associated with the object.
	$session->close;

	if ($num_sensors==0) {
		print "No components found : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}

	if ($output ne "") {$output.=" : ";}
	if ($num_sensors!=0) {
		if (($num_sensors == $num_sensors_ok) && ($num_thresholds == $num_thresholds_ok)){
		  $output.= $num_sensors . " sensors reported OK (".$num_thresholds." thresholds reported OK)";
		} else {
		  $output.= $num_sensors_ok . "/" . $num_sensors ." sensors reported OK (".$num_thresholds." sensors using thresholds)";
		}
	}

	if ($final_status == 3) {
		print $output," : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	} 
	
	if ($final_status == 2) {
		print $output," : CRITICAL\n";
		exit $ERRORS{"CRITICAL"};
	}

	if ($final_status == 1) {
		print $output," : WARNING\n";
		exit $ERRORS{"WARNING"};
	}

	print $output," : OK\n";
	exit $ERRORS{"OK"};
}


# ============================================================================
# ============================== CITRIX NETSCALER ============================
# ============================================================================

if ($o_check_type eq "citrix") {

	verb("Checking citrix");

	# Define variables
	my $output			= "";			
	my $final_status		= 0;
	my $voltage_output		= "";
	my $powersupply_output		= "";
	my $fan_output			= "";
	my $temp_output			= "";
	my $ha_state_output		= "";
	my $ssl_engine_output		= "";
 	my $ha_state_and_ssl_engine 	= "";
	my $result_t;
	my $index;
	my @temp_oid;
	my $using_voltage_threshold;
	my ($num_voltage,$num_voltage_ok,$num_powersupply,$num_powersupply_ok,$num_fan,$num_fan_ok,$num_temp,$num_temp_ok)=(0,0,0,0,0,0);

        # Get SNMP table(s) and check the result
	my $resultat_status 		=  $session->get_table(Baseoid => $citrix_desc);
	&check_snmp_result($resultat_status,$session->error);
	my $resultat_value 		=  $session->get_table(Baseoid => $citrix_value);
	&check_snmp_result($resultat_value,$session->error);

	if (defined($resultat_status)) {	
		foreach my $key ( keys %$resultat_status) {
			if ($key =~ /$citrix_desc/) {
				my $reported_counter_name = $$resultat_status{$key};
				$using_voltage_threshold = 0;

				$index = $key;
				$index =~ s/^$citrix_desc.//;

				my $reported_counter_value = $$resultat_value{$citrix_value.".".$index};

				# Thresholds are hardcoded and are based on the "Citrix NetScaler SNMP OID Reference - Release 9.2" document. 
				# If a threshold for a specific component is not available in this document then a logical threshold has been picked.

				if ($reported_counter_name =~ /Voltage/ ) {
					$num_voltage++; 	my $ha_state_and_ssl_engine ="";

					# Measures the +5V power supply in millivolt
					if ($reported_counter_name =~ /\+5.0VSupplyVoltage/ ){
						$using_voltage_threshold = 1;
						if (($reported_counter_value > 4500 ) && ($reported_counter_value < 5500))  { 
							$num_voltage_ok++;
						} else {
							if ($voltage_output ne "") {$voltage_output.=", ";}
							$voltage_output.= "(" .$reported_counter_name.": "; 
							$voltage_output.= $reported_counter_value." mV)";
							$final_status = 2;
						}
					}

					# Measures the +12V power supply in millivolt
					if ($reported_counter_name =~ /\+12.0VSupplyVoltage/ ){
						$using_voltage_threshold = 1;
						if (($reported_counter_value > 10800 ) && ($reported_counter_value < 13200))  { 
							$num_voltage_ok++;
						} else {
							if ($voltage_output ne "") {$voltage_output.=", ";}
							$voltage_output.= "(" .$reported_counter_name.": "; 
							$voltage_output.= $reported_counter_value." mV)";
							$final_status = 2;
						}	
					}

					# Measures the -5V power supply in millivolt
					if ($reported_counter_name =~ /\-5.0VSupplyVoltage/ ){
						$using_voltage_threshold = 1;
						if (($reported_counter_value > -5500 ) && ($reported_counter_value < -4500))  { 
							$num_voltage_ok++;
						} else {
							if ($voltage_output ne "") {$voltage_output.=", ";}
							$voltage_output.= "(" .$reported_counter_name.": "; 
							$voltage_output.= $reported_counter_value." mV)";
							$final_status = 2;
						}
					}

					# Measures the -12V power supply in millivolt
					if ($reported_counter_name =~ /\-12.0VSupplyVoltage/ ){
						$using_voltage_threshold = 1;
						if (($reported_counter_value > -13200 ) && ($reported_counter_value < -10800))  { 
							$num_voltage_ok++;
						} else {
							if ($voltage_output ne "") {$voltage_output.=", ";}
							$voltage_output.= "(" .$reported_counter_name.": "; 
							$voltage_output.= $reported_counter_value." mV)";
							$final_status = 2;
						}
					}

					# Measures the +3.3V main and standby power supply in millivolt
					if ($reported_counter_name =~ /3.3VSupplyVoltage/ ){
						$using_voltage_threshold = 1;
						if (($reported_counter_value > 2970 ) && ($reported_counter_value < 3630))  { 
							$num_voltage_ok++;
						} else {
							if ($voltage_output ne "") {$voltage_output.=", ";}
							$voltage_output.= "(" .$reported_counter_name.": "; 
							$voltage_output.= $reported_counter_value." mV)";
							$final_status = 2;
						}


					}

					# Measures the +5V standby power supply in millivolt
					if ($reported_counter_name =~ /PowerSupply5vStandbyVoltage/ ){
						$using_voltage_threshold = 1;
						if (($reported_counter_value > 4500 ) && ($reported_counter_value < 5500))  { 
							$num_voltage_ok++;
						} else {
							if ($voltage_output ne "") {$voltage_output.=", ";}
							$voltage_output.= "(" .$reported_counter_name.": "; 
							$voltage_output.= $reported_counter_value." mV)";
							$final_status = 2;
						}
					}

					# Measures the processor core voltage in millivolt
					if ($reported_counter_name =~ /CPU0CoreVoltage|CPU1CoreVoltage/ ){
						$using_voltage_threshold = 1;
						if (($reported_counter_value > 1080 ) && ($reported_counter_value < 1650))  { 
							$num_voltage_ok++;
						} else {
							if ($voltage_output ne "") {$voltage_output.=", ";}
							$voltage_output.= "(" .$reported_counter_name.": "; 
							$voltage_output.= $reported_counter_value." mV)";
							$final_status = 2;
						}
					}

                   			# If no defined voltage description is found, uses the following thresholds
					if ($using_voltage_threshold == 0){
						if (($reported_counter_value > 1000 ) && ($reported_counter_value < 6000)){
							$num_voltage_ok++;
						} else {
							if ($voltage_output ne "") {$voltage_output.=", ";}
							$voltage_output.= "(" .$reported_counter_name.": "; 
							$voltage_output.= $reported_counter_value." mV)";
							$final_status = 2;
						}
					}
				}

				# Power Supply check. No documentation available about possible values. "3" appears to be "OK", so anything other then that will be reported
				if ($reported_counter_name =~ /PowerSupply1FailureStatus|PowerSupply2FailureStatus/ ) {
					$num_powersupply++;
					if ($reported_counter_value == 3 ){
						$num_powersupply_ok++;
					} else {
						if ($powersupply_output ne "") {$powersupply_output.=", ";}
						$powersupply_output.= "(" .$reported_counter_name.": "; 
						$powersupply_output.= $reported_counter_value." Failure)";
						$final_status = 2;
					}
				}

				# Fan speed threshold in RPM. Documentation is not clear about the thresholds
				if ($reported_counter_name =~ /Fan/ ) {
					$num_fan++;
					if (($reported_counter_value > 5000 ) && ($reported_counter_value < 15000)){
						$num_fan_ok++;
					} else {
						if ($fan_output ne "") {$fan_output.=", ";}
						$fan_output.= "(" .$reported_counter_name.": "; 
						$fan_output.= $reported_counter_value." RPM)";
						$final_status = 2;
					}
				}

				# It looks like Citrix NetScaler devices are based on Intel XEON processors. Most of them appear to have a maximum operation temperature of 75 degrees Celsius.
				if ($reported_counter_name =~ /CPU0Temperature|CPU1Temperature/ ) {
					$num_temp++;
					if (($reported_counter_value > 50 ) && ($reported_counter_value < 72)){
						$num_temp_ok++;	
					} else {
						if ($temp_output ne "") {$temp_output.=", ";}
						$temp_output.= "(" .$reported_counter_name.": "; 
						$temp_output.= $reported_counter_value." Celsius)";
						$final_status = 2;
					}
				}

				# Internal temperature in degrees Celsius. No defined threshold in documentation.
				if ($reported_counter_name =~ /InternalTemperature/ ) {
					$num_temp++;
					if (($reported_counter_value > 20 ) && ($reported_counter_value < 40)){
						$num_temp_ok++;	
					} else {
						if ($temp_output ne "") {$temp_output.=", ";}
						$temp_output.= "(" .$reported_counter_name.": "; 
						$temp_output.= $reported_counter_value." Celsius)";
						$final_status = 2;
					}
				}
			}
		}

		# Get High Availability State 
		@temp_oid=($citrix_high_availability_state);
		$result_t = $session->get_request( Varbindlist => \@temp_oid);	
		my $ha_cur_state = $$result_t{$citrix_high_availability_state};
		if (defined($ha_cur_state)){
			$ha_state_output.= "HA State " . $citrix_high_availability_state_text[$ha_cur_state];
			if ($ha_cur_state != 3){
				$final_status = 2;
			}
		}

		# Get High Availability State 
		@temp_oid=($citrix_ssl_engine_state);
		$result_t = $session->get_request( Varbindlist => \@temp_oid);	
		my $ssl_engine_state = $$result_t{$citrix_ssl_engine_state};
		if (defined($ssl_engine_state)){
			$ssl_engine_output.= "SSL Engine " . $citrix_ssl_engine_state_text[$ssl_engine_state];
			if ($ssl_engine_state != 1){
				$final_status = 2;
			}
		}

		if ((defined($ha_cur_state)) && (defined($ssl_engine_state))){$ha_state_and_ssl_engine = " (".$ha_state_output.", ".$ssl_engine_output.")"};
		if ((defined($ha_cur_state)) && (!defined($ssl_engine_state))){$ha_state_and_ssl_engine = " - (".$ha_state_output.")"};
		if ((!defined($ha_cur_state)) && (defined($ssl_engine_state))){$ha_state_and_ssl_engine = " - (".$ssl_engine_output.")"};

		if ($voltage_output ne "") {$voltage_output.=", ";}
		if ($powersupply_output ne "") {$powersupply_output.=", ";}
		if ($fan_output ne "") {$fan_output.=", ";}
		if ($temp_output ne "") {$temp_output.=", ";}
	}

	# Clear the SNMP Transport Domain and any errors associated with the object.
	$session->close;

	if ($num_voltage==0 && $num_fan==0 && $num_temp==0) {
		print "No power/fan/temp found : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}

	$output=$voltage_output . $fan_output . $temp_output ;

	if ($output ne "") {$output.=" : ";}

	if ($num_powersupply!=0) {
		if ($num_powersupply == $num_powersupply_ok) {
		  $output.= $num_powersupply . " powersupply OK, ";
		} else {
		  $output.= $num_powersupply_ok . "/" . $num_powersupply ." powersupply OK, ";
		}
	}

	if ($num_voltage!=0) {
		if ($num_voltage == $num_voltage_ok) {
		  $output.= $num_voltage . " voltage OK, ";
		} else {
		  $output.= $num_voltage_ok . "/" . $num_voltage ." voltage OK, ";
		}
	}

	if ($num_fan!=0) {
		if ($num_fan == $num_fan_ok) {
		  $output.= $num_fan . " fan OK, ";
		} else {
		  $output.= $num_fan_ok . "/" . $num_fan ." fan OK, ";
		}
	}

	if ($num_temp!=0) {
		if ($num_temp == $num_temp_ok) {
		  $output.= $num_temp . " temp OK";
		} else {
		  $output.= $num_temp_ok . "/" . $num_temp ." temp OK";
		}
	}


	$output.= $ha_state_and_ssl_engine;


	if ($final_status == 3) {
		print $output," : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}
	
	if ($final_status == 2) {
		print $output," : CRITICAL\n";
		exit $ERRORS{"CRITICAL"};
	}

	if ($final_status == 1) {
		print $output," : WARNING\n";
		exit $ERRORS{"WARNING"};
	}
	
	print $output," : OK\n";
	exit $ERRORS{"OK"};

}


# ============================================================================
# ============================== TRANSMODE ===================================
# ============================================================================

if ($o_check_type eq "transmode") {

        verb("Checking transmode env");

	# Define variables
        my $final_status	= 0;
        my $tmp_status		= undef;
        my $num_alarms		= 0;
        my $num_ignored		= 0;
        my $alarm_output	= "";
        my $output		= "";
	my ($alarm_serv,$alarm_serv_txt,$alarm_descr,$alarm_time_start,$alarm_time_end,$alarm_rack,$alarm_slot,$alarm_unit)=(undef,undef,undef,undef,undef,undef,undef,undef);

        # Get SNMP table(s) and check the result
        my $resultat_c 		=  $session->get_table(Baseoid => $transmode_table);
	&check_snmp_result($resultat_c,$session->error);

        if (defined($resultat_c)) {
                foreach my $key ( keys %$resultat_c) {
                        if ($key =~ /$transmode_alarm_sev/) {
				$alarm_serv = $$resultat_c{$key};
				$key =~ s/$transmode_alarm_sev//;	

				# Set the alarm variables
				$alarm_descr		= $$resultat_c{$transmode_alarm_descr.$key};
				$alarm_time_start	= $$resultat_c{$transmode_alarm_time_start.$key};
				$alarm_time_end		= $$resultat_c{$transmode_alarm_time_end.$key};
				$alarm_rack		= $$resultat_c{$transmode_alarm_rack.$key};
				$alarm_slot		= $$resultat_c{$transmode_alarm_slot.$key};
				$alarm_unit		= $$resultat_c{$transmode_alarm_unit.$key};
				$alarm_serv_txt		= $transmode_alarm_status_text[$alarm_serv];
				$tmp_status		= $transmode_alarm_status[$alarm_serv];

                                # Ignore client related alarms or alarms that are deactivated
                                if (($alarm_descr =~ /client|Client/ ) || ($alarm_time_end =~ /[0-9]{4}[-][0-9]{2}[-][0-9]{2}/)) {
                                                $num_ignored++;
                                }

				# Print reported alarms that are not ignored
                                else {
						$final_status 		= &set_status($tmp_status,$final_status);
                                                $num_alarms++;
                                                $alarm_output .= "Rack:" . $alarm_rack;
                                                $alarm_output .= " Slot:" . $alarm_slot;
                                                $alarm_output .= " Unit:" . $alarm_unit;
                                                $alarm_output .= " Desc:" . $alarm_descr;
                                                $alarm_output .= " Time:" . $alarm_time_start;
                                                $alarm_output .= " Sev:" . $alarm_serv_txt .",";
                                }
                        }
                }
        }

	# Clear the SNMP Transport Domain and any errors associated with the object.
	$session->close;

	if ($num_alarms == 0) {
		print "No alarms found : OK\n";
		exit $ERRORS{"OK"};
	}

        $output=$alarm_output;

	if ($output ne "") {$output.=" : ";}

	if ($num_alarms != 0) {
		  $output .= $num_alarms . " Active alarm(s) found, ".$num_ignored." ignored";
	}

	if ($final_status == 3) {
		print $output," : UNKNOWN\n";
		exit $ERRORS{"UNKNOWN"};
	}
	
	if ($final_status == 2) {
		print $output," : CRITICAL\n";
		exit $ERRORS{"CRITICAL"};
	}

	if ($final_status == 1) {
		print $output," : WARNING\n";
		exit $ERRORS{"WARNING"};
	}
	
	print $output," : OK\n";
	exit $ERRORS{"OK"};
}


# ============================================================================
# ============================== NO CHECK DEFINED ============================
# ============================================================================

print "Unknown check type : UNKNOWN\n";
exit $ERRORS{"UNKNOWN"};

