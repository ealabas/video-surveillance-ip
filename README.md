# video-surveillance-ip
## Requirements
- Windows 10/11
- FFmpeg with libx264 and dshow support
- A webcam (built-in or USB)

Install FFmpeg

```powershell
winget install Gyan.FFmpeg
```

Verify with `ffmpeg -version`.

NGINX is already included in the repo, no installation needed.

## First Time Setup

### 1. Update NGINX paths

Open `server\nginx\conf\nginx.conf` and replace the two paths to match your project location.

### 2. Update camera name

Run this to find your webcam name:

```powershell
ffmpeg -list_devices true -f dshow -i dummy
```

Update `CAMERA_DEVICE` in `config/config.env` with your webcam name.

## How to Run

Open **two PowerShell terminals** in the project folder.

### Terminal 1 — Start NGINX

```powershell
cd server\nginx
start nginx
```

### Terminal 2 — Start FFmpeg capture

```powershell
.\server\start_capture.ps1
```
### Open the player

Open `client/index.html` in your browser.
Use the DASH URL `http://localhost:9090/dash_output/stream.mpd` in the player.

## How to Stop

- Press `q` in the FFmpeg terminal
- Stop NGINX:
```powershell
cd server\nginx
.\nginx.exe -s stop
```