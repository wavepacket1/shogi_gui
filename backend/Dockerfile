FROM ruby:3.2.7

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client graphviz

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN gem install bundler && bundle install

COPY . .

EXPOSE 3000