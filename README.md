# qah-kiosk-docker
Components:
- PostgreSQL database
- [Strapi app](https://github.com/natf17/kiosk-prd-demo)
- [NextJS app](https://github.com/natf17/nextjs-demo)

After cloning this git repository, `cd` into the project folder, and follow the steps outlined below.

## Network setup
1. Create network (here named `strapi_test`):
```shell
docker network create strapi_test
```

## PostgreSQL setup
2. Create an environment file with the following environment variables for the database:
```
# ./env_list

POSTGRES_PASSWORD=
POSTGRES_USER=
POSTGRES_DB=
```

3. Start a PostgreSQL container and attach to the network:
```shell
docker run --name postgres-db --env-file ./env_list --net=strapi_test -p 5432:5432 -d postgres
```
The command above starts a container, names it `postgres-db`, adds `./env_list` as the environment file, attaches the container port 5432 to host port 5432, runs the container in detached mode, and uses the `postgres` image.

4. (Optional) Test the PostgreSQL container:

- Check that the port on the host is open and attached to the container:
```shell
lsof -i :5432
```

- Connect to the database container's CLI:
```shell
docker exec -it postgres-db bash
```

- Inspect the database's configuration files:
```shell
cat /var/lib/postgresql/data/pg_hba.conf
cat /var/lib/postgresql/data/postgresql.conf
cat /usr/local/bin/docker-entrypoint.sh
```

- See the `postgres` system user that was created by the Dockerfile:
```shell
cat etc/passwd
```
Note that the Dockerfile used to build the image contains an entrypoint script that sets up the database by calling `initdb` using the `postgres` system user, passing in the custom username to set it as the superuser of the database and to create the first user account. The database cluster gets initialized via a call using `CREATE DATABASE` (instead of the `createdb` shortcut).

- Connect to the database:
```shell
psql --username=strapi_app --dbname=strapi
```

- Check available commands:
```shell
\?
```

## Strapi setup
5. After obtaining the `CLOUDINARY_NAME`, `CLOUDINARY_KEY`, and `CLOUDINARY_SECRET` from the cloudinary dashboard, build the docker image from the Dockerfile:
```shell
docker build --build-arg DATABASE_URL=postgres://strapi_app:test@postgres-db:5432/strapi \
             --build-arg MY_HEROKU_URL= \
             --build-arg CLOUDINARY_NAME={enter cloudinary name} \
             --build-arg CLOUDINARY_KEY={enter cloudinary key} \
             --build-arg CLOUDINARY_SECRET={} \
             -t strapi .
```
We set two build arguments: `DATABASE_URL` holds the postgres connection string, and `MY_HEROKU_URL` is set to the empty string. The image name will be `strapi`.

6. Run the container and attach to the network (use -it instead of -d to attach to the container):
```shell
docker run --name strapi-app --net=strapi_test -p 1337:1337 -d strapi
```
Note: to see requests received by the app, run `docker attach strapi-app`.

7. Set up the CMS (follow the [setup instructions](https://github.com/natf17/qah-kiosk-docker/blob/main/setup-instructions.txt) for details).
The admin panel is found at `http://localhost:1337`.

## Next.js setup
8. `cd` into the `next` folder.

9. Create an environment file with the following environment variables for the next.js app:
```
#./.env.local:
# ### CMS ### #
# Used for GraphQL queries
CMS_GRAPHQL_ENDPOINT=http://host.docker.internal:1337/graphql

# In production, CMS API token should be stored here:#
## CMS_ACCESS_TOKEN=

# ### Images ### #
# Used in next.config.js to allow images to be loaded from this domain
IMG_DOMAIN=res.cloudinary.com

# Used as base url for images; should be empty in production
NEXT_PUBLIC_VERCEL_IMG_API=

```
10. Build the docker image from the Dockerfile: (add production variable?)
```shell
docker build -t kiosk-app .
```

11. Run the container and attach to the network (use -it instead of -d to attach to the container):
```shell
docker run --name next-app -p 3000:3000 -d kiosk-app
```

## Add the first events!
12. Follow the instructions [here](https://github.com/natf17/qah-kiosk-docker/blob/main/adding-events-instructions.txt) to add the first events to the kiosk.

13. Follow steps 9 and 10 to rebuild and rerun the NextJS app. Make sure to update the Dockerfile `ARG CACHEBUST` to force Docker to bypass the cache and rebuild the pages. (This is a current limitation).

14. Open the app (from the host machine) here: `localhost:3000`.

