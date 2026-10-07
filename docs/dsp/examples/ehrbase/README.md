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


Do not publish `5432` beyond the VM unless you have a specific reason. Other
containers reach Postgres on the internal network as hostname `ehrdb`.

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

### 3. Start the stack

```bash
docker compose pull
docker compose up -d
docker compose ps
docker compose logs -f ehrbase
```

Wait until EHRbase logs show that the application has started (Spring Boot
“Started …” line). First start can take a few minutes while images are pulled
and the database is initialized.

### 4. Check that EHRbase is up

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

If Basic Auth is enabled, use `ehrbase-user` / `SuperSecretPassword` (or the
values you set).

### 5. Stop, restart, or tear down

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

---

## Serve EHRbase on a domain with TLS

EHRbase itself speaks HTTP on port `8080`. To serve it as
`https://your.domain/...`, terminate TLS in front of the stack with the
included nginx proxy and the certificate you already have.

On AIDA DSP, follow
[Exposing HTTPS services](../../getting-started/exposing-https-services.md)
first (domain, CNAME or namespaced name, floating IP, security group from
`10.253.254.248/29`, then the cert and key from support). This recipe uses
those files on the VM.

### 1. Place the certificate files

Copy the certificate chain and private key into `certs/` in this folder,
using these names:

```bash
cp /path/to/fullchain.pem certs/fullchain.pem
cp /path/to/privkey.pem   certs/privkey.pem
chmod 600 certs/privkey.pem
```

If your files have other names (for example `cert.crt` and `cert.key`), copy
or symlink them to `fullchain.pem` and `privkey.pem`. `fullchain.pem` must
include the leaf certificate and any intermediates.

### 2. Point EHRbase at the public hostname

In `.env.ehrbase`, set `SERVER_NODENAME` to the FQDN (not `local.ehrbase.org`).

### 3. Start the stack with the TLS proxy

```bash
docker compose --profile tls up -d
```

nginx listens on **443** (HTTPS) and redirects **80** to HTTPS. It proxies:

- `/ehrbase` → EHRbase (`8080`)

Public URLs:

- openEHR REST: `https://your.domain.example/ehrbase`
- Swagger UI: `https://your.domain.example/ehrbase/swagger-ui/index.html`
- Health: `https://your.domain.example/ehrbase/management/health`

On DSP, allow HTTPS (443) from `10.253.254.248/29` in the VM security group.
Do not publish Postgres (`5432`) on the floating IP.

Without `--profile tls`, the stack still runs on HTTP `8080` as in the
recipe above.
