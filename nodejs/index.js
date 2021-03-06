var querystring = require('querystring');
var WebSocketClient = require('websocket').client;
var protocol = require('./protocol');

var DEFAULT_KEEPALIVE_INTERVAL_MS = 30000;

module.exports = {
  XCometClient: XCometClient,
  XCometMessage: protocol.Message,
}

function isFunction(f) {
  return f instanceof Function;
}

function XCometClient(address, options) {
  this.uid = options.uid;
  this.password = options.password;
  this.sock_;
  this.conn_;
  this.address_ = address;
  this.full_url_;
  this.keepAliveTimer_;
  this.onOpen = function() {}
  this.onError = function(error) {}
  this.onClose = function() {}
  this.onMessage = function(message) {}

  if (!this.uid || !this.password || !this.address_) {
    throw new Error("uid or password must be provided");
  }

  this.full_url_ = 'ws://' + address + '/connect?' +
                   querystring.stringify(options);
  console.log('full_url_ = ', this.full_url_);

  this.sock_ = new WebSocketClient(this.full_url_);
  this.sock_.connect(this.full_url_);

  this.sock_.on('connect', function(connection) {
    console.log('connected');
    this.conn_ = connection;
    if (isFunction(this.onOpen)) {
      this.onOpen();
    }

    this.restartKeepAlive();

    connection.on('error', function(error) {
      console.log('connection error ' + error);
      if (isFunction(this.onError)) {
        this.onError(error);
      }
    }.bind(this));

    connection.on('close', function(reason, description) {
      console.log('connection closed with reason ' + reason
                  + ', desc ' + description);
      if (isFunction(this.onClose)) {
        this.onClose();
      }
    }.bind(this));

    connection.on('message', function(message) {
      console.log('receive message', message);
      if (message.type !== 'utf8' && isFunction(this.onError)) {
        this.onError(new Error('unexpected message type'));
        return;
      }
      try {
        var msg = new protocol.Message(message.utf8Data);
        this.sendAck(msg.seq());
        if (isFunction(this.onMessage)) {
          this.onMessage(msg);
        }
      } catch (e) {
        if (isFunction(this.onError)) {
          this.onError(new Error('message format error'));
        }
      }
    }.bind(this));

  }.bind(this));
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
  this.conn_.sendUTF(data);
}

XCometClient.prototype.send = function(body, to) {
  this.sendPacket(protocol.sendPacket(body, to));
}

XCometClient.prototype.publish = function(body, channel) {
  this.sendPacket(protocol.publishPacket(body, channel));
}

XCometClient.prototype.sub = function(channelId) {
  this.sendPacket(protocol.subPacket(channelId, this.uid));
}

XCometClient.prototype.unsub = function(channelId) {
  this.sendPacket(protocol.unsubPacket(channelId, this.uid));
}

XCometClient.prototype.close = function() {
  this.conn_.close();
}

XCometClient.prototype.sendAck= function(seq) {
  this.sendPacket(protocol.ackPacket(seq));
}
