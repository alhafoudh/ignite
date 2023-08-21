import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:eventsource/eventsource.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'package:tar/tar.dart';

class Config {
  String? url;

  Config({this.url});
}

void main(List<String> args) async {
  final mainArg = ArgParser();
  final loginCommand = ArgParser();
  mainArg.addCommand('login', loginCommand);
  final deployCommand = ArgParser();
  mainArg.addCommand('deploy', deployCommand);

  final parsed = mainArg.parse(args);

  if (parsed.command?.name == 'login' &&
      parsed.command!.arguments.length == 1) {
    final url = parsed.command!.arguments.first;
    final config = await loadConfig();
    config.url = url;
    await saveConfig(config);
    return;
  } else if (parsed.command?.name == 'deploy' &&
      parsed.command!.arguments.length == 2) {
    final appName = parsed.command!.arguments.first;
    final sourceDir = Directory(parsed.command!.arguments.last);

    await deploy(appName, sourceDir);
  }
}

Future<Config> loadConfig() async {
  final configFile = File('.ignite');
  if (!await configFile.exists()) {
    return Config();
  }

  final content = await configFile.readAsString();
  final json = jsonDecode(content);
  return Config(url: json['url']);
}

Future saveConfig(Config config) async {
  final configFile = File('.ignite');
  final json = jsonEncode({'url': config.url});
  await configFile.writeAsString(json);
}

Future deploy(String appName, Directory sourceDir) async {
  final config = await loadConfig();
  if (config.url == null) {
    print('Please login first');
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
      "${config.url}/apps/$appName/deployments",
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
