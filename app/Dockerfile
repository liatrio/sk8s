FROM debian:buster
LABEL maintainer="Andrei Titerlea (andrei.titerlea@gmail.com)"

ENV DEBIAN_FRONTEND=noninteractive INITRD=no TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y locales python3-dev python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen "en_US.UTF-8"
ENV LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8

COPY build/ /app/
RUN pip3 install -r /app/requirements.txt

ENTRYPOINT ["/app/entrypoint.sh"]
