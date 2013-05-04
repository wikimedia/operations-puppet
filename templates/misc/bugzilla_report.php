#!/usr/bin/php
<?php error_reporting(E_ALL);

function getBugsPerProduct ($begin_date,$end_date) {
        print "Created reports per product\n\n";
        return <<<END
SELECT
        name, count(*)
FROM
        bugs
JOIN
        products
        on
        product_id = products.id
WHERE
        creation_ts
BETWEEN
        "$begin_date"
        and
        "$end_date"
GROUP BY
        product_id
LIMIT 5;
END;
}

function getBugsPerComponent ($begin_date,$end_date) {
        print "Created reports per component\n\n";
        return <<<END
SELECT
        name, count(*) as total
FROM
        bugs
JOIN
        components
        on
        component_id = components.id
WHERE
        creation_ts
BETWEEN
        "$begin_date"
        and
        "$end_date"
GROUP BY
        component_id
ORDER BY
        total
DESC
LIMIT
        5;

END;
}

function getBugsResolvedPerUser($begin_date,$end_date) {
        print "Top 5 bug report closers\n\n";
        return <<<END
SELECT
        login_name, count(*) as total
FROM
        bugs_activity
JOIN
        profiles
        on
        who = profiles.userid
WHERE
        added = 'RESOLVED'
        and
        bug_when
BETWEEN
        "$begin_date"
        and
        "$end_date"
GROUP BY
        who
ORDER BY
        total
DESC
LIMIT
        5;
END;
}
function getBugResolutions($begin_date, $end_date, $resolution) {
        $resolution = mysql_real_escape_string($resolution);
        $resolution = "'$resolution'";

        return <<<END
SELECT
        count (distinct bugs.bug_id)
FROM
        bugs, bugs_activity
WHERE
        bugs.resolution = "$resolution"
AND
        bugs_activity.added = "$resolution"
AND
        bugs_activity.bug_when
BETWEEN
        "$begin_date"
AND
        "$end_date"
AND
        bugs.bug_id = bugs_activity.bug_id;
END;
}

function getBugsChangingStatus($begin_date, $end_date, $state) {
        $state = mysql_real_escape_string($state);
        $state = "'$state'";

        return <<<END
SELECT
        count(*)
FROM
        bugs, bugs_activity
WHERE
        bugs.bug_status = "$state"
AND
        bugs_activity.added = "$state"
AND
        bugs_activity.bug_when
BETWEEN
        "$begin_date"
        and
        "$end_date"
AND
        bugs.bug_id = bugs_activity.bug_id;
END;
}

function getTotalOpenReports() {
         return <<<END
SELECT
        count(*)
FROM
        bugs
WHERE
        bug_status = 'UNCONFIRMED' or
        bug_status = 'ASSIGNED' or
        bug_status = 'NEW' or
        bug_status = 'REOPENED';
END;
}

function getTotalOpenEnhancements() {
         return <<<END
SELECT
        count(*)
FROM
        bugs
WHERE
        (bug_status = 'UNCONFIRMED' or
        bug_status = 'ASSIGNED' or
        bug_status = 'NEW' or
        bug_status = 'REOPENED')
AND
        bug_severity = 'enhancement';
END;
}

function getTotalOpenBugs() {
         return <<<END
SELECT
        count(*)
FROM
        bugs
WHERE
        (bug_status = 'UNCONFIRMED' or
        bug_status = 'ASSIGNED' or
        bug_status = 'NEW' or
        bug_status = 'REOPENED')
AND
        bug_severity != 'enhancement';
END;
}

function getTotalOpenBugsNonLowestPriority() {
         return <<<END
SELECT
        count(*)
FROM
        bugs
WHERE
        (bug_status = 'UNCONFIRMED' or
        bug_status = 'ASSIGNED' or
        bug_status = 'NEW' or
        bug_status = 'REOPENED')
AND
        bug_severity != 'enhancement'
AND
        priority != 'lowest';
END;
}

function getBugsCreated($begin_date, $end_date) {
         return <<<END
SELECT
        count(bug_id)
FROM
        bugs
WHERE
        creation_ts
BETWEEN
        "$begin_date"
        and
        "$end_date"
END;
}

function getHighestPrioTickets() {
         return <<<END
SELECT
        products.name AS product,
        components.name AS component,
        bugs.bug_id AS bugID,
        bugs.priority,
        bugs.delta_ts,
        profiles.login_name AS assignee,
        bugs.short_desc as bugsummary
FROM
        bugs
JOIN
        profiles ON assigned_to = profiles.userid
JOIN
        products ON bugs.product_id = products.id
JOIN
        components ON bugs.component_id = components.id
LEFT JOIN
        bug_group_map AS security_map ON bugs.bug_id = security_map.bug_id
WHERE
        ( security_map.group_id != 15 OR security_map.group_id IS NULL )
AND
        ( bug_status != "RESOLVED" AND bug_status != "VERIFIED" AND bug_status != "CLOSED" )
AND
        ( priority = "Highest" OR priority = "Immediate" )
ORDER BY
        product, component, delta_ts
LIMIT
        200;
END;
}

function formatOutput($result) {
        while ($row = mysql_fetch_row($result)) {
                if (is_array($row)) {
                     foreach ($row as $row_i) {
                          $row_i = str_replace ( '@', ' [AT] ', $row_i); //strip out any easy scrapes
                          print pack('A36',($row_i));
                     }
                }
                else {
                        print "0\n";
                }
        print "\n";
        }
}

