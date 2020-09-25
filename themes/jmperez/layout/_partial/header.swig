<header class="main-header">
    <nav id="menu">
        <a href="/"{% if is_current('index.html') %} aria-current="page"{% endif %}>Blog</a>
        <a href="#"{% if is_current('projects/') %} aria-current="page"{% endif %}>Projects</a>
        <a href="#"{% if is_current('about-me/') %} aria-current="page"{% endif %}>About</a>
    </nav>
</header>
