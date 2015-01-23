This module is mostly a copy/paste of classes from the old
manifests/misc/statistics.pp file.  It has not been refactored.
The misc contents have been moved here in order to satisfy
the requirement of moving all non site.pp manifests
out of the root manifests and into a modules.

You will probably want to include either statistics::web or
statistics::compute, and then include any specific other
specific classes to your nodes selectively.

