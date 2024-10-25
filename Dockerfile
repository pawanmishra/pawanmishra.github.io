FROM ruby:2.7

# RUN bundle config --global frozen 1

RUN mkdir /blog
WORKDIR /blog
COPY . /blog

COPY Gemfile Gemfile.lock ./
RUN gem install bundler:1.16.2
RUN bundle install
RUN ["chmod", "+x", "startup.sh"]

EXPOSE 4000

# ENTRYPOINT [ "bundler", "exec", "jekyll", "build"]
# ENTRYPOINT [ "bundler", "exec", "jekyll", "build", "&&", "/bin/bash", "-c", "'cd _site && python3 -m http.server --bind localhost 4000'"]

ENTRYPOINT [ "./startup.sh" ]