# download source code from github
FROM alpine as git
RUN apk add git
WORKDIR /repo
RUN git clone https://github.com/natf17/kiosk-prd-demo.git


FROM node:14-alpine as build
# update list of packages, add packages, redirect stdout to /dev/null(?), redirect fd2 (stderr) to fd1 (current stdout)
RUN apk update && apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev vips-dev > /dev/null 2>&1
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
ARG DATABASE_URL=postgres://someuser:somepassword@somehost:381/somedatabase
ENV DATABASE_URL=${DATABASE_URL}
ARG MY_HEROKU_URL=127.0.0.1
ENV MY_HEROKU_URL=${MY_HEROKU_URL}
WORKDIR /opt
COPY --from=git /repo/kiosk-prd-demo/package.json ./
ENV PATH /opt/node_modules/.bin:$PATH
RUN npm install --production
COPY --from=git /repo/kiosk-prd-demo/ ./
RUN ls
RUN npm run build

FROM node:16-alpine
# Installing libvips-dev for sharp Compatibility
RUN apk add vips-dev
RUN rm -rf /var/cache/apk/*
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
ARG DATABASE_URL=postgres://someuser:somepassword@somehost:381/somedatabase
ENV DATABASE_URL=${DATABASE_URL}
ARG MY_HEROKU_URL=127.0.0.1
ENV MY_HEROKU_URL=${MY_HEROKU_URL}
WORKDIR /opt/app
COPY --from=build /opt/node_modules ./node_modules/
ENV PATH /opt/node_modules/.bin:$PATH
COPY --from=build /opt/ ./
EXPOSE 1337
CMD ["npm", "run","start"]
