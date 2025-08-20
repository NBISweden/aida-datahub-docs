# Exposing HTTPS services in DSP to the outside

## Introduction

There are use cases where you might want to expose services running in DSP to
the outside world. This can be e.g. offering an interactive data explorer or
accepting input data for processing and then publishing a report.

This guide details services exposed via HTTPS. Other services may be possible
to expose but that will involve another, more involved process.

## Steps

* allocate a domain name for the service you want to expose
  * wildcard names are not supported
* point the allocated name to DSP
  * the recommended way to do this is to use a `CNAME` to
    `dsp.aida.scilifelab.se`, but it's also possible through other means
    (details subject to change for now, contact support)
  * DSP will need to request a certificate for the appointed name, this will
    be done through Let's Encrypt
    * for DSP to be able to do this, there can't be any restrictions denying
      that (e.g `CAA` DNS records)
* we also support using namespaced names, e.g.
  `myservice.myproject.dsp.aida.scilifelab.se`
* decide on one or more floating IP addresses that will be mapped ("associated")
  to the VM(s) providing the service
  * any special handling beyond basic up/down detection is currently not
    supported (e.g. session handling is not provided)
  * you will need to have the services exposed so that they are reachable from
    10.253.254.248/29, i.e. at least one security group allowing the desired
    traffic must be added to the instance or the corresponding port
* contact support with the allocated/desired domain name and the chosen
  floating IP address(es)
  * you will receive keys and certificates to use for TLS

## Considerations

Once done, this will expose your service to the internet at large. It may be
appropriate to take precautions, e.g. investigate if the exposed service can
be isolated from other things in your secure environment.
