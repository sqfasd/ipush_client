var T_SUBSCRIBE = 1;
var T_UNSUBSCRIBE = 2;
var T_MESSAGE = 3;
var T_CHANNEL_MESSAGE = 4;
var T_ACK = 5;
var T_ROOM_JOIN = 6;
var T_ROOM_LEAVE = 7;
var T_ROOM_KICK = 8;
var T_ROOM_SEND = 9;
var T_ROOM_BROADCAST = 10;
var T_COUNT = 11;


var K_FROM = 'f';
var K_TO = 't';
var K_SEQ = 's';
var K_TYPE = 'y';
var K_USER = 'u';
var K_CHANNEL = 'c';
var K_BODY = 'b';
var K_ROOM = 'r';

module.exports = {
  Message: Message,
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

  roomJoinPacket: function(roomId) {
    var msg = new Message();
    msg.setType(T_ROOM_JOIN);
    msg.setRoom(roomId);
    return msg.serialize();
  },

  roomLeavePacket: function(roomId) {
    var msg = new Message();
    msg.setType(T_ROOM_LEAVE);
    msg.setRoom(roomId);
    return msg.serialize();
  },

  roomKickPacket: function(roomId, memberId) {
    var msg = new Message();
    msg.setType(T_ROOM_KICK);
    msg.setRoom(roomId);
    msg.setUser(memberId);
    return msg.serialize();
  },

  roomSendPacket: function(roomId, body, to) {
    var msg = new Message();
    msg.setType(T_ROOM_SEND);
    msg.setRoom(roomId);
    msg.setTo(to);
    msg.setBody(body);
    return msg.serialize();
  },

  roomBroadcastPacket: function(roomId, body) {
    var msg = new Message();
    msg.setType(T_ROOM_BROADCAST);
    msg.setRoom(roomId);
    msg.setBody(body);
    return msg.serialize();
  },
}

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

Message.prototype.isNormalMessage = function() {
  return this.data_[K_TYPE] == T_MESSAGE;
}

Message.prototype.isChannelMessage = function() {
  return this.data_[K_TYPE] == T_CHANNEL_MESSAGE;
}

Message.prototype.isRoomSendMessage = function() {
  return this.data_[K_TYPE] == T_ROOM_SEND;
}

Message.prototype.isRoomBroadcastMessage = function() {
  return this.data_[K_TYPE] == T_ROOM_BROADCAST;
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

Message.prototype.setRoom = function(room) {
  this.data_[K_ROOM] = room;
}

Message.prototype.room = function() {
  return this.data_[K_ROOM];
}
