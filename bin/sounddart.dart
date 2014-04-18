import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:unscripted/unscripted.dart';

bool VERBOSE;
String SEP = Platform.isWindows?'\\':'/';

main(arguments) => declare(sounddart).execute(arguments);

@Command(help: 'Combines uncompressed sound files, encodes to popular formats, and generates json atlas.')
@ArgExample('-o audio *.wav', help: 'wildcard expansion supported even if your shell doesn\'t')
@ArgExample('-e "mp3,ogg" *.wav', help: 'only export mp3 and ogg formats')
sounddart(
    @Rest(name: 'files', help: "Sound files to join together.", required: true)
    List<String> files,
    { 
      @Option(abbr: 'o', help: 'Filename for the output file(s), without extension.')
      String output : 'output', 
      @Option(abbr: 'e', help: 'Limit exported file types. eg "mp3,ogg"')
      String export : '',
      @Option(abbr: 'r', help: 'Sample rate.')
      String samplerate: '44100',
      @Option(abbr: 'c', help: 'Number of channels (1=mono, 2=stereo).')
      String channels: '1',
      @Option(abbr: 'g', help: 'Length of gap in seconds.')
      String gap: '.25',
      @Flag(abbr: 'v', help: 'Be super chatty.')
      bool verbose: false
     }
){
  
  var SAMPLE_RATE = int.parse(samplerate);
  var NUM_CHANNELS = int.parse(channels);
  var GAP = double.parse(gap);
  
  VERBOSE = verbose;
  
  //TODO if wildcard * present in passed files list, expand that shiz
  var expandFiles = [];
  files.forEach((file) {
    if(file.contains('*')) {
      var dirStr = file.contains(SEP)?file.substring(0, file.lastIndexOf(SEP)):'.$SEP';
      var fileStr = file.substring(file.lastIndexOf(SEP)+1);
      var dir = new Directory(dirStr);
      var pattern = new RegExp(fileStr.replaceAll('*', r'.*'));
      var matches = dir.listSync().where((f) => pattern.hasMatch(f.path)).map((f) => f.path);
      if(matches.length>0) expandFiles.addAll(matches);
    } else expandFiles.add(file);
      
  });
  //make list unique
  files = expandFiles.toSet().toList(growable: false);
  
  var offsetCursor = 0;
  var wavArgs = '-ar $SAMPLE_RATE -ac $NUM_CHANNELS -f s16le'.split(' ');
  var formats = {
  'opus': '-acodec libopus', //opus, -b:a 128k -vbr on and -compression_level 10 enabled by default
  'mp3': '-ar $SAMPLE_RATE -aq 4 -f mp3', //was -ab 128k now -aq 4 (VBR good quality)
  'm4a': '', //guess defaults work - can't use VBR here, so will be larger
  'ogg': '-acodec libvorbis -qscale:a 5' //-qscale:a 5 - VBR
  };
  
  //if provided, limit to specified formats
  if(export.length>0) formats = new Map.fromIterable(formats.keys.where((k) => export.contains(k)),
      value: (k) => formats[k]);
  
  //TODO allow user to customize json template
  //var json = {'urls': [], 'sprite': {}};
  var sprites = {};
  var urls = [];
  
  if(!haveFfmpeg()) return;
  //ffmpeg is ready to roll
  
  //create temporary file to hold appended files
  var tmpFile = mktemp();
  
  //gap bytes
  var silence = new List.filled((SAMPLE_RATE * 2 * NUM_CHANNELS * GAP).round(), 0);
  var counter = 0;
  
  Future.forEach(files, (filename) {
    var dest = Directory.systemTemp.createTempSync('sounddart');
    var file = new File(filename);
    var name = filename.substring(filename.lastIndexOf(SEP)+1, filename.lastIndexOf('.'));
    if(file.existsSync()) {
      var tmp = mktemp();
      
      var args =  ['-i', filename];
      args.addAll(wavArgs);
      args.add(tmp.path);
      log('ffmpeg ${args.join(' ')}');
      var ffmpeg = Process.run('ffmpeg', args);
      
      ffmpeg.then((res) {
        tmpFile.writeAsBytesSync(tmp.readAsBytesSync(), mode: FileMode.APPEND);
        log('appended ${tmp.path} to ${tmpFile.path}');
        var dur = tmp.lengthSync() / SAMPLE_RATE / NUM_CHANNELS / 2;
        sprites.putIfAbsent(name, () => [offsetCursor, dur]);
        print('$name added at ${offsetCursor.toStringAsFixed(2)} seconds, length ${dur.toStringAsFixed(2)} seconds');
        offsetCursor += dur;
        tmp.deleteSync();
        log('removed ${tmp.path}');
        //add gap if not last
        if(++counter<files.length) {
          tmpFile.writeAsBytesSync(silence, mode: FileMode.APPEND);
          offsetCursor += GAP;
        } 
      });
      
      return ffmpeg;
      
    } else {
      print('File $filename does not exist');
    }
    
  }).whenComplete(() {
   
    var tmpSize = tmpFile.lengthSync();
    var tmpDur = tmpSize / SAMPLE_RATE / NUM_CHANNELS / 2;
    print('Total sprite length ${tmpDur.toStringAsFixed(2)} seconds, uncompressed size ${(tmpSize/1024).round()} KB');
    var pwd = Directory.current.path;
    var inArgs = '-y -ac $NUM_CHANNELS -f s16le -i ${tmpFile.path}';
    Future.forEach(formats.keys, (format) {
      var outName = '$output.$format';
      var argStr = '$inArgs ${formats[format]} $outName';
      log('ffmpeg $argStr');
      List args = argStr.split(' ');
      
      var ffmpeg = Process.run('ffmpeg', args);
      ffmpeg.then((res) {
        var outSize = new File(outName).lengthSync();
        print('$outName created, compressed size ${(outSize/1024).round()} KB');
        urls.add(outName);  
      });
      
      return ffmpeg;
      
    }).whenComplete(() {
      tmpFile.deleteSync();
      log('removed ${tmpFile.path}');
      var json = {'urls': urls, 'sprite': sprites};
      
      var atlas = new File('$output.json');
      atlas.writeAsStringSync(JSON.encode(json));
      atlas.createSync();
      
      print('all done - kthxbye!');
    });
    
  });

  
}

bool haveFfmpeg() {
  try {
    Process.runSync('ffmpeg', ['-version']);  
  } catch(exception, trace) {
    print('whoa now - ffmpeg was not found on your path');
    log(exception);
    return false;
  }
  return true;
}

File mktemp() {
  var rand = new Random();
  var tmpName = 'sounddart${rand.nextInt(999999)+100000}';
  log('create temporary file $tmpName');
  return new File('${Directory.systemTemp.path}${SEP}${tmpName}');
}

void log(String message) {
  if(VERBOSE) print(message);
}