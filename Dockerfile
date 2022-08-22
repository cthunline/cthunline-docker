########################################### clone repositories + run builds

FROM node:16-alpine AS builder

# install git
RUN apk add --update git

# clone repositories
RUN git clone https://github.com/cthunline/cthunline-api.git api
RUN git clone https://github.com/cthunline/cthunline-web.git web

# woking on api
WORKDIR /api
# install dependencies
RUN npm i
# build app
RUN npm run build

# woking on web client
WORKDIR /web
# install dependencies
RUN npm i
# build app
RUN npm run build

########################################### final image with api + web client

FROM node:16-alpine

# work dir
WORKDIR /app

# copy api build and dependencies
COPY --from=builder /api/build .
COPY --from=builder /api/package.json ./package.json
# copy prisma data
COPY --from=builder /api/src/prisma ./prisma
# install prod dependencies
RUN npm i --only=prod
# generate prisma client
RUN npx prisma generate --schema prisma/schema.prisma

# create logs and assets directories
RUN mkdir -p /data/logs
RUN mkdir -p /data/assets

# create web client directory
RUN mkdir web

# copy web client build
COPY --from=builder /web/build ./web

# entry point
ENTRYPOINT ["npm", "run", "prod"]
