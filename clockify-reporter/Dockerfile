FROM ruby

WORKDIR /usr/src/app

RUN gem install bundler
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["bundle", "exec", "./runner.rb"]
