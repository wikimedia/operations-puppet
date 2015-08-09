# = Class: role::aptly
#
# Sets up a simple aptly repo server serving over http on port 80
class role::aptly {
    include ::aptly
}
