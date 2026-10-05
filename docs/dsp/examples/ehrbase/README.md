# Recipe: run EHRbase with Docker Compose on an AIDA DSP VM

This folder is a self-contained recipe for starting **your own EHRbase**
instance on a virtual machine in **AIDA DSP**.

The Compose file in this directory is taken from the upstream EHRbase project:

- [https://github.com/ehrbase/ehrbase](https://github.com/ehrbase/ehrbase)

Specifically, `docker-compose.yml` follows the
[upstream `docker-compose.yml`](https://github.com/ehrbase/ehrbase/blob/develop/docker-compose.yml)
(EHRbase server, PostgreSQL, and Keycloak). Application settings live in
`.env.ehrbase`, also based on the
[upstream `.env.ehrbase`](https://github.com/ehrbase/ehrbase/blob/develop/.env.ehrbase).

Official product documentation: [https://docs.ehrbase.org](https://docs.ehrbase.org)

---

## Components in the stack

Three containers share the Docker network `ehrbase-net`. EHRbase waits until
PostgreSQL is healthy and Keycloak has started before it comes up.

- **ehrbase** (`ehrbase/ehrbase:next`, host port `8080`): openEHR Clinical Data
  Repository (REST API, AQL, Swagger UI)
- **ehrdb** (`ehrbase/ehrbase-v2-postgres:16.2`, host port `5432`): PostgreSQL
  16, preconfigured with EHRbase roles and schema
- **keycloak** (`quay.io/keycloak/keycloak:24.0.3`, host port `8081`): Identity
  provider (OAuth2 / OpenID Connect), started in `start-dev` with realm import

### EHRbase (`ehrbase`)

EHRbase is an open source openEHR server. Applications talk to it over the
openEHR REST API (compositions, EHRs, templates, AQL queries). Configuration is
loaded from `.env.ehrbase` (node name, optional auth users, management
endpoints). Database connection is injected by Compose:

- JDBC URL: `jdbc:postgresql://ehrdb:5432/ehrbase`
- Admin role: `ehrbase` / `ehrbase`
- Restricted role: `ehrbase_restricted` / `ehrbase_restricted`

Default image tag is `next` (override with `EHRBASE_IMAGE` if you need a pinned
release).

### PostgreSQL (`ehrdb`)

The `ehrbase/ehrbase-v2-postgres` image is the vendor-prepared database for
EHRbase v2. On first start it creates the `ehrbase` database and the admin /
restricted users that the server expects. A health check (`pg_isready`) gates
EHRbase startup.

This service is **not** given a named volume in the upstream Compose file.
Removing the container (for example `docker compose down -v`) **deletes
clinical data**. Add a volume under `ehrdb` if you need persistence (see
[Persist database data](#persist-database-data)).

Do not publish `5432` beyond the VM unless you have a specific reason. Other
containers reach Postgres on the internal network as hostname `ehrdb`.

### Keycloak (`keycloak`)

Keycloak provides the OAuth2 realm that EHRbase can use when
`SECURITY_AUTHTYPE=OAUTH`. It listens on container port `8080` under path
`/auth`, mapped to host **8081**.

- Admin console: `http://<vm-host>:8081/auth`
- Default admin: `admin` / `admin`
- Default issuer URI used by EHRbase OAuth:
  `http://localhost:8081/auth/realms/ehrbase`

Keycloak is started with `start-dev --import-realm` and mounts
`./tests/keycloak/import` (realm JSON from the EHRbase test fixtures). That
path is relative to this `compose/` directory; you must copy the upstream
import files before the first start (step 3 below).

`start-dev` is for evaluation and development, not a hardened production IdP.

---

## Prerequisites

On your AIDA DSP VM:

1. A Linux VM you can SSH into, with enough RAM (4 GiB is a practical minimum;
   8 GiB is a good compromise).
2. [Docker Engine](https://docs.docker.com/engine/install/) and the
   [Compose plugin](https://docs.docker.com/compose/install/)
   (`docker compose version` should work).
3. Free host ports **8080** (EHRbase), **8081** (Keycloak), and **5432**
   (Postgres) unless you change the mappings.

---

## Recipe

### 1. Copy this folder onto the VM

Clone this repository and enter the directory:

```bash
cd docs/dsp/examples/ehrbase
```

All following commands are run from `compose/`.

### 2. Review credentials and settings

Edit `.env.ehrbase` before the first start if you will expose the API beyond
localhost. Defaults from upstream:

| Variable                     | Default                  |
| ---------------------------- | ------------------------ |
| `SERVER_NODENAME`            | `local.ehrbase.org`      |
| `SECURITY_AUTHUSER`          | `ehrbase-user`           |
| `SECURITY_AUTHPASSWORD`      | `SuperSecretPassword`    |
| `SECURITY_AUTHADMINUSER`     | `ehrbase-admin`          |
| `SECURITY_AUTHADMINPASSWORD` | `EvenMoreSecretPassword` |

Authentication is **off** unless you set `SECURITY_AUTHTYPE`. Typical choices:

- `SECURITY_AUTHTYPE=BASIC` — HTTP Basic Auth with the users above
- `SECURITY_AUTHTYPE=OAUTH` — JWT from Keycloak; also set
  `SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUERURI` to
  `http://localhost:8081/auth/realms/ehrbase`
  (use the VM hostname or a reverse-proxy URL if clients are not on the VM)

Database and Keycloak passwords are still the upstream defaults in
`docker-compose.yml`. Change them for any shared or long-lived VM.

### 3. Provide the Keycloak realm import [Optional]

Compose mounts `./tests/keycloak/import`. Fetch that directory from the
upstream repository (same source as the Compose file):

```bash
mkdir -p tests/keycloak
curl -fsSL -o /tmp/ehrbase-develop.tar.gz \
  https://github.com/ehrbase/ehrbase/archive/refs/heads/develop.tar.gz
tar -xzf /tmp/ehrbase-develop.tar.gz \
  --strip-components=3 \
  -C tests/keycloak \
  --wildcards 'ehrbase-develop/tests/keycloak/import/*'
rm /tmp/ehrbase-develop.tar.gz
ls tests/keycloak/import
```

Alternatively, clone [ehrbase/ehrbase](https://github.com/ehrbase/ehrbase) and
copy `tests/keycloak/import` into this folder so the path is
`compose/tests/keycloak/import`.

### 4. Start the stack

```bash
docker compose pull
docker compose up -d
docker compose ps
docker compose logs -f ehrbase
```

Wait until EHRbase logs show that the application has started (Spring Boot
“Started …” line). First start can take a few minutes while images are pulled
and the database is initialized.

### 5. Check that it is up

From the VM:

```bash
curl -sS -o /dev/null -w "%{http_code}\n" \
  http://localhost:8080/ehrbase/management/health
```

Useful URLs (replace `<vm-host>` with `localhost` on the VM, or the VM’s
hostname/IP from your laptop if ports are reachable):

- **openEHR REST** (context path `/ehrbase`):
  `http://<vm-host>:8080/ehrbase`
- **Swagger UI**:
  `http://<vm-host>:8080/ehrbase/swagger-ui/index.html`
- **Actuator health**:
  `http://<vm-host>:8080/ehrbase/management/health`
- **Keycloak**: `http://<vm-host>:8081/auth`

If Basic Auth is enabled, use `ehrbase-user` / `SuperSecretPassword` (or the
values you set).

### 6. Stop, restart, or tear down

```bash
docker compose stop          # keep containers and data
docker compose start         # start existing containers
# remove containers and network (anonymous volumes go away)
docker compose down
```

---

## Persist database data

The upstream Compose file does not declare a volume for Postgres. To keep EHRs
across `docker compose down`, add a volume on `ehrdb` in `docker-compose.yml`:

```yaml
volumes:
  - ehrdb-data:/var/lib/postgresql/data
```

and at the bottom of the file:

```yaml
volumes:
  ehrdb-data:
```

Then recreate the database service once: `docker compose up -d`.

---

## Pin image versions

Defaults can be overridden without editing YAML:

```bash
export EHRBASE_IMAGE=ehrbase/ehrbase:2.21.0
export EHRBASE_POSTGRES_IMAGE=ehrbase/ehrbase-v2-postgres:16.2
docker compose up -d
```

`ehrbase:next` tracks upstream development and may change without notice.
Prefer a release tag on a VM you intend to keep.
