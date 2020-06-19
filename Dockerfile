FROM node:12

WORKDIR /opt/app

ENV JSONNET_BIN ./jsonnet
ENV JSONNET_LIB ./grafonnet-lib
ENV JSONNET_FILE ./dashboards/microprofile.jsonnet

RUN curl -L -o /tmp/jsonnet.tar.gz https://github.com/google/jsonnet/releases/download/v0.16.0/jsonnet-bin-v0.16.0-linux.tar.gz && tar -xvzf /tmp/jsonnet.tar.gz && rm -f /tmp/jsonnet.tar.gz

RUN git clone https://github.com/grafana/grafonnet-lib.git

COPY package*.json ./

RUN npm install

COPY dashboards/ ./dashboards
COPY public/ ./public
COPY *.js ./

EXPOSE 8080

CMD [ "npm", "start" ]

