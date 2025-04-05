import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Stream',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const LiveStreamPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LiveStreamPage extends StatefulWidget {
  const LiveStreamPage({Key? key}) : super(key: key);

  @override
  _LiveStreamPageState createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  late VlcPlayerController _controller;
  bool _isPlaying = true;
  bool _isError = false;
  String _errorMessage = '';
  
  // RTMP stream URL
  final String rtmpUrl = "rtmp://172.20.10.14/live/stream_key";

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Keep screen on using wakelock_plus
    _initializePlayer();
  }

  void _initializePlayer() {
    _controller = VlcPlayerController.network(
      rtmpUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000),
          VlcAdvancedOptions.fileCaching(1000),
          VlcAdvancedOptions.liveCaching(1000),
        ]),
        http: VlcHttpOptions([
          VlcHttpOptions.httpReconnect(true),
        ]),
        rtp: VlcRtpOptions([
          VlcRtpOptions.rtpOverRtsp(true),
        ]),
        //sout: VlcSoutOptions([]),
        video: VlcVideoOptions([]),
      ),
    );

    _controller.addOnInitListener(() {
      setState(() {
        _isError = false;
      });
    });

    
  }

  @override
  void dispose() {
    _controller.dispose();
    WakelockPlus.disable(); // Disable wakelock when disposing
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: _isError
              ? _buildErrorWidget()
              : _buildPlayerWidget(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_isPlaying) {
              _controller.pause();
              _isPlaying = false;
            } else {
              _controller.play();
              _isPlaying = true;
            }
          });
        },
        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }

  Widget _buildPlayerWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: VlcPlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
            placeholder: const Center(child: CircularProgressIndicator()),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Live Stream',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Stream Error',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Could not connect to the live stream. Please try again later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _controller.dispose();
              _initializePlayer();
            },
            child: const Text('Retry'),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Technical details: $_errorMessage',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}