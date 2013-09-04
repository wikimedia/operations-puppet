/**
 * Gmetric.js
 * Gmetric packet submission for node.js
 * https://github.com/jbuchbinder/node-gmetric
 */
(function() {
  /**
   * Module dependencies.
   */

  var dgram  = require('dgram'),
      socket = require('dgram').createSocket('udp4');

  /**
   *  The Gmetric class.
   */

  var Gmetric = (function(){
    function Gmetric(){}

    /**
     * Packs an integer as a big endian unsigned long.
     * refs: http://code.google.com/p/embeddedgmetric/wiki/GmetricProtocol
     * refs: http://www.ietf.org/rfc/rfc4506.txt
     * @param  {Buffer}  (target) The target Buffer to pack onto
     * @param  {Integer} (i) The integer to pack
     * @param  {Integer} (pos) The position to begin the pack
     * @return {Integer} The current position in the buffer
     */

    Gmetric.prototype.pack_int = function(target, i, pos){
      if (i === undefined || i === null){
        i = 0;
      }
      i = parseInt(i, 10);
      target.writeInt32BE(i, pos);
      return pos + 4;
    };

    /**
     * Packs a boolean as a big endian unsigned long.
     * refs: http://code.google.com/p/embeddedgmetric/wiki/GmetricProtocol
     * refs: http://www.ietf.org/rfc/rfc4506.txt
     * @param  {Buffer}  (target) The target Buffer to pack onto
     * @param  {Integer} (b) The boolean to pack
     * @param  {Integer} (pos) The position to begin the pack
     * @return {Integer} The current position in the buffer
     */

    Gmetric.prototype.pack_bool = function(target, b, pos){
      return this.pack_int(target, (b ? 1 : 0), pos);
    };

    /**
     * Packs a string matching the xdr format.
     * refs: http://code.google.com/p/embeddedgmetric/wiki/GmetricProtocol
     * refs: http://www.ietf.org/rfc/rfc4506.txt
     * @param  {Buffer}  (target) The target Buffer to pack onto
     * @param  {String}  (data) The string to pack
     * @param  {Integer} (pos) The position to begin the pack
     * @return {Integer} The current position in the buffer
     */

    Gmetric.prototype.pack_string = function(target, data, pos){
      if (data === null || data === undefined){
        data = "";
      }
      data = data.toString();
      pos = this.pack_int(target, data.length, pos);

      var fill_length = this.string_fill_length(data);
      pos += target.write(data, pos, 'ascii');
      target.fill(0, pos, (pos + fill_length));
      return pos + fill_length;
    };

    /**
     * Returns the xdr fill length for a given string.
     * @param  {String}  (str) The string to retrieve the fill length for
     * @return {Integer} The xdr fill length for the given string
     */

    Gmetric.prototype.string_fill_length = function(str){
      var len = str.length;
      len = Math.floor((len + 3) / 4) * 4;
      return (len - str.length);
    };

    /**
     * Unpacks an xdr string.
     * @param  {Buffer}  (buffer) The buffer to read from
     * @param  {Integer} (pos) The current buffer position
     * @return {Object}  The unpacked string and buffer position
     */

    Gmetric.prototype.unpack_string = function(buffer, pos){
      var unpack, strlen, unpacked_string;

      // Parse the string length
      unpack = this.unpack_int(buffer, pos);
      pos = unpack.pos;
      strlen = unpack.integer;

      // Parse the string and update the position
      unpacked_string = buffer.toString('ascii', pos, pos+strlen);
      pos += strlen;

      // Add the fill length onto the position
      pos += this.string_fill_length(unpacked_string);
      return { string: unpacked_string, pos: pos };
    };

    /**
     * Unpacks an xdr integer.
     * @param  {Buffer}  (buffer) The buffer to read from
     * @param  {Integer} (pos) The current buffer position
     * @return {Object}  The unpacked integer and buffer position
     */

    Gmetric.prototype.unpack_int = function(buffer, pos){
      var unpacked = null;
      try{
        unpacked = buffer.readInt32BE(pos);
        pos += 4;
      } catch (err){}
      return { integer: unpacked, pos: pos };
    };

    /**
     * Unpacks an xdr boolean.
     * @param  {Buffer}  (buffer) The buffer to read from
     * @param  {Integer} (pos) The current buffer position
     * @return {Object}  The unpacked boolean and buffer position
     */

    Gmetric.prototype.unpack_bool = function(buffer, pos){
      var unpacked = this.unpack_int(buffer, pos);
      unpacked.bool = (unpacked.integer === 1);
      delete unpacked.integer;
      return unpacked;
    };

    /**
     * Returns the list of metric elements considered extras.
     * @param  {Object} (metric) The gmetric metric hash
     * @return {Array} The list of gmetric objects considered to be extras
     */

    Gmetric.prototype.extra_elements = function(metric){
      var keys = Object.keys(metric);
      var extra_elems = [];

      for(var i = 0; i < keys.length; i++){
        if (module.exports.natural_metrics.hasOwnProperty(keys[i]) !== true){
          extra_elems.push(keys[i]);
        }
      }
      return extra_elems;
    };

    /**
     * Creates the metadata buffer for the gmetric packet.
     * refs: http://code.google.com/p/embeddedgmetric/wiki/GmetricProtocol
     * refs: http://www.ietf.org/rfc/rfc4506.txt
     * @param  {Object} (metric) The gmetric metric hash
     * @return {Buffer} The meta buffer
     */

    Gmetric.prototype.create_meta = function(metric){
      var buffer = new Buffer(1024), pos = 0, extra_elems = [];
      pos = this.pack_int(buffer, 128, pos);                // gmetadata_full
      pos = this.pack_string(buffer, metric.hostname, pos); // hostname
      pos = this.pack_string(buffer, metric.name, pos);     // metric name
      pos = this.pack_bool(buffer, metric.spoof, pos);      // spoof flag

      pos = this.pack_string(buffer, metric.type, pos);     // metric type
      pos = this.pack_string(buffer, metric.name, pos);     // metric name
      pos = this.pack_string(buffer, metric.units, pos);    // metric units
      pos = this.pack_int(buffer,
        module.exports.slope[metric.slope], pos);           // slope derivative
      pos = this.pack_int(buffer, metric.tmax, pos);        // max between
      pos = this.pack_int(buffer, metric.dmax, pos);        // lifetime

      // Magic Number: The number of extra data elements
      extra_elems = this.extra_elements(metric);
      pos = this.pack_int(buffer, extra_elems.length, pos);

      // Metadata Extra Data: key/value functionality
      for(var i = 0; i < extra_elems.length; i++){
        pos = this.pack_string(buffer, extra_elems[i].toUpperCase(), pos);
        pos = this.pack_string(buffer, metric[extra_elems[i]], pos);
      }
      return buffer.slice(0, pos);
    };

    /**
     * Creates the data buffer for the gmetric packet.
     * refs: http://code.google.com/p/embeddedgmetric/wiki/GmetricProtocol
     * refs: http://www.ietf.org/rfc/rfc4506.txt
     * @param  {Object} (metric) The gmetric metric hash
     * @return {Buffer} The data buffer
     */

    Gmetric.prototype.create_data = function(metric){
      var buffer = new Buffer(512), pos = 0, value = metric.value.toString();
      pos = this.pack_int(buffer, 128+5, pos);                // string message
      pos = this.pack_string(buffer, metric.hostname, pos);   // hostname
      pos = this.pack_string(buffer, metric.name, pos);       // metric name
      pos = this.pack_bool(buffer, metric.spoof, pos);        // spoof flag
      pos = this.pack_string(buffer, "%s", pos);              //
      pos = this.pack_string(buffer, value, pos);             // metric value
      return buffer.slice(0, pos);
    };

    /**
     * Create the final package from a metric to send to the gmond target.
     * @param  {Object} (metric) The metric packet to merge and pack
     * @return {Object} The gmetric meta and data packets
     */

    Gmetric.prototype.pack = function(opts){
      var metric = {
        hostname: '',
        group:    '',
        spoof:    0,
        units:    '',
        slope:    'both',
        tmax:     60,
        dmax:     0
      };

      for ( var key in opts ) {
          metric[key] = opts[key];
      }

      // Convert bools to ints
      if (metric.spoof === true){
        metric.spoof = 1;
      } else if(metric.spoof === false){
        metric.spoof = 0;
      }

      if ("name"  in metric !== true ||
          "value" in metric !== true ||
          "type"  in metric !== true){
        throw new Error("Missing name, value, type");
      }

      if (metric.type in module.exports.supported_types !== true){
        throw new Error("Invalid metric type");
      }

      var meta = this.create_meta(metric);
      var data = this.create_data(metric);
      return { meta: meta,  data: data };
    };

    /**
     * Unpacks a gmetric meta packet.
     * @param  {Buffer} (meta_packet) The meta packet buffer to unpack
     * @return {Object} The parsed meta packet
     */

    Gmetric.prototype.parse_meta = function(meta_packet){
      var meta = {}, unpack = null;
      if (meta_packet.readInt32BE(0) !== 128){
        throw new Error("Invalid meta packet");
      }
      var pos = 4;

      // Parse hostname
      unpack = this.unpack_string(meta_packet, pos);
      pos = unpack.pos;
      meta.hostname = unpack.string;

      // Parse metric name
      unpack = this.unpack_string(meta_packet, pos);
      pos = unpack.pos;
      meta.name = unpack.string;

      // Parse spoof flag
      unpack = this.unpack_bool(meta_packet, pos);
      pos = unpack.pos;
      meta.spoof = unpack.bool;

      // Parse metric type
      unpack = this.unpack_string(meta_packet, pos);
      pos = unpack.pos;
      meta.type = unpack.string;

      // Parse metric name
      unpack = this.unpack_string(meta_packet, pos);
      pos = unpack.pos;
      meta.name = unpack.string;

      // Parse metric units
      unpack = this.unpack_string(meta_packet, pos);
      pos = unpack.pos;
      meta.units = unpack.string;

      // Parse slope derivative
      unpack = this.unpack_int(meta_packet, pos);
      pos = unpack.pos;
      meta.slope = module.exports.slope2str[unpack.integer];

      // Parse tmax
      unpack = this.unpack_int(meta_packet, pos);
      pos = unpack.pos;
      meta.tmax = unpack.integer;

      // Parse dmax
      unpack = this.unpack_int(meta_packet, pos);
      pos = unpack.pos;
      meta.dmax = unpack.integer;

      // Parse number of extra data elements
      unpack = this.unpack_int(meta_packet, pos);
      pos = unpack.pos;
      var extra_elems = unpack.integer;

      // Parse each metadata key/value pair and add it into extras
      for(var i = 0; i < extra_elems; i++) {
        var extra_key, extra_value;

        unpack = this.unpack_string(meta_packet, pos);
        pos = unpack.pos;
        extra_key = unpack.string.toLowerCase();
        unpack = this.unpack_string(meta_packet, pos);
        pos = unpack.pos;
        extra_value = unpack.string;
        meta[extra_key] = extra_value;
      }

      return meta;
    };

    /**
     * Unpacks a gmetric data packet.
     * @param  {Buffer} (data_packet) The data packet buffer to unpack
     * @return {Object} The parsed data packet
     */

    Gmetric.prototype.parse_data = function(data_packet){
      var data = {}, unpack = null;
      if (data_packet.readInt32BE(0) !== 133){
        throw new Error("Invalid data packet");
      }
      var pos = 4;

      // Parse hostname
      unpack = this.unpack_string(data_packet, pos);
      pos = unpack.pos;
      data.hostname = unpack.string;

      // Parse metric name
      unpack = this.unpack_string(data_packet, pos);
      pos = unpack.pos;
      data.name = unpack.string;

      // Parse spoof flag
      unpack = this.unpack_bool(data_packet, pos);
      pos = unpack.pos;
      data.spoof = unpack.bool;

      // Parse metric value
      unpack = this.unpack_string(data_packet, pos);
      pos = unpack.pos;
      unpack = this.unpack_string(data_packet, pos);
      pos = unpack.pos;
      data.value = unpack.string;

      return data;
    };

    /**
     * Unpacks a gmetric packet.
     * @param  {Buffer} (packet) The packet to unpack
     * @return {Object} The parsed data or metadata packet
     */

    Gmetric.prototype.unpack = function(packet){
      if (packet.readInt32BE(0) === 128) {
        return this.parse_meta(packet);
      } else if (packet.readInt32BE(0) === 133) {
        return this.parse_data(packet);
      }
    };

    /**
     * Sends a packet buffer over UDP.
     * @param {String} (host) The target host
     * @param {Integer} (port) The target port
     * @param {Buffer} (packet) The packet buffer to send
     */

    Gmetric.prototype.send_packet = function(host, port, packet){
      socket.send(packet, 0, packet.length, port, host, function (err, bytes){
          if (err){
            console.log(err);
          }
        });
    };

    /**
     * Sends a metric packet over UDP.
     * @param {String} (host) The target host
     * @param {Integer} (port) The target port
     * @param {Object} (metric) The metric to send
     */

    Gmetric.prototype.send = function(host, port, metric){
      var packet = this.pack(metric);
      this.send_packet(host, port, packet.meta);
      this.send_packet(host, port, packet.data);
    };

    /**
     * Sends a metric packet over UDP broadcast
     * @param {String} (host) The target host
     * @param {Integer} (port) The target port
     * @param {Object} (metric) The metric to send
     */

    Gmetric.prototype.send_broadcast = function(host, port, metric){
      var packet = this.pack(metric);
      socket.setBroadcast(true);
      socket.setMulticastTTL(128);
      socket.addMembership(host);
      this.send_packet(host, port, packet.meta);
      this.send_packet(host, port, packet.data);
    };

    /**
     * Closes the udp socket.
     */

    Gmetric.prototype.close = function() {
        socket.close();
    };

    return Gmetric;

  })();

  /**
   * Expose `createGmetric()`.
   */

  module.exports = Gmetric;

  /**
   * Expose slope.
   */

  module.exports.slope = {
    zero: 0,
    positive: 1,
    negative: 2,
    both: 3,
    unspecified: 4
  };

  /**
   * Expose slope2str.
   */

  module.exports.slope2str = {
    0: 'zero',
    1: 'positive',
    2: 'negative',
    3: 'both',
    4: 'unspecified'
  };

  /**
   * Expose supported_types.
   */

  module.exports.supported_types = {
    string: true,
    int8: true,
    uint8: true,
    int16: true,
    uint16: true,
    int32: true,
    uint32: true,
    float: true,
    double: true
  };

  /**
   * Expose natural_metrics.
   */

  module.exports.natural_metrics = {
    hostname: true,
    spoof: true,
    units: true,
    slope: true,
    name:  true,
    value: true,
    type:  true,
    tmax: true,
    dmax: true
  };

}).call(this);
