A short summary of key management. I limited the scope to the technical side of a single application or set of applications that need to communicate securely. Specifically avoiding key policy, procedures and such.

### Overview

Network encryption of https traffic is done with TLS[^1]. The server managing the security of the connection needs access to private and public TLS keys and a certificate issued by an Authority (CA). The certificate is a document by the Authority that guarantees the servers name and public key are authentic. The client starting the connection with the server can validate the certificate after which it uses the servers public key to setup the connection. Lastly the servers private key is used in decrypting communication from clients during the handshake. After the handhsake the connection is private, authenticated and tamper proof.
[^1]: [Wikipedia TLS][TLS]

Typically a client does not provide proof of authenticity. In a environment with applications communicating we can set up two side authentication. This is called mutual TLS(mTLS)[^2]. Using mTLS provides some access control through authentication with the CA.
[^2]: [Cloudflare mTLS][mTLS]

More info on this and the broader topic of security can be found by investigating the Zero Trust Model.

### Certificate Authority
A private CA needs to be created to verify, issue and revoke certificates for the applications within the cluster domain. Every authority has a certificate signed by a "higher" authorithy. This chain is bootstrapped with a self-signed root certificate. Lets call the CA implemented in the cluster the intermediate CA and have the root CA be external to the cluster.

As an aside, for the web there have been efforts to replace the third-party CAs with DANE & DNSSEC: https://www.sidn.nl/en/news-and-blogs/new-opportunity-for-dane-for-web

### Algorithm selection
Within the cluster we should be able to control all settings for secure communication[^3]. Therefore lets try and use: 
- Algorithm for key exchange: ECDHE(secp384r1) + SHA-512
- Algorithm for cert verification: ECDSA (secp384r1) + SHA-512
- Algorithm for bulk encryption: AES-256-GCM + HMAC-SHA-512

Good options for tls1.3: no tls compression, 0-rtt off, ocsp stapling on.

Guidelines on TLS can be found in publications by NIST[^4] as well as recommendations on elliptic curve selection[^5] and alot more.

[^3]: [NCSC-NL TLS Guidelines][TLSGuidelines]
[^4]: [NIST TLS Guidelines][NISTTLSGuidelines]
[^5]: [NIST Elliptic Curve Recommendations][NISTECRecommendations]

### Creating a root CA 
For a examples see the OpenSSL docs[^6] and x509 cert conf format[^7], example with cert functionality we might need later to revoke?[^8].
```
openssl ecparam -list_curves         
openssl genpkey -out root-private.pem -algorithm EC -pkeyopt ec_paramgen_curve:secp384r1 -aes256
openssl ec -in root-private.pem -pubout -out root-public.pem
openssl req -config root.config -new -x509 -sha3-512 -key root-private.pem -out root-cert.pem -days 3650
openssl x509 -in root-cert.pem -text
```

[^6]: [OpenSSL Docs: Examples][openssldocs]
[^7]: [OpenSSL x509 conf format][opensslx509ex]
[^8]: https://michaeljcallahan.medium.com/generating-an-elliptic-curve-certificate-authority-d5c47cca796e



### Managing keys in a cluster.
#### Kubernetes
#### Cilium
#### Nifi
#### Kafka
#### Sidecars (for applications without or outdated mTLS?)


### Links
- Publications on cyber security by NCSC-NL: https://english.ncsc.nl/publications
- Publications on cyber security by NIST: https://csrc.nist.gov/Publications
- TLS PKI Tools by Cloudflare: https://github.com/cloudflare/cfssl
- Kubernetes TLS: https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/
- Cloudflare Geo Key Manager: https://blog.cloudflare.com/inside-geo-key-manager-v2

[K8sAAA]: https://kubernetes.io/docs/reference/access-authn-authz/

[TLS]: https://en.wikipedia.org/wiki/Transport_Layer_Security
[mTLS]: https://www.cloudflare.com/learning/access-management/what-is-mutual-tls/
[TLSGuidelines]: https://english.ncsc.nl/publications/publications/2021/january/19/it-security-guidelines-for-transport-layer-security-2.1
[NISTTLSGuidelines]: https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-52r2.pdf
[NISTECRecommendations]: https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-186.pdf
[openssldocs]: https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html#EXAMPLES
[opensslx509ex]: https://www.openssl.org/docs/man3.0/man5/x509v3_config.html