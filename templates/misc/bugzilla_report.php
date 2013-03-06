#!/usr/bin/php
<?php error_reporting(E_ALL);

function getBugsPerProduct ($begin_date,$end_date) {
        print "New bugs per product\n\n";
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
        bug_status = 'NEW'
        and creation_ts
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
        print "New bugs per component\n\n";
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
        bug_status = 'NEW'
        and
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
        count(*)
FROM
        bugs
WHERE
        resolution = $resolution
        and delta_ts
BETWEEN
        "$begin_date"
        and
        "$end_date"
END;
}

function getBugsChangingStatus($begin_date, $end_date, $state) {
        $state = mysql_real_escape_string($state);
        $state = "'$state'";

        return <<<END
SELECT
        count(*)
FROM
        bugs
WHERE
        bug_status = $state
        and delta_ts
BETWEEN
        "$begin_date"
        and
        "$end_date"
END;
}

function getTotalOpenBugs() {
         return <<<END
SELECT
        count(*)
FROM
        bugs
WHERE
        bug_status = 'ASSIGNED' or
        bug_status = 'NEW' or
        bug_status = 'REOPENED';
END;
}

function getHighestPrioTickets() {
        return <<<END

SELECT
        products.name AS product,
        components.name AS component,
        bugs.bug_id,
        bugs.short_desc as bugsummary,
        profiles.login_name AS assignee,
        bugs.delta_ts,
        bugs.priority
FROM
        bugs 
JOIN
        profiles ON assigned_to = profiles.userid 
JOIN
        products ON bugs.product_id = products.id
        JOIN components ON bugs.component_id = components.id 
WHERE
        resolution = "" 
AND
        priority = "Highest" OR priority = "Immediate"
ORDER BY
        product, component, delta_ts
LIMIT 200;
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

$ok = mysql_connect("db9.pmtpa.wmnet", "bugs", "<%= scope.lookupvar('passwords::bugzilla::bugzilla_db_pass') %>");
if (!$ok)
        reportFailure("DB connection failure");

$ok = mysql_select_db("bugzilla3");
if (!$ok)
        reportFailure("DB selection failure");

$reportsPerItem = array ('getBugsPerComponent',
                         'getBugsPerProduct',
                         'getBugsResolvedPerUser',);

$statesToRun = array('NEW',
                     'ASSIGNED',
                     'REOPENED',
                     'RESOLVED',);

$resolutionsToRun = array('FIXED',      'REMIND',
                          'INVALID',    'DUPLICATE',
                          'WONTFIX',    'WORKSFORME',
                          'LATER',      'MOVED',);

$totalStatistics = array ('getTotalOpenBugs',);


print "Status changes this week\n\n";
foreach ($statesToRun as $state) {
        $sql = getBugsChangingStatus(date('Y-m-d',$begin_date),date('Y-m-d',$end_date), $state);
        $result = mysql_query($sql);
        if (!$result)
                reportFailure("Query failure");
        print pack('A23A3',"Bugs $state",":");
        formatOutput($result);
}

foreach ($totalStatistics as $report) {
        $sql = getTotalOpenBugs();
        $result = mysql_query($sql);
        if (!$result)
                 reportFailure("Query failure");
        print "\nTotal bugs still open: ";
        formatOutput($result);
}

print "\nResolutions for the week:\n\n";
foreach ($resolutionsToRun as $resolution) {
        $sql = getBugResolutions(date('Y-m-d',$begin_date),date('Y-m-d',$end_date), $resolution);
        $result = mysql_query($sql);
        if (!$result)
                 reportFailure("Query failure");
        print pack('A23A3',"Bugs marked $resolution",":");
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
