FROM ruby:3.2.0-slim

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      curl \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV BUNDLE_PATH=/usr/local/bundle

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
