# Basic setup for new VMs to be able to access external resources

## The short bit

We offer a service at [http://10.253.254.250/](http://10.253.254.250/) which
serves a script with suggested configuration. When connected to a newly
deployed machine you can do the e.g. the below to configure it.

```bash

# Fetch the script
curl http://10.253.254.250/ > dspconfigscript
# Inspect and see that you don't disagree with any of the configurations
# being done
less dspconfigscript
# Run the configuration script if it's fine
bash dspconfigscript
```

## Intro

The DSP offers an outgoing proxy giving access to a limited set of resources,
but in order to use it some things need to be done in order to use it. Here we
go through the most important bits that entails.

### Certificates

To manage what outgoing connections should be allowed and not, the solution
needs to inspect outgoing traffic, and to do that, it needs to hijack outgoing
connections. To do that, we need clients to trust certificates we issue and thus
require clients to import a certificate authority root we provide.

#### Importing the CA

To trust a new CA, we put it under `/usr/local/share/ca-certificates/` in a file
with a prefix of `.crt` and run `update-ca-certificates` which makes the system
at large trust the certificate.

#### Using the CA for python virtual environments

Python typically doesn't use the system CA store but rather uses the
[certifi](https://pypi.org/project/certifi/) package to provide the CAs
(derived from those used in Mozilla).

```bash
REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
export REQUESTS_CA_BUNDLE
```

makes most of those packages use the system CA store instead.

### Using the proxy

Most tooling will look at the environment variables `http_proxy`, `https_proxy`
and `no_proxy` in various uppercase or lowercase combination. Unfortunately,
behaviour isn't uniform but mostly

```bash
http_proxy=https://10.253.254.250:3130/
https_proxy=https://10.253.254.250:3130/
export http_proxy
export https_proxy
```

will do the right thing.

#### Making docker use the proxy

Docker requires some special configuration to use the proxy. Providing

```text
[Service]
Environment="HTTP_PROXY=https://10.253.254.250:3130/"
Environment="HTTPS_PROXY=https://10.253.254.250:3130/"
Environment="no_proxy=192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,192.168.*,10.*,172.1*"
```

in `/etc/systemd/system/docker.service.d/http-proxy.conf`, reloading systemd
units with `sudo systemctl daemon-reload` and *restarting* docker with
`sudo systemctl restart docker`.

#### Making apt use the proxy

`apt` also needs some configuration to use the proxy, putting

```text
Acquire::http::Proxy "https://10.253.254.250:3130/";
```

in e.g. `/etc/apt/apt.conf.d/90proxy` will cause apt do use the proxy when
connecting to the outside world.
