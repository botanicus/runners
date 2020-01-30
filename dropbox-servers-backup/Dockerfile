FROM ruby

WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y --no-install-recommends rsync && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN bundle update --bundler
RUN bundle install

COPY . .

CMD ["bundle", "exec", "./runner.rb"]
