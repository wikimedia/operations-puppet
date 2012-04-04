<?php
$ggood=number_format($ggood, 0, ',', ' ');
$gtotal=number_format($gtotal, 0, ',', ' ');
$gedits=number_format($gedits, 0, ',', ' ');
$gadmins=number_format($gadmins, 0, ',', ' ');
$gusers=number_format($gusers, 0, ',', ' ');
$gimages=number_format($gimages, 0, ',', ' ');

echo "<br /><table><tr><th colspan=\"6\" class=\"grand\">Grand Total (of current display)</th></tr><tr><th class=\"grand\">Articles</th><th class=\"grand\">Total</th><th class=\"grand\">Edits</th><th class=\"grand\">Admins</th><th class=\"grand\">Users</th><th class=\"grand\">Images</th></tr>
<tr><td class=\"grand\"> ${ggood} </td><td class=\"grand\"> ${gtotal} </td><td class=\"grand\"> ${gedits} </td><td class=\"grand\"> ${gadmins} </td><td class=\"grand\"> ${gusers} </td><td class=\"grand\"> ${gimages} </td></tr></table>";
?>
