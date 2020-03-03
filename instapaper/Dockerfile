FROM ruby

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle update --bundler
RUN bundle install

COPY lib ./
COPY . .

CMD ["bundle", "exec", "./runner.rb"]