function reportFailure($text) {
                print "Wikimedia Bugzilla report (FAILED), $text ";
                        die( "FAILED\n\n$text\n" );
}

function formatOutputHighestPrio($result) {
        printf( "%-13.13s | %-13.13s | %5s | %-9.9s | %-10.10s | %-20.20s | %-37.37s\n",
                "Product", "Component", "BugID", "Priority", "LastChange", "Assignee", "Summary" );
        printf ( "%-60s", "--------------------------------------------------------------" );
        print "\n";
        while ($row = mysql_fetch_row($result)) {
                foreach ($row as $row_i) {
                        $row = str_replace ( '@', '[AT]', $row);
                }
                printf( "%-13.13s | %-13.13s | %5s | %-9.9s | %-10.10s | %-20.20s | %-37.37s",
                        $row[0], $row[1], $row[2], $row[3], $row[4], $row[5], $row[6] );
                print "\n\n";
        }
}

# main

$options = getopt('b:e:');

if ( !isset($options['e']))
   $end_date = strtotime('now');
else
   $end_date = strtotime($options['e']);
if ( !isset($options['b']) )  {
   $begin_date =  $end_date - 86400*7 ;
}
else
   $begin_date = strtotime($options['b']);

print "MediaWiki Bugzilla Report for " . date('F d, Y', $begin_date) . " - " . date('F d, Y', $end_date) . "\n\n";

/* TODO: mysql_connect is deprecated - switch to MySQLi or PDO */
$ok = mysql_connect("db9.pmtpa.wmnet", "bugs", "<%= scope.lookupvar('passwords::bugzilla::bugzilla_db_pass') %>");
if (!$ok)
        reportFailure("DB connection failure");

$ok = mysql_select_db("bugzilla3");
if (!$ok)
        reportFailure("DB selection failure");

$reportsPerItem = array ('getBugsPerComponent',
                         'getBugsPerProduct',
                         'getBugsResolvedPerUser',);

$statesToRun = array('UNCONFIRMED',
                     'NEW',
                     'ASSIGNED',
                     'REOPENED',
                     'RESOLVED',
                     'VERIFIED',);

$resolutionsToRun = array('FIXED',      'DUPLICATE',
                          'INVALID',    'WORKSFORME',
                          'WONTFIX',);

$totalStatistics = array ('getTotalOpenReports',);

$totalStatisticsEnhancements = array ('getTotalOpenEnhancements',);

$totalStatisticsBugs = array ('getTotalOpenBugs',);

$totalStatisticsBugsNonLowestPriority = array ('getTotalOpenBugsNonLowestPriority',);

$createdStatistics = array('getBugsCreated',);

$urgentStatistics = array('getHighestPrioTickets',);

print "Status changes this week\n\n";
foreach ($statesToRun as $state) {
        $sql = getBugsChangingStatus(date('Y-m-d',$begin_date),date('Y-m-d',$end_date), $state);
        $result = mysql_query($sql);
        if (!$result)
                reportFailure("Query failure");
        print pack('A34A3',"Reports changed/set to $state",":");
        formatOutput($result);
}

foreach ($totalStatistics as $report) {
        $sql = getTotalOpenReports();
        $result = mysql_query($sql);
        if (!$result)
                 reportFailure("Query failure");
        print "\nTotal reports still open              : ";
        formatOutput($result);
}

foreach ($totalStatisticsBugs as $report) {
        $sql = getTotalOpenBugs();
        $result = mysql_query($sql);
        if (!$result)
                 reportFailure("Query failure");
        print "Total bugs still open                 : ";
        formatOutput($result);
}

foreach ($totalStatisticsBugsNonLowestPriority as $report) {
        $sql = getTotalOpenBugsNonLowestPriority();
        $result = mysql_query($sql);
        if (!$result)
                 reportFailure("Query failure");
        print "Total non-lowest prio. bugs still open: ";
        formatOutput($result);
}

foreach ($totalStatisticsEnhancements as $report) {
        $sql = getTotalOpenEnhancements();
        $result = mysql_query($sql);
        if (!$result)
                 reportFailure("Query failure");
        print "Total enhancements still open         : ";
        formatOutput($result);
}

foreach ($createdStatistics as $report) {
        $sql = getBugsCreated(date('Y-m-d', $begin_date),date('Y-m-d', $end_date));
        $result = mysql_query($sql);
        if (!$result)
                 reportFailure( 'Query failure' );
        print "\nReports created this week: ";
        formatOutput( $result );
}

print "\nResolutions for the week:\n\n";
foreach ($resolutionsToRun as $resolution) {
        $sql = getBugResolutions(date('Y-m-d',$begin_date),date('Y-m-d',$end_date), $resolution);
        $result = mysql_query($sql);
        if (!$result)
                 reportFailure("Query failure");
        print pack('A25A3',"Reports marked $resolution",":");
        formatOutput($result);
}
print "\nSpecific Product/Component Resolutions & User Metrics \n\n";
foreach ($reportsPerItem as $report) {
        $sql = $report(date('Y-m-d',$begin_date),date('Y-m-d',$end_date));
        $result = mysql_query($sql);
        if (!$result)
                 reportFailure("Query failure");
        formatOutput($result);
        print "\n";
}
print "\nMost urgent open issues\n\n";
foreach ($urgentStatistics as $report) {
        $sql = getHighestPrioTickets();
        $result = mysql_query($sql);
        if (!$result)
                reportFailure("Query failure");
        formatOutputHighestPrio($result);
}
