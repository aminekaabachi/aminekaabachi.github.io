<!doctype html>
<html lang="{{page.language or 'en'}}">
<head>
  <meta charset="utf-8">
  <meta http-equiv="x-ua-compatible" content="ie=edge">
  <meta http-equiv="Accept-CH" content="DPR, Viewport-Width, Width">
  {% set title = page.title or "DataOps Consultant and Azure Wizard" %}
  <title>{{ title }} - Amine Kaabachi</title>
  <link rel="dns-prefetch" href="//res.cloudinary.com" />
  <link rel="dns-prefetch" href="//www.google-analytics.com" />
  {% if page.description or config.description %}<meta name="description" content="{{ page.description or config.description }}">{% endif %}
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <link rel="alternate" type="application/rss+xml" title="Amine Kaabachi" href="https://kaabachi.io/feed.xml">
  <meta name="twitter:card" content="{% if page.image %}summary_large_image{% else %}summary{% endif %}">
  <meta name="twitter:url" content="{{ page_url(config.url + '/' + page.path) }}" property="og:url">
  <meta name="twitter:title" content="{{ title }}" property="og:title">
  {% if page.description %}<meta name="twitter:description" content="{{ page.description }}" property="og:description">{% endif %}
  {% if page.image %}
  <meta property="og:image" content="{{ page_url(config.url + page.image.url) }}">
  <meta name="twitter:image" content="{{ page_url(config.url + page.image.url) }}">
  {% else %}
  {% endif %}
  <link rel="canonical" href="{{ page_url(config.url + '/' + page.path) }}" />
  {{ inline_css('css/main') }}
  {% if (is_post() && config.generator_amp) %}
  <link rel="amphtml" href="{{ url_for(page.path + 'amp/') }}">
  {% endif %}
  <meta name="theme-color" content="#005689">
  <link rel="manifest" href="/manifest.json">
  {% for url in page.i18n %}
    <link rel="alternate" hreflang="{{ loop.key }}" href="{{ url_for(url + '/') }}" />
  {% endfor %}
</head>
<body>
  {{ partial('_partial/ga')}}
  {{ partial('_partial/header')}}
  <div id="page">
    {{ body }}
  </div>
  {{ partial('_partial/footer')}}
  <script>
   window.addEventListener('load', () => {
     setTimeout(() => {
      var t = window.performance && performance.timing;
      function round2(num) { return Math.round(num * 100) / 100; }
      if (t) {
        var timingStats = document.querySelector('.timing-stats');
        var loadTime = (t.loadEventEnd - t.navigationStart) / 1000;
        var timingStatsHTML = 'This page loaded in ' + round2(loadTime) + ' seconds. ';
        var performanceEntries = performance.getEntriesByType('paint');
        performanceEntries.forEach(function(performanceEntry, i, entries) {
          var name = performanceEntry.name;
          if (name === 'first-paint') {
            name = '<abbr title=' + name + '>FP</abbr>';
          } else if (name === 'first-contentful-paint') {
            name = '<abbr title=' + name + '>FCP</abbr>';
          }
          timingStatsHTML += name + ' was ' + round2(performanceEntry.startTime / 1000) + ' seconds. ';
        });
        timingStats.innerHTML = timingStatsHTML;
      }
    }, 0);
   });
  </script>
  <script src="/quicklink.js" async></script>
  <script src="https://unpkg.com/turbolinks@5.2.0/dist/turbolinks.js" async data-turbolinks-suppress-warning></script>
</body>
</html>
