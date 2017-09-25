# Output API Feature Usage to elasticsearch
#
# This is used to do a pseudo iterator. It might be replaced by a nicer syntax
# once we are fully Puppet 4 compatible.
#
define role::logstash::apifeatureusage::elasticsearch {
    logstash::output::elasticsearch { "apifeatureusage-${title}":
        host            => $title,
        guard_condition => '[type] == "api-feature-usage-sanitized"',
        manage_indices  => true,
        priority        => 95,
        template        => '/etc/logstash/apifeatureusage-template.json',
        require         => File['/etc/logstash/apifeatureusage-template.json'],
    }
}