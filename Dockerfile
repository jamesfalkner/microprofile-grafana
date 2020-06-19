FROM node:12

ENV JSONNET_BIN /usr/bin/jsonnet
ENV JSONNET_LIB /usr/lib/grafonnet-lib
ENV JSONNET_FILE /root/dashboards/microprofile.jsonnet


WORKDIR /root

RUN curl -L -o /tmp/jsonnet.tar.gz https://github.com/google/jsonnet/releases/download/v0.16.0/jsonnet-bin-v0.16.0-linux.tar.gz && cd /usr/bin && tar -xvzf /tmp/jsonnet.tar.gz && rm -rf /tmp/jsonnet.tar.gz

RUN git clone https://github.com/grafana/grafonnet-lib.git /usr/lib/grafonnet-lib

COPY package*.json ./

RUN npm install

COPY dashboards/ ./dashboards
COPY public/ ./public
COPY *.js ./

EXPOSE 8080

CMD [ "npm", "start" ]

