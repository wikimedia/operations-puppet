<?php
// Monitoring helper for PHP-FPM 7.x
define('MW_PATH', '/srv/mediawiki');


function opcache_stats(bool $full = false): array {
	// first of all, check if opcache is enabled
	$stats = opcache_get_status($full);
	if ($stats === false) {
		return [];
	}
	return $stats;
}


function apcu_stats(bool $limited = true, bool $sma_limited = false): array {
	if (!function_exists('apcu_cache_info')) {
		return [];
	}
	$cache_info = apcu_cache_info($limited);
	if ($cache_info === false) {
		$cache_info = [];
	}
	$sma_info = apcu_sma_info($sma_limited);
	if ($sma_info === false) {
		$sma_info = [];
	}
	return array_merge($cache_info, $sma_info);
}

/*

  Very simple class to manage prometheus metrics printing.
  Not intended to be complete or useful outside of this context.

*/
class PrometheusMetric {
	public $description;
	public $key;
	private $value;
	private $labels;
	private $type;

	function __construct(string $key, string $type, string $description) {
		$this->key = $key;
		$this->description = $description;
		// Set labels empty
		$this->labels = [];
		$this->type = $type;
	}

	public function setValue($value) {
		if (is_bool($value) === true) {
			$this->value = (int) $value;
		} elseif (is_array($value)) {
			$this->value = implode($value, " ");
		} else {
			$this->value = $value;
		}
	}

	public function setLabel(string $name, string $value) {
		$this->labels[] = "$name=\"${value}\"";
	}

	private function _helpLine(): string {
		// If the description is empty, don't return
		// any help header.
		if ($this->description == "") {
			return "";
		}
		return sprintf("# HELP %s %s\n# TYPE %s %s\n",
					$this->key, $this->description,
					$this->key, $this->type
		);
	}

	public function __toString() {
		if ($this->labels != []) {
			$full_name = sprintf('%s{%s}',$this->key, implode(",", $this->labels));
		} else {
			$full_name = $this->key;
		}
		return sprintf(
			"%s%s %s\n",
			$this->_helpLine(),
			$full_name,
			$this->value
		);
	}
}


function prometheus_metrics(): array {
	$oc = opcache_stats();
	$ac = apcu_stats();
	$defs = [
		[
			'name'  => 'php_opcache_enabled',
			'type'  => 'gauge',
			'desc'  => 'Opcache is enabled',
			'value' => $oc['opcache_enabled']
		],
		[
			'name'  => 'php_opcache_full',
			'type'  => 'gauge',
			'desc'  => 'Opcache is full',
			'value' => $oc['cache_full']
		],
		[
			'name'  => 'php_opcache_memory',
			'type'  => 'gauge',
			'label' => ['type', 'used'],
			'desc'  => 'Used memory stats',
			'value' => $oc['memory_usage']['used_memory']
		],
		[
			'name'  => 'php_opcache_memory',
			'type'  => 'gauge',
			'label' => ['type', 'free'],
			'desc'  => '',
			'value' => $oc['memory_usage']['free_memory']
		],
		[
			'name'  => 'php_opcache_strings_memory',
			'type'  => 'gauge',
			'label' => ['type', 'used'],
			'desc'  => 'Memory usage from interned strings',
			'value' => $oc['interned_strings_usage']['used_memory']
		],
		[
			'name'  => 'php_opcache_strings_memory',
			'type'  => 'gauge',
			'label' => ['type', 'free'],
			'desc'  => '',
			'value' => $oc['interned_strings_usage']['free_memory']
		],
		[
			'name'  => 'php_opcache_strings_numbers',
			'type'  => 'gauge',
			'desc'  => 'Memory usage from interned strings',
			'value' => $oc['interned_strings_usage']['number_of_strings'],
		],
		[
			'name'  => 'php_opcache_stats_cached',
			'type'  => 'gauge',
			'label' => ['type', 'scripts'],
			'desc'  => 'Stats about cached objects',
			'value' => $oc['opcache_statistics']['num_cached_scripts']
		],
		[
			'name'  => 'php_opcache_stats_cached',
			'type'  => 'gauge',
			'label' => ['type', 'keys'],
			'desc'  => '',
			'value' => $oc['opcache_statistics']['num_cached_keys']
		],
		[
			'name'  => 'php_opcache_stats_cached',
			'type'  => 'counter',
			'label' => ['type', 'max_keys'],
			'desc'  => '',
			'value' => $oc['opcache_statistics']['max_cached_keys']
		],
		[
			'name'  => 'php_opcache_stats_cache_hit',
			'type'  => 'counter',
			'label' => ['type', 'hits'],
			'desc'  => 'Stats about cached object hit/miss ratio',
			'value' => $oc['opcache_statistics']['hits']
		],
		[
			'name'  => 'php_opcache_stats_cache_hit',
			'type'  => 'counter',
			'label' => ['type', 'misses'],
			'desc'  => '',
			'value' => $oc['opcache_statistics']['misses']
		],
		[
			'name'  => 'php_apcu_num_slots',
			'type'  => 'counter',
			'desc'  => 'Number of distinct APCu slots available',
			'value' => $ac['num_slots'],
		],
		[
			'name'  => 'php_apcu_cache_ops',
			'type'  => 'counter',
			'label' => ['type', 'hits'],
			'desc'  => 'Stats about APCu operations',
			'value' => $ac['num_hits'],
		],
		[
			'name'  => 'php_apcu_cache_ops',
			'type'  => 'counter',
			'label' => ['type', 'misses'],
			'desc'  => '',
			'value' => $ac['num_hits'],
		],
		[
			'name'  => 'php_apcu_cache_ops',
			'type'  => 'counter',
			'label' => ['type', 'inserts'],
			'desc'  => '',
			'value' => $ac['num_inserts'],
		],
		[
			'name'  => 'php_apcu_cache_ops',
			'type'  => 'counter',
			'label' => ['type', 'entries'],
			'desc'  => '',
			'value' => $ac['num_entries'],
		],
		[
			'name'  => 'php_apcu_cache_ops',
			'type'  => 'counter',
			'label' => ['type', 'expunges'],
			'desc'  => '',
			'value' => $ac['expunges'],
		],
		[
			'name'  => 'php_apcu_memory',
			'type'  => 'gauge',
			'label' => ['type', 'free'],
			'desc'  => 'APCu memory status',
			'value' => $ac['avail_mem'],
		],
		[
			'name'  => 'php_apcu_memory',
			'type'  => 'gauge',
			'label' => ['type', 'total'],
			'desc'  => '',
			'value' => $ac['seg_size'],
		],
	];
	$metrics = [];
	foreach ($defs as $metric_def) {
		$t = isset($metric_def['type'])? $metric_def['type'] : 'counter';
		$p = new PrometheusMetric($metric_def['name'], $t, $metric_def['desc']);
		if (isset($metric_def['label'])) {
			$p->setLabel(...$metric_def['label']);
		}
		if (isset($metric_def['value'])) {
			$p->setValue($metric_def['value']);
		}
		$metrics[] = $p;
	}
	return $metrics;
}

