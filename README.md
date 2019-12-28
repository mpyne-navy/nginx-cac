# Introduction

This is the barest possible NGINX configuration and
[Docker](https://www.docker.com/) infrastructure I could create that would
enable developing a Web site that is protected using [client
TLS](https://en.wikipedia.org/wiki/Transport_Layer_Security#Client-authenticated_TLS_handshake)
using the [DoD public key infrastructure
(PKI)](https://public.cyber.mil/pki-pke/admins/).

In other words, you can build CAC-protected web sites using NGINX as the SSL
termination point, starting from this baseline.

# Building

You should be on Linux, with the normal command line toolchain (shell,
coreutils, etc.), along with curl, openssl and zip.

Of course, you'll need Docker installed as well to actually build the Docker
image and launch new containers.

To build, just run `make`.

This will:

* Download the base Docker image (alpine),
* Generate a new self-signed SSL cert,
* Download the [DoD root
  certs](https://public.cyber.mil/pki-pke/pkipke-document-library/?_dl_facet_pkipke_type=popular-dod-certs)
  and wrap them into a single file (to serve as the trusted set of certificates
  that can sign certificates presented by the CAC-holding client during TLS
  session negotiation),
* Install the new client CA and the new self-signed cert into the Docker image,
* Install nginx and a simple config into the Docker image, along with a sample
  index.html.

By default the new Docker image is called "nginx-cac".

# Launching

From there you can run it by using `make run`.

This will start a new container based on the image built, expose port 443
(inside the container) to a random port on the host.

Use `docker ps` to ensure the new container is actually running. If so, Docker
will tell you which port on the host corresponds to port 443 in the guest.

# Testing

In my case I had Firefox already configured to be able to authenticate against
CAC-enabled websites, using PCSC Lite, the CACKey middleware, and by installing
the DoD root certs **and intermediate CA certs** into the NSS keystore.

With "real" CAC sites already working, testing for me was a matter of going to
`https://localhost:$PORT/` (replacing `$PORT` with the actual port on the host
mapped to the guest's port 443).

I believe at this point it should already ask for the CAC PIN (as part of SSL
mutual auth) and then show an error page that the site is untrusted.

After confirming a security exception for the NGINX server's self-signed
certificate (I made it a temporary exception but permanent should work as
well), Firefox reloaded the page and this time you should see "It works!".

If you look into the Developer Tools you should also see that NGINX has sent
back your Subject Name information as a server response header.

## Windows Testing

I've also tested exporting the created Docker image (using
`docker save nginx-cac:latest | gzip > nginx-cac.tar.gz`
on the Linux host and using `docker load` on a Win10 machine to import the
image).

The container ran fine on Windows and I was also able to test with Firefox,
Chrome, and Microsoft Edge (with success on all 3).

As with Linux, you need to make sure you've setup your smartcard infrastructure
(in my case I used OpenSC with Firefox) and that you've installed the DoD root
and intermediate certificates into each browser.

# Shutdown

Don't forget to shutdown the Docker container when you're done (Use `docker ps`
to find the short name of the running container and then `docker stop
$short-name` from there).

# Why?????

Because doing this all within DoD is so much harder than doing it in my off
time. :(
