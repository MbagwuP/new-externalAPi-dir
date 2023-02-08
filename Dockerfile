FROM ruby:2.1.7

RUN gem install bundler -v 1.17.3

RUN apt-get clean && apt-get update && apt-get install -y --force-yes locales

# Set the locale
RUN locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Newer versions of Ruby use the above environment variables for the encoding, but this version needs explicit option setting
ENV RUBYOPT='-E utf-8'

WORKDIR /external_api

COPY . ./

RUN bundle check || bundle install

EXPOSE 4567
# Debugging ports
EXPOSE 1234
EXPOSE 26162