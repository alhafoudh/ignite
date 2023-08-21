import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eventsource/eventsource.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'package:tar/tar.dart';

void main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: ignite <app-name> <source-dir>');
    exit(1);
  }
  final appName = args.first;
  final sourceDir = Directory(args.last);

  // final tarEntries = Stream<TarEntry>.value(
  //   TarEntry.data(
  //     TarHeader(
  //       name: 'hello.txt',
  //       mode: int.parse('644', radix: 8),
  //     ),
  //     utf8.encode('Hello world'),
  //   ),
  // );

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
      "http://localhost:3000/apps/$appName/deployments",
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
