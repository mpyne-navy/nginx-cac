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

# See https://iase.disa.mil/pki-pke/getting_started/Pages/administrators.aspx for instructions
# on how to obtain DoD PKI certs -- which are *not* CAC-firewalled. The ZIP file they link you to
# includes the raw DoD Root certs in various formats. This Makefile just picks out the 3 current
# root certs and concatenates them into a single file. Worked for me as of 2018-06-09
#
# unzip -p is used to dump directly to stdout, tr -d converts text to Unix format
ROOT_CERTS := Certificates_PKCS7_v5.0u1_DoD
DoDRoots.crt: $(ROOT_CERTS).zip
	unzip -p "$<" '$(ROOT_CERTS)/DoD_Root_CA_[234]*.cer' | tr -d '\15\32' > "$@"

# ***NOTE*** the DISA IASE website appears to use http instead of https for the
# link to the ZIP file so if you care about security (and you should), make
# sure to manually turn it back into an HTTPS link.
#
# As of 2018-06-09 this worked
# https://iasecontent.disa.mil/pki-pke/Certificates_PKCS7_v5.0u1_DoD.zip
$(ROOT_CERTS).zip:
	curl -s -o "$@" "https://iasecontent.disa.mil/pki-pke/$@"
