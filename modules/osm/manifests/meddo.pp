# = Class: osm::meddo
#
# Meddo is a tool to manage OSM datasources.
# See https://github.com/kartotherian/meddo for details.
#
# At this point, meddo is very much related to all our OSM data import.
# Depending on how it evolves, it might make sense to move this to its own
# module at some point.
#
# == Parameters:
class osm::meddo {
    # make sure all dependencies for meddo are present
    ensure_packages([
        'python3-requests',
        'python3-psycopg2',
        'python3-yaml',
        'gdal-bin',
        'meddo'
    ])
}
