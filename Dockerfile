FROM ruby:2.7

RUN bundle config --global frozen 1

RUN mkdir /blog
WORKDIR /blog
COPY . /blog

COPY Gemfile Gemfile.lock ./
RUN gem install bundler:1.16.2
RUN bundle install

# RUN apt-get update

# RUN apt-get install -y ruby-bundler
# RUN apt update -y
# RUN apt list --upgradable
# RUN apt install -y ruby-bundler



# RUN bundle add jekyll
# # RUN bundle exec jekyll new --force --skip-bundle .
# RUN bundle install

EXPOSE 4000

# CMD [ "bundler", "exec", "jekyll", "build", "&&", "bash", "-c", "'cd _site && python3 -m http.server --bind localhost 3000'"]

CMD [ "bundler", "exec", "jekyll", "serve"]