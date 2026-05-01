## Environment Setup
- FFmpeg Version: 8.1-full_build-www.gyan.dev (gcc 15.2.0, MSYS2)
- Key FFmpeg features enabled: libx264, dshow, libopus, libmp3lame

## Camera and Audio Setup
- `ffmpeg -list_devices true -f dshow -i dummy` to find video devices
- `ffmpeg -f dshow -list_options true -i "video=YOUR_CAMERA"` to list supported modes
- Supported modes of my laptop:
  - MJPEG: 1280x720@30fps, 640x480@30fps, 640x360@30fps, 320x240@30fps
  - YUYV422: 1280x720@10fps, 640x480@30fps, 640x360@30fps, 320x240@30fps
- Audio Device identified via DirectShow (e.g., audio=Mikrofon (USB Pro Audio)).

## Camera Format
- YUYV422 at 640x480@30fps - raw uncompressed format
- Pixel format is only the camera input format. The output is H.264/AVC. FFmpeg converts yuyv422 to H.264 during encoding.
- Added `-pix_fmt yuv420p` to convert camera's 4:2:2 to standard 4:2:0 for browser compatibility

## SDKs and Tools Used
Server:
- FFmpeg (video capture + H.264 encoding + DASH segmentation)
- NGINX (HTTP server for serving DASH segments)
Client:
- dash.js (JavaScript DASH player library)
- HTML5 Media Source Extensions (MSE)

### FFmpeg DASH Capture Pipeline
- File: server/start_capture.ps1
- What it does: Captures webcam and microphone, encodes to H.264 and AAC, outputs DASH segments.
- Config file: config/config.env (all parameters configurable)
- Frame duplication (dup= in output) caused timing mismatch. Fixed by adding `-r 30` to force output framerate.
- Camera outputs yuyv422 which some browsers reject. Fixed with `-pix_fmt yuv420p`.

| Flag | Purpose |
|------|---------|
| `-f dshow` | Windows DirectShow camera input |
| `-pixel_format yuyv422` | Camera's raw format |
| `-video_size 640x480` | Capture resolution |
| `-c:v libx264` | H.264/AVC encoder (project requirement) |
| `-preset veryfast` | Fast encoding for real-time |
| `-tune zerolatency` | Minimize encoding delay |
| `-b:v 1500k` | Target bitrate |
| `-r 30` | Force output framerate (prevents frame duplication) |
| `-g 120` | Keyframe every 120 frames (= segment duration x fps) |
| `-keyint_min 120` | Enforce strict keyframe interval |
| `-sc_threshold 0` | No scene-change keyframes |
| `-pix_fmt yuv420p` | Convert to browser-compatible pixel format |
| `-c:a aac` |	AAC audio encoder |  
| `-b:a 128k` |	Target audio bitrate |  
| `-ac 2` |	Stereo audio channels | 
| `-an` |	Disable audio entirely (fallback if no mic configured) |
| `-f dash` | Output DASH format |
| `-seg_duration 4` | 4-second segments |
| `-streaming 1 -ldash 1` | Live streaming mode |
| `-window_size 5` | Keep last 5 segments in manifest |
| `-extra_window_size 10` | Keep 10 extra segments on disk for rewinding |

### Output Files of DASH
- `stream.mpd` - DASH manifest 
- `init-stream0.m4s` - Initialization segment for the video track
- `chunk-stream0-XXXXX.m4s` - Video data segments
- `init-stream1.m4s` - Initialization segment for the audio track
- `chunk-stream1-XXXXX.m4s` - Audio data segments

### NGINX Configuration
- File: server/nginx/conf/nginx.conf on port 9090
- MIME types for .mpd (application/dash+xml) and .m4s (video/iso.segment)
- CORS headers (Access-Control-Allow-Origin) to allow browser requests
- No-cache on .mpd to ensure browser gets fresh manifest

### Client Architecture & Custom Player UI
- The client uses HTML5 Media Source Extensions and dash.js to create a custom streaming interface.
  - DASH APIs & Live Logic:

  - Throughput: Calculated using player.getAverageThroughput('video') to accurately measure network speed (handling 0ms local cache hits).

  - Latency: Tracked using player.getCurrentLiveLatency().

  - Live Jump: To bypass the engine's slow catch-up mechanism when clicking the "Live" button, the safe edge is dynamically calculated and enforced via vid.currentTime = vid.seekable.end() - player.getTargetLiveDelay().

- Audio Control (Mute/Volume):

  - Handled via standard HTML5 <video> APIs. The mute button toggles the vid.muted boolean, and the slider maps percentage inputs (0-100) to the vid.volume property (0.0 to 1.0).

  - Screenshot Tool:

  - Utilizes a hidden HTML5 <canvas> element. When triggered, ctx.drawImage(vid, ...) captures the current frame of the video element. The frame is then exported as a base64 JPEG using canvas.toDataURL() and automatically downloaded via a dynamic <a> tag.

  - Dynamic Thumbnails:

  - Instead of requesting separate images from the server, the client generates its own thumbnails every 10 seconds. It draws the current video frame to a small hidden <canvas>, saves the image data, and appends it to a scrollable flexbox row (thumb-row). Clicking a thumbnail extracts its timestamp and triggers a fast seek (vid.currentTime).

## 6. Latency Measurements
With 30FPS, 7000Kbps encoding
| Segment Duration | Measured Latency | Notes |
| 2 seconds        |  8 second        | Tested with dash.js reference player and host client |
| 4 seconds        |  16.1 seconds    | Tested with dash.js reference player and host client |
| 6 seconds        |  24.03 seconds   | Tested with dash.js reference player and host client |

### Integration Testing
- FFmpeg capture + NGINX serving + dash.js player (https://reference.dashif.org/dash.js/latest/samples/dash-if-reference-player/index.html) all working together with current configs
- Also host client tested
