FROM ubuntu:18.04

LABEL io.k8s.description="Platform for serving Node JS apps in Shepherd" \
      io.k8s.display-name="Shepherd Node JS" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,shepherd,nodejs" \
      io.openshift.s2i.scripts-url="image:///usr/local/s2i"

ENV DEBIAN_FRONTEND noninteractive

ENV NODEJS_VERSION=8 \
    NPM_RUN=start \
    NAME=nodejs \
    NPM_CONFIG_PREFIX=$HOME/.npm-global \
    PATH=$HOME/node_modules/.bin/:$HOME/.npm-global/bin/:$PATH

# Configured timezone.
ENV TZ=Australia/Adelaide
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Ensure UTF-8.
ENV LANG       en_AU.UTF-8
ENV LC_ALL     en_AU.UTF-8

RUN apt-get update \
&& apt-get -y install locales \
&& locale-gen en_AU.UTF-8 \
&& apt-get -y dist-upgrade \
&& apt-get -y install build-essential curl openssh-client wget ssmtp git mysql-client \
&& apt-get -y autoremove && apt-get -y autoclean && apt-get clean && rm -rf /var/lib/apt/lists /tmp/* /var/tmp/*

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
&& apt-get -y install nodejs 

# Make bash the default shell.
RUN ln -sf /bin/bash /bin/sh

# Add /code /shared directories and ensure ownership by User 33 (www-data) and Group 0 (root).
RUN mkdir -p /code /shared /.npm-global

# Add s2i scripts.
COPY ./s2i/bin /usr/local/s2i
RUN chmod +x /usr/local/s2i/*
ENV PATH "$PATH:/usr/local/s2i:/code/bin"

EXPOSE 8080

WORKDIR /code

RUN chown -R 33:0 /code \
&& chown -R 33:0 /shared \ 
&& chown -R 33:0 /.npm-global 

RUN chmod -R g+rwX /code \ 
&& chmod -R g+rwX /shared \
&& chmod -R g+rwX /.npm-global 

RUN usermod -d /code www-data

USER 33:0

CMD ["/usr/local/s2i/run"]