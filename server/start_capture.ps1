# Load config
$configPath = Join-Path $PSScriptRoot "..\config\config.env"
if (-Not (Test-Path $configPath)) {
    Write-Error "Config file not found at: $configPath"
    exit 1
}

# Parse config.env into variables
Get-Content $configPath | ForEach-Object {
    $line = $_.Trim()
    
    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line -split "=", 2
        if ($parts.Length -eq 2) {
            Set-Variable -Name $parts[0].Trim() -Value $parts[1].Trim()
        }
    }
}

$projectRoot = (Get-Item $PSScriptRoot).Parent.FullName
$OUTPUT_DIR = Join-Path $projectRoot "server\dash_output"

if (-Not (Test-Path $OUTPUT_DIR)) {
    New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null
}

# Clean old segments
Remove-Item "$OUTPUT_DIR\*.m4s" -ErrorAction SilentlyContinue
Remove-Item "$OUTPUT_DIR\*.mpd" -ErrorAction SilentlyContinue

# Calculate keyframe interval
$GOP_SIZE = [int]$FRAMERATE * [int]$SEGMENT_DURATION

# Display settings
Write-Host "Starting video capture with the following settings:" -ForegroundColor Cyan
Write-Host "Camera:           $CAMERA_DEVICE"
Write-Host "Format:           $CAMERA_FORMAT"
Write-Host "Pixel Format:     $PIXEL_FORMAT"
Write-Host "Resolution:       $RESOLUTION"
Write-Host "Framerate:        $FRAMERATE fps"
Write-Host "Video Bitrate:    $VIDEO_BITRATE"
Write-Host "Segment Duration: $SEGMENT_DURATION seconds"
Write-Host "GOP Size:         $GOP_SIZE frames"
Write-Host "Output:           $OUTPUT_DIR\$MANIFEST_NAME"
Write-Host "Press 'q' in the FFmpeg window to stop" -ForegroundColor Yellow
Write-Host ""

# Parse resolution into width and height for FFmpeg
$originalDir = Get-Location
Set-Location $OUTPUT_DIR

# Build and run FFmpeg command
ffmpeg `
    -f $CAMERA_FORMAT `
    -pixel_format $PIXEL_FORMAT `
    -video_size $RESOLUTION `
    -framerate $FRAMERATE `
    -i "$CAMERA_DEVICE" `
    -c:v libx264 `
    -preset veryfast `
    -tune zerolatency `
    -b:v $VIDEO_BITRATE `
    -r $FRAMERATE `
    -g $GOP_SIZE `
    -keyint_min $GOP_SIZE `
    -sc_threshold 0 `
    -pix_fmt yuv420p `
    -f dash `
    -seg_duration $SEGMENT_DURATION `
    -use_timeline 1 `
    -use_template 1 `
    -window_size 5 `
    -extra_window_size 10 `
    -remove_at_exit 0 `
    -streaming 1 `
    -ldash 1 `
    "$OUTPUT_DIR\$MANIFEST_NAME"

Set-Location $originalDir