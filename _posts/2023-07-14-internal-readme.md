---
layout: post
title: Test post
tags: [Scala]
date: 9999-12-31
excerpt: Internal readme post. Publish date set in future. To view this page run jekyll command with --future flag
---

{% include base_path %}
{% include toc %}

#### Command to run the site locally -

```
bundler exec jekyll build && bash -c 'cd _site && python3 -m http.server --bind localhost 3000'
```

Before bundler exec jekyll serve was enough but the latest version of Ruby(3.0+) isn't compatible with the jekyll version being used in this repo. Running just exec jekyll serve gives this error -

```
jekyll 3.9.0 | Error:  no implicit conversion of Hash into Integer
/var/lib/gems/3.0.0/gems/pathutil-0.16.2/lib/pathutil.rb:502:in `read': no implicit conversion of Hash into Integer (TypeError)
```

For more on this see this stackoverflow post - https://stackoverflow.com/questions/66113639/jekyll-serve-throws-no-implicit-conversion-of-hash-into-integer-error

So instead of downgrading Ruby to 2.7, started using the longer command. It works.

#### Commands to install ruby-bundler

```
sudo apt install ruby-bundler
sudo apt update
apt list --upgradable
sudo apt install ruby-bundler
```

Installing ruby-bundler should install ruby as well. By default it will install the latest version of ruby.