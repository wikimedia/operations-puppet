# Should be included on an instance that already has
# a Quarry install (celery or web) setup
#
# filtertags: labs-project-quarry
class role::labs::quarry::killer {
    include quarry::querykiller
}
