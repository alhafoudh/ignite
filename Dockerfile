FROM ruby:3.1.2

RUN apt-get update -yq && apt-get install -y \
  build-essential \
  libpq-dev \
  postgresql-client \
  libglib2.0-0 \
  libglib2.0-dev \
  libpoppler-glib8 \
  libvips \
  libvips-dev \
  && apt-get clean \
  && apt-get autoclean \
  && apt-get install curl gnupg -yq \
  && curl -sL https://deb.nodesource.com/setup_16.x | bash \
  && apt-get install nodejs -yq \
  && gem install bundler \
  && npm install -g yarn \
  && echo -n "ruby: " && ruby -v \
  && echo -n "bundler: " && bundler -v \
  && echo -n "node: " && node -v \
  && echo -n "yarn: " && yarn -v


RUN mkdir -p /app
WORKDIR /app

ENV RAILS_ENV production
ENV NODE_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true

COPY Gemfile .
COPY Gemfile.lock .

RUN bundle config --global frozen 1

# https://github.com/sass/sassc-ruby/issues/146
RUN bundle config --global build.sassc --disable-march-tune-native \
  && bundle config build.libv8 --with-system-v8 \
  && bundle config build.nokogiri --use-system-libraries

RUN bundle config --local deployment true \
  && bundle config --local without "development test" \
  && bundle config --local path vendor \
  && bundle config --local jobs $(nproc) \
  && bundle install

# yarn install
COPY package.json .
COPY yarn.lock .

RUN yarn install --frozen-lockfile

COPY . .
RUN \
  bundle exec rails SECRET_KEY_BASE=secret DATABASE_URL=postgresql:does_not_exist assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
