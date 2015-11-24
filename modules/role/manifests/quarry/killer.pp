# Should be included on an instance that already has
# a Quarry install (celery or web) setup
class role::quarry::killer {
    include quarry::querykiller
}
