<?php
// wikimedia defaults for phabricator settings. These are overridden by
// local.json
return array(
  'repository.default-local-path'     => '/srv/phab/repos',
  'storage.upload-size-limit'         => '10M',

  'maniphest.statuses' =>  array (
    'open' => array(
      'name'      => 'Open',
      'special'   => 'default',
    ),
    'resolved' => array(
      'closed'    => true,
      'name'      => 'Resolved',
      'name.full' => 'Closed, Resolved',
      'prefixes'  => array ('closed','closes','close',
                            'fix','fixes','fixed',
                            'resolve','resolves','resolved'),
      'suffixes'  => array ('as resolved', 'as fixed'),
      'special'   => 'closed',
    ),
    'stalled' => array(
      'closed'            => false,
      'name'              => 'Stalled',
      'name.full'         => 'Open, Stalled',
      'prefixes'          => array ('stalled'),
      'suffixes'          => array ('as stalled'),
      'transaction.icon'  => 'fa-pause',
    ),
    'declined' => array(
      'closed'            => true,
      'name'              => 'Declined',
      'name.action'       => 'Declined',
      'name.full'         => 'Closed, Declined',
      'prefixes'          => array ('decline','declines','declined'),
      'suffixes'          => array ('as declined'),
      'transaction.icon'  => 'fa-thumbs-o-down',
    ),
    'invalid' => array(
      'closed'            => true,
      'name'              => 'Invalid',
      'name.full'         => 'Closed, Invalid',
      'prefixes'          => array('invalidate','invalidates','invalidated'),
      'suffixes'          => array('as invalid'),
      'transaction.icon'  => 'fa-thumbs-o-down',
    ),
    'duplicate' => array(
      'closed'            => true,
      'name'              => 'Duplicate',
      'name.full'         => 'Closed, Duplicate',
      'special'           => 'duplicate',
      'transaction.icon'  => 'fa-times',
    ),
  ),

);
