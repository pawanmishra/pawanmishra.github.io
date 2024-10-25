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

Helpful links 

[so-simple-theme](https://talk.jekyllrb.com/t/page-build-fail-on-updated-so-simple-theme/3515/2)

#### Using Docker
---

Finally got docker based setup working. Follow the below steps -

* Install Docker desktop. On windows, for WSL to work, enable following settings - 
> Use the WSL 2 based engine (Windows Home can only run the WSL 2 backend) &&
> Add the *.docker.internal names to the host's etc/hosts file (Requires password)

* Once docker is installed and running, go to the repo, and execute the following commands -

```
-- This command creates the image
docker build -t pawan_blog_ruby .

-- This command runs the container
docker run --rm -p 4000:4000/tcp pawan_blog_ruby:latest
```

Output of successful container run should look like this -
```
Configuration file: /blog/_config.yml
            Source: /blog
       Destination: /blog/_site
 Incremental build: disabled. Enable with --incremental
      Generating...
      Remote Theme: Using theme mmistakes/so-simple-theme
       Jekyll Feed: Generating feed for posts
                    done in 2.649 seconds.
 Auto-regeneration: disabled. Use --watch to enable.
```

Finally, from host machine, enter either localhost:4000 or 127.0.0.1:4000 and there you have it.


