{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    // Render inside #flutter-host (kept inside the iOS safe area by CSS in
    // index.html) instead of taking over the whole <body>.
    hostElement: document.getElementById('flutter-host'),
    // Load the CanvasKit renderer from this site instead of www.gstatic.com,
    // so the app also starts offline and without third-party requests.
    canvasKitBaseUrl: 'canvaskit/',
  },
  // Flutter's own service worker is deprecated (and only unregisters itself);
  // offline caching is handled by quran_sw.js instead.
});
