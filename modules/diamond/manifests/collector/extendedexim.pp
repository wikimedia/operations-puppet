# == Define: diamond::collector::extendedexim
#
# Exim collector. Collects queue properties and paniclog size.
#
# Queue properties:
#     - queue.oldest: age of oldest e-mail in queue (seconds)
#     - queue.youngest: age of youngest e-mail in queue (seconds)
#     - queue.size: total size of the queue (bytes)
#     - queue.length: total number of e-mails in the queue
#     - queue.num_frozen: number of frozen e-mails in the queue
#
# Paniclog properties:
#     - paniclog.length: number of lines in /var/log/exim4/paniclog

define diamond::collector::extendedexim {

    diamond::collector { 'ExtendedExim':
        source  => 'puppet:///modules/diamond/collector/extendedexim.py',
    }

}
