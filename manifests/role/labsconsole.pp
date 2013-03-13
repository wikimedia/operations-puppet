#  Install LabsConsole and OpenStack on a single node.
#
#  Uses the labsconsole_singlenode class with minimal alteration

class role::labsconsole::labs {
  class { 'labsconsole_singlenode':
  }
}
