## Environment Setup
- FFmpeg Version: 8.1-full_build-www.gyan.dev (gcc 15.2.0, MSYS2)
- Key FFmpeg features enabled: libx264, dshow, libopus, libmp3lame

## Camera Setup
- `ffmpeg -list_devices true -f dshow -i dummy` to find video devices
- `ffmpeg -f dshow -list_options true -i "video=YOUR_CAMERA"` to list supported modes
- Supported modes of my laptop:
  - MJPEG: 1280x720@30fps, 640x480@30fps, 640x360@30fps, 320x240@30fps
  - YUYV422: 1280x720@10fps, 640x480@30fps, 640x360@30fps, 320x240@30fps

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
- What it does: Captures webcam, encodes to H.264, outputs DASH segments
- Config file: config/config.env (all parameters configurable)
- Frame duplication (dup= in output) caused timing mismatch. Fixed by adding `-r 30` to force output framerate.
- Camera outputs yuyv422 which some browsers reject. Fixed with `-pix_fmt yuv420p`.
- TODO: Test with different segment durations (2, 4, and 6s)
- TODO: Measure latency for each segment duration

| Flag | Purpose |
|------|---------|
| `-f dshow` | Windows DirectShow camera input |
| `-pixel_format yuyv422` | Camera's raw format |
| `-video_size 640x480` | Capture resolution |
| `-framerate 30` | Capture framerate |
| `-c:v libx264` | H.264/AVC encoder (project requirement) |
| `-preset veryfast` | Fast encoding for real-time |
| `-tune zerolatency` | Minimize encoding delay |
| `-b:v 1500k` | Target bitrate |
| `-r 30` | Force output framerate (prevents frame duplication) |
| `-g 120` | Keyframe every 120 frames (= segment duration x fps) |
| `-keyint_min 120` | Enforce strict keyframe interval |
| `-sc_threshold 0` | No scene-change keyframes |
| `-pix_fmt yuv420p` | Convert to browser-compatible pixel format |
| `-f dash` | Output DASH format |
| `-seg_duration 4` | 4-second segments |
| `-streaming 1 -ldash 1` | Live streaming mode |
| `-window_size 5` | Keep last 5 segments in manifest |
| `-extra_window_size 10` | Keep 10 extra segments on disk for rewinding |

### Output Files
- `stream.mpd` - DASH manifest 
- `init-stream0.m4s` - Initialization segment 
- `chunk-stream0-XXXXX.m4s` - Other video segments 

### NGINX Configuration
- TODO

### Integration Testing
- TODO
