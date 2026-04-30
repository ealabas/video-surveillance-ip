## HTML5 Player (client/index.html)
- Single HTML5 + JavaScript file, no plugins used
- Uses dash.js via CDN for DASH manifest parsing and MSE buffer management

### Player Controls
- **Pause/Play** - toggles video playback
- **Rewind** - seeks back N seconds from current position; disables dash.js liveCatchup to prevent automatic snap-back to live
- **Jump to Live** - seeks to live edge, re-enables liveCatchup
- **Screenshot** - captures current frame via canvas, downloads as JPEG with timestamp watermark

### Bonus Features
- **Seek thumbnails** - captures frames every 15s and instantly on motion detection; grayed out when no longer in buffer; click to jump to that moment
- **Motion detection** - client-side pixel-diff algorithm on 160x90 downscaled canvas, configurable sensitivity slider, 10s cooldown between alerts, triggers instant thumbnail capture
- **Adaptive Quality UI** - Auto/Low/Med/High selection buttons
- **Stream Stats** - live bitrate (kbps), segment latency (ms), dropped frames counter
- **Latency Log** - logs per-segment fetch latency from dash.js FRAGMENT_LOADING_COMPLETED event
- **TV noise animation** - displayed before stream connects

### Known Issues / Implementation Notes
- dash.js liveCatchup causes automatic snap-back to live after seek; resolved by disabling it on rewind/seek and re-enabling on Jump to Live
- DVR window limited to ~60s at current server config (window_size=15, seg_duration=2s)
- Thumbnails older than the DVR window are grayed out and unclickable
- iOS not tested (DASH/MSE not supported on iOS Safari per project notes)
