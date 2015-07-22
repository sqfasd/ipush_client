var readline = require('readline');
var XCometClient = require('./index').XCometClient;

var address;
var options = {};
var client;
var rl;

function main(argv) {
  if (argv.length != 5) {
    console.log('usage: $PROGRAM <address> <uid> <password>');
    console.log('example: $PROGRAM 127.0.0.1:9000 user123 password123');
    return;
  }
  address = argv[2];
  options.uid = argv[3];
  options.password = argv[4];

  try {
    client = new XCometClient(address, options);
    client.onOpen = function() {
      console.log('client onOpen');
    }
    client.onClose = function() {
      console.log('client onClose');
      rl.close();
      process.exit(1);
    }
    client.onError = function(error) {
      console.log('client onError', error);
    }
    client.onMessage = function(message) {
      console.log('client.onMessage: ' + message);
    }
  } catch (e) {
    console.log('exception caught', e);
    return;
  }

  process.on('uncaughtException', function(err) {
    console.log('Caught exception', err);
    client.close();
    process.exit(1);
  });

  process.on('SIGINT', function() {
    console.log('Got SIGINT');
    client.close();
    process.exit(1);
  });

  rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  rl.setPrompt('xcomet@' + options.uid + '> ');

  rl.on('line', function(line) {
    var fields = line.split(' ');
    if (line && fields && fields.length > 0) {
      var cmd = fields[0];
      switch (cmd) {
        case 'msg':
          var body = fields[1];
          var to= fields[2];
          client.send(body, to);
          break;
        case 'cmsg':
          var body = fields[1];
          var channel = fields[2];
          client.publish(body, channel);
          break;
        case 'sub':
          var cid = fields[1];
          client.sub(cid);
          break;
        case 'unsub':
          var cid = fields[1];
          client.unsub(cid);
          break;
        case 'close':
        case 'bye':
        case 'exit':
        case 'quit':
        case 'q':
          client.close();
          process.exit(0);
          break;
        case '?':
        case 'help':
        case 'h':
          console.log('msg <body> <to>');
          console.log('cmsg <body> <channel>');
          console.log('sub <channel>');
          console.log('unsub <channel>');
          break;
        default:
          console.log('unsupported cmd');
          break;
      }
    }
    rl.prompt();
  });
}

main(process.argv);
