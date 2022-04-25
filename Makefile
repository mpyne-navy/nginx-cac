.PHONY: all run cert clean

all: cert DoDRoots.crt
	docker build -t nginx-cac:latest .

run:
	docker run -d -P nginx-cac:latest

# Generate a self-signed certificate for the NGINX server side
# Since I want it to use EC we have to generate the privkey separately
cert: certificate.pem
	
certificate.pem: key.pem
	openssl req -batch -sha256 -days 365             \
	    -new -x509 -key key.pem -out certificate.pem \
	    -subj "/C=US/ST=Vulcan/O=DemoClientSSL/CN=localhost"

key.pem:
	openssl ecparam -genkey -name prime256v1 -out key.pem

clean:
	@rm -f key.pem certificate.pem

# See https://public.cyber.mil/pki-pke/pkipke-document-library/?_dl_facet_pkipke_type=popular-dod-certs
# for instructions on how to obtain DoD PKI certs -- which are *not*
# CAC-firewalled. The ZIP file they link you to includes the raw DoD Root certs
# in various formats.

# File name format *inside* the ZIP file
ROOT_CERTS := Certificates_PKCS7_v5.9_DoD

# Format of the ZIP file name itself
ROOT_CERTS_FILE_NAME := certificates_pkcs7_DoD
#ROOT_CERTS_FILE_NAME := $(shell echo $(ROOT_CERTS) | tr A-Z. a-z- )

# Current versions of the DoD PKI distro contain all the certs in a pkcs7 bundle,
# which NGINX doesn't handle natively, but is not too difficult to have openssl
# convert into a bunch of concatenated individual PEM-format certs.
# unzip -p is used to dump directly to stdout
DoDRoots.crt: $(ROOT_CERTS_FILE_NAME).zip
	unzip -p "$<" '$(ROOT_CERTS)/$(ROOT_CERTS).pem.p7b' | openssl pkcs7 -out "$@" -print_certs

# As of 2019-06-27 this worked
$(ROOT_CERTS_FILE_NAME).zip:
	curl -s -o "$@" "https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/$@"
