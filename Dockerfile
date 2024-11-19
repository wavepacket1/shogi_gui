FROM ruby:3.2.0
ENV APP /railsapp
ENV LANG C.UTF-8
ENV TZ Asia/Tokyo
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
RUN apt update -qq \
    && apt install -y build-essential mariadb-client nodejs graphviz imagemagick libmagickcore-dev libmagickwand-dev libmagic-dev libpq-dev\
    && npm install --global yarn
RUN yarn add @fortawesome/fontawesome-free @fortawesome/fontawesome-svg-core @fortawesome/free-brands-svg-icons @fortawesome/free-regular-svg-icons @fortawesome/free-solid-svg-icons
WORKDIR $APP
COPY Gemfile $APP/Gemfile
COPY Gemfile.lock $APP/Gemfile.lock
RUN bundle install