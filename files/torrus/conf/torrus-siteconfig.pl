# Torrus Site config. Put all your site specifics here.
# You need to stop and start Apache server every time you change this file.

@Torrus::Global::xmlAlwaysIncludeFirst = ( 'defaults.xml', 'site-global.xml' );

%Torrus::Global::treeConfig =
    (
#     'main' => {
#         'description' => 'The main tree',
#         'info'        => 'some tree',
#         'xmlfiles' => [qw(routers.xml)],
#         'run' => { 'collector' => 1, 'monitor' => 0 } }

	'Network' => {
		'description'	=> 'Network devices',
		'info'		=> 'Wikimedia core and access switches',
		'xmlfiles'	=> [qw(corerouters.xml accessswitches.xml aggregates.xml)],
		'run'		=> { 'collector' => 1, 'monitor' => 1 }
	},
	'Storage' => {
		'description'	=> 'Storage',
		'info'		=> 'Wikimedia storage appliances',
		'xmlfiles'	=> [qw(storage.xml)],
		'run'		=> { 'collector' => 1, 'monitor' => 0 }
	},
	'Facilities' => {
		'description'	=> 'Data center facilities',
		'info'		=> 'Power, environment monitoring',
		'xmlfiles'	=> [qw(power.xml facilities_aggregates.xml)],
		'run'		=> { 'collector' => 1, 'monitor' => 1 }
	},
	'CDN' => {
		'description'	=> 'Content Delivery Network',
		'info'		=> 'Wikimedia Content Delivery Network',
		'xmlfiles'	=> [qw(squid.xml varnish.xml cdn-aggregates.xml)],
		'run'		=> { 'collector' => 1, 'monitor' => 0 }
	},
#	'Test' => {
#		'description'	=> 'Testing new monitoring',
#		'info'		=> 'Testing',
#		'xmlfiles'	=> [qw(varnish.xml)],
#		'run'		=> { 'collector' => 1, 'monitor' => 0 }
#	}
     );


$Torrus::Renderer::companyName = 'Wikimedia Foundation';
$Torrus::Renderer::companyURL = 'http://wikimediafoundation.org';
# The URL of your company logo which will be displayed instead of
# companyName
#$Torrus::Renderer::companyLogo = 'http://upload.wikimedia.org/wikipedia/foundation/9/9a/Wikimediafoundation-logo.png';
# $Torrus::Renderer::siteInfo = `hostname`;

$Torrus::ApacheHandler::authorizeUsers = 0;

$Torrus::Renderer::styling{'default'}{'cssoverlay'} = 'wikimedia.css';
$Torrus::Renderer::stylingProfileOverlay = $Torrus::Global::cfgSiteDir . '/schema-override.pl';

# The time period after which we give up to reach the host being unreachable
$Torrus::Collector::SNMP::unreachableTimeout = 7776000; # 90 days

# For unreachable host, we retry SNMP query not earlier than this
$Torrus::Collector::SNMP::unreachableRetryDelay = 600; # 10 min


1;
