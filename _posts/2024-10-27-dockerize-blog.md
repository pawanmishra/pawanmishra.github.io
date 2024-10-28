---
layout: post
title: Dockerizing my blog
tags: [Docker]
excerpt: I have never worked with Docker. I have never created a Dockerfile, containerized an app, run it as a service, or interacted with it. I did take some courses on O'Reilly, but without active practice, I forgot what I had learned in those courses. Finally, I decided to build something with Docker, and I did that by dockerizing my blog.
---

##### Why Dockerize?
I've maintained this blog for almost a decade now. While writing has been infrequent, I've ensured the blog is up and running.  The blog is currently hosted on GitHub and uses GitHub Pages. To give it a decent look and feel, I've integrated the [minimal-mistakes-so-simple-theme](https://github.com/mmistakes/so-simple-theme). The site is rendered via Jekyll, a static site generator, and the theme is implemented as a Ruby gem.

+ **Github Pages** - GitHub Pages is a feature of GitHub that allows users to host static websites on GitHub's servers and make them available to the public.
+ **Jekyll** - Jekyll is a static site generator that creates websites from Markdown, HTML, and other markup languages.
+ **Ruby Gem** - Ruby gems are packages of code, documentation, and other components that can be used to extend or modify Ruby applications.
+ **Gemfile** - A gemfile is a file that lists gems and their versions required by the Ruby application.
+ **Gemfile.lock** - A Gemfile.lock is a file that records the exact versions of gems that were installed for a Ruby project. It is created automatically by the bundler when you run `bundle install`.
+ **Bundler** - Bundler is a took that helps manage dependencies for Ruby application by installing and tracking Gems.

As we can see, there are quite a lot of components involved in running a blog. Now, I'm not a Ruby developer, so every time I switched machines and tried to get the blog running locally, I would run into all sorts of issues: bundler-related errors, gem incompatibilities, weird Ruby-related errors, etc.

Dockerizing my blog would help me by eliminating the need to remember the steps, configurations, binaries, etc., required to run my blog. I can easily switch machines, clone the repo, create and run the Docker image, and have the blog up and running in a few minutes.

##### Current Setup

I have a windows machine. Blog's code is cloned inside wsl. Assuming Ruby and all other dependencies are installed correctly, the command to build and serve the site is - 

```bash
bundler exec jekyll build && bash -c 'cd _site && python3 -m http.server --bind localhost 4000'
```

- `bundler exec jekyll build` - it builds the site, generates the static HLTML content, and writes it to a temp directory called `_site`
- `cd _site && python3 http.server localhost 4000` - starts a basic webserver from within the `_site_` directory. Once the server is up, we can access the content by going to `http://localhost:4000`

##### Docker Based Setup
Before we can run the blog as a container within Docker, we need to install Docker itself. On windows, I used the Docker desktop installer. While Docker is installed on Windows, it has the option of enabling WSL connectivity, such that it can manage running containers within WSL as well. This option is enabled by default.

Once I had Docker installed and running, I created the Dockerfile within the blog's codebase. 

```Dockerfile
FROM ruby:2.7

RUN mkdir /blog
WORKDIR /blog
COPY . /blog

COPY Gemfile Gemfile.lock ./
RUN gem install bundler:1.16.2
RUN bundle install
RUN ["chmod", "+x", "startup.sh"]

EXPOSE 4000

ENTRYPOINT [ "./startup.sh" ]
```

- Using Ruby based base image makes sense, after all, blog's theme and features are implemented as Ruby gems. Having the ability to specify which version of Ruby image I want made things so much better. The gems the site needs, require an older version of Ruby and thus I hard-code a speicific version.
- Next, created a new directory called `blog` inside the docker container and copied all of blogs content in it. Setting it as WORKDIR, ensures that all subsequent commands will get executed from within this directory.
- Gemfile and Gemfile.lock files contains all of the required gems and their dependnecies. Running `bundle install`, installs all of the required gems.
- Next, the repo contains a bash script called `startp.sh`. It contains the command we saw before - `bundler exec jekyll build && bash -c 'cd _site && python3 -m http.server --bind localhost 4000'`. Having this command in a bash script makes it easy to invoke it via `ENTRYPOINT` command. Else we would have to pass the entre command in json arry parameter format. 
- Next, expose the port 4000. We would still have to provide the `-p` flag and define the port mapping in the `docker run` command.
- Set `ENTRYPOINT` command to execute the `startup.sh` script.

To build the image, run the following command -

```bash
docker build -t pawan_blog_ruby .
```

`-t` flag assigns a tag name to the image. Running this command, downloads the base image, executes all the steps sequentially, and if everything goes well then ends up creating an image. We can see the details of the create image either in Docker desktop or via `docker` commands.

Once the image is ready then execute the following command to start the container - 

```bash
docker run --rm -p 4000:4000/tcp pawan_blog_ruby:latest
```

This command starts the container. Essentially, it executes the `startup.sh` script specified in the `ENTRYPOINT` command. Once the container is up & running, I was able to access the site in my local by going to `http://localhost:4000`.

##### Learning

The effort to setup Docker, define the Dockerfile was not that challenging. In a couple of hours and few hit & trial, I was able to get the bundler & other commands working and had the image ready. I also managed to get the container running, without throwing any exception. However, the most time consuming part was that I was unable to figure out why from my local machine, I was unable to connect to the server running within the docker container. `localhost:4000` or `127.0.0.1:4000` failed with connection reset error. 

Just to isolate the problem, I tried a couple of things.

- Ran the `bundler exec jekyll build && bash -c 'cd _site && python3 -m http.server --bind localhost 4000'` in wsl. No docker. The site got built and I was able to access the site from my local machine by going to `localhost:4000`. This ensured that the command itself is correct.
- Next, ran the same command via `ENTRYPOINT` and then from within the running container, issues the following curl command - `curl localhost:4000`. This worked as well. I got the HTML text response. But accessing localhost:4000 from browser in machine failed with `connection reset error`. This isolated the problem. Something was preventing connectivity between my local machine and the server running inside the container.
- Solution, finally, I found the solution in one of stackoverflow post answer. It suggested to change the `python3 -m http.server --bind localhost 4000` command and instead of `localhost`, set it to `0.0.0.0`. With localhost, one can access the server from inside the container but by setting it to 0.0.0.0, we are making the server accessible fromlocal and external network. With this change, I was able to access the site from my machine.