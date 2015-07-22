/*!
 * xcomet-client JavaScript Library v0.1.0
 *
 * Copyright 2015 xuexibao.com, Inc.
 * Date: 2015-07-20
 */

;(function(window, undefined) {
  var T_SUBSCRIBE = 1;
  var T_UNSUBSCRIBE = 2;
  var T_MESSAGE = 3;
  var T_CHANNEL_MESSAGE = 4;
  var T_ACK = 5;
  var T_COUNT = 6;


  var K_FROM = 'f';
  var K_TO = 't';
  var K_SEQ = 's';
  var K_TYPE = 'y';
  var K_USER = 'u';
  var K_CHANNEL = 'c';
  var K_BODY = 'b';

  var DEFAULT_KEEPALIVE_INTERVAL_MS = 30000;

  function Message(raw) {
    if (raw) {
      try {
        this.data_ = JSON.parse(raw);
      } catch (e) {
        console.error('parse message failed', e);
        this.data_ = {};
      }
    } else {
      this.data_ = {};
    }
  }

  Message.prototype.toString = function() {
    return JSON.stringify(this.data_);
  }

  Message.prototype.serialize = function() {
    return JSON.stringify(this.data_);
  }

  Message.prototype.setFrom = function(from) {
    this.data_[K_FROM] = from;
  }

  Message.prototype.from = function() {
    return this.data_[K_FROM];
  }

  Message.prototype.setTo = function(to) {
    this.data_[K_TO] = to;
  }

  Message.prototype.to = function() {
    return this.data_[K_TO];
  }

  Message.prototype.setSeq = function(seq) {
    this.data_[K_SEQ] = seq;
  }

  Message.prototype.seq = function() {
    return this.data_[K_SEQ];
  }

  Message.prototype.setType = function(type) {
    this.data_[K_TYPE] = type;
  }

  Message.prototype.type = function() {
    return this.data_[K_TYPE];
  }

  Message.prototype.setUser = function(user) {
    this.data_[K_USER] = user;
  }

  Message.prototype.user = function() {
    return this.data_[K_USER];
  }

  Message.prototype.setChannel = function(channel) {
    this.data_[K_CHANNEL] = channel;
  }

  Message.prototype.channel = function() {
    return this.data_[K_CHANNEL];
  }

  Message.prototype.setBody = function(body) {
    this.data_[K_BODY] = body;
  }

  Message.prototype.body = function() {
    return this.data_[K_BODY];
  }

  var protocol = {
    heartbeatPacket: function() {
      return ' ';
    },

    sendPacket: function(body, to) {
      var msg = new Message();
      msg.setType(T_MESSAGE);
      msg.setBody(body);
      msg.setTo(to);
      return msg.serialize();
    },

    publishPacket: function(body, channel) {
      var msg = new Message();
      msg.setType(T_CHANNEL_MESSAGE);
      msg.setBody(body);
      msg.setChannel(channel);
      return msg.serialize();
    },

    subPacket: function(cid, uid) {
      var msg = new Message();
      msg.setType(T_SUBSCRIBE);
      msg.setChannel(cid);
      msg.setUser(uid);
      return msg.serialize();
    },

    unsubPacket: function(cid, uid) {
      var msg = new Message();
      msg.setType(T_UNSUBSCRIBE);
      msg.setChannel(cid);
      msg.setUser(uid);
      return msg.serialize();
    },

    ackPacket: function(seq) {
      var msg = new Message();
      msg.setType(T_ACK);
      msg.setSeq(seq);
      return msg.serialize();
    },
  };

  function isFunction(f) {
    return f instanceof Function;
  }

  function joinURLParameters(obj) {
    var str = '';
    for (var k in obj) {
      var v = obj[k];
      str += k;
      str += '=';
      str += v;
      str += '&';
    }
    if (str.charAt(str.length - 1) == '&') {
      str = str.slice(0, -1);
    }
    return str;
  }

  function XCometClient(address, options) {
    this.uid = options.uid;
    this.password = options.password;
    this.sock_;
    this.address_ = address;
    this.full_url_;
    this.keepAliveTimer_;
    this.onOpen = function() {}
    this.onError = function(error) {}
    this.onClose = function() {}
    this.onMessage = function(message) {}

    if (!this.uid || !this.password || !this.address_) {
      throw new Error('invalid parameters');
    }

    this.full_url_ = 'ws://' + address + '/connect?' +
                     joinURLParameters(options);
    console.log('full_url_ = ', this.full_url_);

    if (!window || !window.WebSocket) {
      throw new Error('WebSocket not support');
    }
    this.sock_ = new window.WebSocket(this.full_url_);

    this.sock_.onopen = function() {
      console.log('websocket onopen');
      if (isFunction(this.onOpen)) {
        this.onOpen();
        this.restartKeepAlive();
      }
    }.bind(this);

    this.sock_.onmessage = function(e) {
      console.log('websocket onmessage', e);
      try {
        var msg = new Message(e.data);
        this.sendAck(msg.seq());
        if (isFunction(this.onMessage)) {
          this.onMessage(msg);
        }
      } catch (e) {
        if (isFunction(this.onError)) {
          this.onError(new Error('message format error'));
        }
      }
    }.bind(this);

    this.sock_.onclose = function(e) {
      console.log('websocket closed', e);
      if (this.keepAliveTimer_) {
        console.log('clear keepalive timer');
        clearInterval(this.keepAliveTimer_);
      }
      if (isFunction(this.onClose)) {
        this.onClose();
      }
    }.bind(this);
  }

  XCometClient.prototype.restartKeepAlive = function() {
    if (this.keepAliveTimer_) {
      clearInterval(this.keepAliveTimer_);
    }
    this.keepAliveTimer_ = setInterval(
      function() {
        console.log('send heartbeat');
        this.sendPacket(protocol.heartbeatPacket());
      }.bind(this),
      DEFAULT_KEEPALIVE_INTERVAL_MS
    );
  }

  XCometClient.prototype.sendPacket = function(data) {
    this.restartKeepAlive();
    this.sock_.send(data);
  }

  XCometClient.prototype.send = function(body, to) {
    this.sendPacket(protocol.sendPacket(body, to));
  }

  XCometClient.prototype.publish = function(body, channel) {
    this.sendPacket(protocol.publishPacket(body, channel));
  }

  XCometClient.prototype.sub = function(channelId) {
    this.sendPacket(protocol.subPacket(this.channelId, this.uid));
  }

  XCometClient.prototype.unsub = function(channelId) {
    this.sendPacket(protocol.unsubPacket(this.channelId, this.uid));
  }

  XCometClient.prototype.close = function() {
    this.sock_.close();
  }

  XCometClient.prototype.sendAck= function(seq) {
    this.sendPacket(protocol.ackPacket(seq));
  }

  window.XCometClient = XCometClient;
  window.XCometMessage = Message;
})(window);
