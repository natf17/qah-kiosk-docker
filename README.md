# qah-kiosk-docker
Components:
- PostgreSQL database
- Strapi app
- Express app

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
5. Build the docker image from the Dockerfile:
```shell
docker build --build-arg DATABASE_URL=postgres://strapi_app:test@postgres-db:5432/strapi --build-arg MY_HEROKU_URL= -t strapi .
```
We set two build arguments: `DATABASE_URL` holds the postgres connection string, and `MY_HEROKU_URL` is set to the empty string. The image name will be `strapi`.

6. Run the container and attach to the network (use -it instead of -d to attach to the container):
```shell
docker run --name strapi-app --net=strapi_test -p 1337:1337 -d strapi
```