<?php
/**
 * @section LICENSE
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * http://www.gnu.org/copyleft/gpl.html
 *
 * @file
 */

header( 'Content-Type: application/json' );
header( 'Cache-Control: no-store, no-cache, must-revalidate' );
header( 'Cache-Control: post-check=0, pre-check=0', false );
header( 'Pragma: no-cache' );

$cache = apc_cache_info();
$mem = apc_sma_info();

$uptime = time() - $cache['start_time'];
$segments = 0;
$blocks = 0;
$fragmentedSize = 0;
$blockSize = 0;

for ( $i = 0; $i < $mem['num_seg']; $i++ ) {
	$ptr = 0;
	foreach( $mem['block_lists'][$i] as $block ) {
		if ( $block['offset'] !== $ptr ) {
			$segments++;
		}
		$ptr = $block['offset'] + $block['size'];
		if ( $block['size'] < 5242880 /*5M*/ ) {
			$fragmentedSize += $block['size'];
		}
		$blockSize += $block['size'];
	}
	$blocks += count( $mem['block_lists'][$i] );
}

$stats = array(
	'cache_frag_count'    => $blocks,
	'cache_frag_pcnt'     => round( ( $fragmentedSize / $blockSize ) * 100, 2 ),
	'cache_full'          => $cache['expunges'],
	'cache_hit_rate'      => round( $cache['num_hits'] / $uptime, 2 ),
	'cache_hits'          => $cache['num_hits'],
	'cache_insert_rate'   => round( $cache['num_inserts'] / $uptime, 2 ),
	'cache_inserts'       => $cache['num_inserts'],
	'cache_miss_rate'     => round( $cache['num_misses'] / $uptime, 2 ),
	'cache_misses'        => $cache['num_misses'],
	'cache_request_rate'  => round( ( $cache['num_hits'] + $cache['num_misses'] ) / $uptime, 2 ),
	'cache_requests'      => $cache['num_hits'] + $cache['num_misses'],
	'cache_segments'      => $segments,
	'cached_files_count'  => $cache['num_entries'],
	'cached_files_size'   => $cache['mem_size'],
	'memory_available'    => $mem['avail_mem'],
	'memory_segment_size' => $mem['seg_size'],
	'memory_segments'     => $mem['num_seg'],
	'memory_total'        => $mem['num_seg'] * $mem['seg_size'],
	'memory_used'         => ( $mem['num_seg'] * $mem['seg_size'] ) - $mem['avail_mem'],
	'uptime'              => $uptime,
);

echo json_encode( $stats );