function dump_file($name, $contents) {
	if (is_file($name)) {
		if (!unlink($name)) {
			die("Could not remove ${name}.\n");
		}
	}
	file_put_contents(
		$name,
		json_encode($contents)
	);
	echo "Requested data dumped at ${name}.\n";
}

// Views
function show_prometheus_metrics() {
	foreach (prometheus_metrics() as $k) {
		printf("%s", $k);
	}
}

function show_apcu_info() {
	print json_encode(apcu_stats());
}

function dump_apcu_full() {
	$stats = apcu_stats(true);
	dump_file('/tmp/apcu_dump_meta', $stats['cache_list']);
}

function clear_apcu() {
	apcu_clear_cache();
	echo "APCu cache cleared\n";
}

function show_opcache_info() {
	print json_encode(opcache_stats());
}

function dump_opcache_meta() {
	$oc = opcache_stats(true);
	dump_file('/tmp/opcache_dump_meta', $oc['scripts']);
}

function clear_opcache() {
	$result = [];
	$file_name = isset($_GET['file']) ? realpath(MW_PATH . '/' . $_GET['file']) : null;
	// It seems possible that partial opcache clears (of just a subset of
	// files) cause more opcache corruption than resetting the entire opcache
	// wholesale.  For the time being, let's try ignoring any provided
	// filenames and always do full resets.
	// c.f. https://phabricator.wikimedia.org/T221347
	if (true || empty($file_name)) {
		$result['*'] = opcache_reset();
	} else{
		if (strpos($file_name, MW_PATH) !== 0) {
			die("Please don't provide paths outside the working tree.");
		}
		$files = [];
		get_php_files_in($file_name, $files);
		foreach ($files as $file) {
				$result[$file] = opcache_invalidate($file);
		}
	}
	print json_encode($result);
}

function is_php_file($file) {
	if (basename($file) != basename($file, '.php')) {
		return $file;
	} else {
		return false;
	}
}

function get_php_files_in($name, &$php_files) {
	// If just a file is provided, check it's a php file and
	// add it to $php_files and return immediately
	$name = realpath($name);
	if (!is_dir($name)) {
		$file = is_php_file($name);
		if ($file) {
			$php_files[] = $file;
		}
		return;
	}

	// Else, scan the directory for contents
	$files_in_cwd = scandir($name);
	foreach ($files_in_cwd as $filename) {
		$path = realpath($name . '/' . $filename);
		// scandir returns '.' and '..' - let's avoid listing
		// all of the filesystem.
		$len = strlen($name) + 1;
		if (substr($path, 0, $len) != $name . '/') {
			continue;
		}
		get_php_files_in($path, $php_files);
	}
}
