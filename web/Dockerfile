FROM ruby:4.0-slim

RUN apt-get update && apt-get install -y build-essential libsqlite3-dev libyaml-dev && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN SECRET_KEY_BASE=placeholder rails db:prepare

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
