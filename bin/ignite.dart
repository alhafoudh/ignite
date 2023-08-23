import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:eventsource/eventsource.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'package:tar/tar.dart';

class Config {
  String? url;
  String? app;
  String? src;

  Config({this.url, this.app, this.src});

  bool isValid() => url != null && app != null && src != null;

  Config.fromJson(Map<String, dynamic> json)
      : url = json['url'],
        app = json['app'],
        src = json['src'];

  Map<String, dynamic> toJson() => {
        'url': url,
        'app': app,
        'src': src,
      };
}

class InitCommand extends Command {
  @override
  String get description => 'Initialize application in this directory';

  @override
  String get name => 'init';

  InitCommand() {
    argParser.addOption('url', abbr: 'u', help: 'Server URL', mandatory: true);
    argParser.addOption('app', abbr: 'a', help: 'App name', mandatory: true);
    argParser.addOption('src', abbr: 's', help: 'Source dir', defaultsTo: '.');
  }

  @override
  FutureOr run() async {
    final config = await loadConfig();
    config.url = argResults!['url'];
    config.app = argResults!['app'];
    config.src = argResults!['src'];
    saveConfig(config);

    print(
        'Initialized ${config.app} app for server ${config.url} in ${config.src} directory.');
  }
}

class DeployCommand extends Command {
  @override
  String get description => 'Deploy app to server';

  @override
  String get name => 'deploy';

  @override
  FutureOr run() async {
    final config = await loadConfig();
    if (!config.isValid()) {
      print('Please use "ignite init" to initialize app in this directory');
      exit(1);
    }

    final sourceDir = config.src != null ? Directory(config.src!) : null;
    if (sourceDir == null || !await sourceDir.exists()) {
      print('Source directory \'$sourceDir\' does not exist');
      exit(1);
    }

    final fileEntities = await sourceDir.list(recursive: true);
    final tarEntries = fileEntities.map((fileEntry) {
      final fileStat = FileStat.statSync(fileEntry.path);
      final relativePath = relative(fileEntry.path, from: sourceDir.path);
      return TarEntry.data(
        TarHeader(
          name: relativePath,
          mode: fileStat.mode,
          typeFlag: fileStat.type == FileSystemEntityType.directory
              ? TypeFlag.dir
              : TypeFlag.reg,
        ),
        fileStat.type == FileSystemEntityType.directory
            ? []
            : File(fileEntry.path).readAsBytesSync(),
      );
    });

    late List<int> tarBytes;
    final sink = ByteConversionSink.withCallback((data) => tarBytes = data);
    final output = tarConverter.startChunkedConversion(sink);
    final completer = Completer();
    tarEntries.listen((tarEntry) {
      output.add(tarEntry);
    }).onDone(() {
      completer.complete();
    });
    await completer.future;
    output.close();

    final multipartFile = MultipartFile.fromBytes('file', tarBytes,
        filename: 'code.tar', contentType: MediaType('application', 'x-tar'));
    final multipartRequest = MultipartRequest('POST', Uri.base)
      ..files.add(multipartFile);

    final body = await multipartRequest.finalize().bytesToString();

    final eventSource = await EventSource.connect(
        "${config.url}/apps/${config.app}/deployments",
        method: 'POST',
        headers: multipartRequest.headers,
        body: body);
    eventSource.onMessage.listen((Event event) {
      if (event.event == 'message') {
        final json = jsonDecode(event.data!);
        if (json['type'] == 'log') {
          stderr.write('>> ${json['payload']}');
        } else if (json['type'] == 'close') {
          exit(0);
        } else {
          print(':: ${json['type']} ${json['phase']} ${json['payload']}');
        }
      }
    }, onDone: () {
      print('Connection closed');
    });

    eventSource.onOpen.listen((Event message) {
      print('Connection opened');
    });

    eventSource.onError.listen((Event message) {
      print('Error: ${message}');
    });
  }
}

void main(List<String> args) async {
  CommandRunner("ignite", "Command line deployer for Ignite server")
    ..addCommand(InitCommand())
    ..addCommand(DeployCommand())
    ..run(args);
}

Future<Config> loadConfig() async {
  final configFile = File('.ignite');
  if (!await configFile.exists()) {
    return Config();
  }

  final content = await configFile.readAsString();
  return Config.fromJson(jsonDecode(content));
}

Future saveConfig(Config config) async {
  final configFile = File('.ignite');
  await configFile.writeAsString(jsonEncode(config));
}
