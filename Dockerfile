FROM ruby:2.5
MAINTAINER Action Verb, LLC "https://github.com/Files-com"

ADD . /files-mock-server
RUN gem update --system \
  && cd files-mock-server \
  && bundle install

EXPOSE 4041
WORKDIR files-mock-server
ENTRYPOINT ["bundle", "exec", "puma"]
