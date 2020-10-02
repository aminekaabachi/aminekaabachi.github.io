<header>
<script type="application/ld+json">
{
  "@context": "http://schema.org",
  "@type": "BlogPosting",
  "headline": "{{ page.title }}",
  {% if page.description %}
  "description": "{{ strip_html(page.description) }}",
  {% elseif page.excerpt %}
  "description": "{{ strip_html(page.excerpt) }}",
  {% endif %}
  "mainEntityOfPage":{
      "@type":"WebPage",
      "@id":"{{ config.url }}/{{ page.path }}"
  },
  "datePublished": "{{ page.date.toISOString() }}",
  "dateModified": "{{ page.updated.toISOString() }}",
  {% if page.image %}
  "image": {
    "@type": "ImageObject",
    "url": "{{ config.url }}{{ page.image.url }}",
    "width" : "{{ page.image.width }}",
    "height" : "{{ page.image.height }}"
  },
  {% endif %}
  "author": {
      "@type": "Person",
      "name": "{{ config.author }}",
      "url": "https://kaabachi.io",
      "sameAs": [
        "http://www.linkedin.com/in/aminekaabachi",
      ]
  },
  "publisher": {
      "@type": "Organization",
      "name": "{{ config.title }}"
      {% if config.generator_amp.logo.height && config.generator_amp.logo.width && config.generator_amp.logo.height %}
      ,
      "logo": {
        "@type": "ImageObject",
        "url": "{{ config.url }}/assets/images/logo.png",
        "width": {{ config.generator_amp.logo.width }},
        "height": {{ config.generator_amp.logo.height }}
      }
      {% endif %}
  }
}
</script>

  <div class="media author">
    <div class="img">
      <a href="#">
        <img src="https://avatars0.githubusercontent.com/u/1732576?s=460&u=c7f050fcc3501a22aac1e1b6ac998cdf3ce6f9b1&v=4" class="avatar-img" alt="" height="53" width="53" sizes="53px">
      </a>
    </div>
    <div class="bd">
      <address class="name" itemprop="author" itemscope itemtype="https://schema.org/Person"><a href="#" itemprop="name">Amine Kaabachi</a></address>
      <meta class="post-data" itemprop="datePublished" content="{{ page.date.toISOString() }}">
          {{ date(page.date, 'MMMM D, YYYY') }}
      </meta><span style="margin:0 .5rem;display:inline-block">|</span> Reading Time: ~<time>{{ readingTime(page.content, 'mins', 200) }}</time>
    </div>
  </div>
  {% if page.url %}
  <a href="{{ page.url }}">
    <h1>{{ page.title }}</h1>
  </a>
  {% else %}
  <h1>{{ page.title }}</h1>
  {% endif %}
</header>
