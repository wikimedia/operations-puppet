# EventLogging role classes

At the very least, each of these classes sets up a distinct scap deployment
target for deploying the EventLogging python codebase.  The
eventlogging::deployment::target define in the eventlogging module
sets up EventLoggging dependencies via the eventlogging::dependencies
class, and also a scap::target for deploying the eventlogging code.

- analytics: The original Analytics deployment of EventLogging.  This
  role sets up and manages EventLogging daemon processes for processing
  Analytics events.

TODO: Move eventbus/eventbus.pp role here to role::eventlogging::eventbus.

