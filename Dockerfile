FROM ubuntu:18.04
MAINTAINER Action Verb, LLC "https://www.files.com/"

# Update Apt and install dependencies
RUN export DEBIAN_FRONTEND=noninteractive \
  && apt-get update \
  && apt-get -o Dpkg::Options::="--force-confnew" install -q -y build-essential curl git \
  && apt-get -o Dpkg::Options::="--force-confnew" install -q -y zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev wget sudo

# Create User
RUN addgroup --group --gid 1003  docker \
  && adduser --uid 1002 --gid 1003 --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password docker \
  && echo "docker ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/docker \
  && chmod 0440 /etc/sudoers.d/docker

USER docker
WORKDIR /home/docker
ENV USER docker
ENV HOME /home/docker
ENV PATH ${HOME}/.rbenv/bin:$HOME/.rbenv/shims:${PATH}
ENV RBENV ${HOME}/.rbenv

# Install rbenv
RUN wget -O - https://github.com/rbenv/rbenv/archive/master.tar.gz | tar zxf - \
     && mkdir -p $HOME && mv rbenv-master $HOME/.rbenv \
     && wget -O - https://github.com/rbenv/ruby-build/archive/master.tar.gz | tar zxf - \
     && mkdir -p $HOME/.rbenv/plugins \
     && mv ruby-build-master $HOME/.rbenv/plugins/ruby-build \
     && echo 'eval "$(rbenv init -)"' >> $HOME/.profile \
     && echo 'eval "$(rbenv init -)"' >> $HOME/.bashrc \
     && rbenv install 2.5.1 \
     && rbenv global 2.5.1 \
     && gem update --system

ADD . /home/docker/mock-server
RUN sudo chown -R docker /home/docker \
  && cd mock-server \
  && bundle install

EXPOSE 4041
WORKDIR files-mock-server
ENTRYPOINT ["bundle", "exec", "puma"]
