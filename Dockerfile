FROM ruby:2.4-alpine

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile /app
COPY Gemfile.lock /app

RUN bundle install

COPY . /app

CMD ["/app/loggly-host-metrics-datadog-collector.rb"]
