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

Note: tried sha3-512 instead of sha-512, could not verify certificate signing requests with openssl due "unknown signature algorithm" error. Seems the consensus is there is no current use for a wider hash range, so alternative hashing algorithms like sha 3 have not been adopted yet amongst other reasons.[^8]

[^3]: [NCSC-NL TLS Guidelines][TLSGuidelines]
[^4]: [NIST TLS Guidelines][NISTTLSGuidelines]
[^5]: [NIST Elliptic Curve Recommendations][NISTECRecommendations]
[^8]: https://crypto.stackexchange.com/questions/72507/why-isn-t-sha-3-in-wider-use

### Creating a root CA 
For examples see the OpenSSL docs[^6] and x509 cert conf format[^7], example with cert functionality we might need later to revoke?[^9]. After making a config, generate the private key and self-sign a certificate, which generates a public key and signature.
```
openssl ecparam -list_curves         
openssl genpkey -out root-private.key -algorithm EC -pkeyopt ec_paramgen_curve:secp384r1 -aes256
openssl req -config root.config -new -x509 -sha-512 -key root-private.key -out root.crt -days 3650
openssl x509 -in root.crt -text
```



#### the config
distinguished_name: section header name  
commonName: legacy field (single name for subject of cert)  
basicConstraints:   
keyUsage: https://www.gradenegger.eu/en/basics-the-key-usage-certificate-extension/  
fields https://superuser.com/a/1248085  

[^6]: [OpenSSL Docs: Examples][openssldocs]
[^7]: [OpenSSL x509 conf format][opensslx509ex]
[^9]: https://michaeljcallahan.medium.com/generating-an-elliptic-curve-certificate-authority-d5c47cca796e

### Intermediate CA (cluster.domain.tld)
Generate a certificate signing request (CSR) for the intermediate and sign it with the root CA. See [kubernetes](#kubernetes) for requirements to make it a cluster CA. If you make an intermediate CA that the cluster will manage, then don't encrypt the private key.   
Note: csrs use req_extensions instead of x509_extensions in [ req ] header, otherwise openssl will not add keyUsage and basicConstraints to the csr. Also add -copy_extensions copy in the cert creation or they will be ignored.
```
openssl genpkey -out intermediate-private.key -algorithm EC -pkeyopt ec_paramgen_curve:secp384r1 -aes256
openssl req -config intermediate.config -new -key intermediate-private.key -out intermediate.csr -sha-512
openssl x509 -req -copy_extensions copy -in intermediate.csr -CA root.crt -CAkey root-private.key -out intermediate.crt -sha-512 -days 3650
openssl x509 -in intermediate.crt -text
openssl verify -verbose -CAfile root.crt intermediate.crt
```

### Service Certificates (svc.cluster.domain.tld)
Depends on how you deploy the CA etc. Let's first get that setup and functional before wrinting this section. Making CA's available across the cluster, Signing certs for the service, etc. In general for internal services, sign with internal dns, external services add the external dns / ip

### Managing keys in a cluster.
#### Kubernetes control plane
Kubeadm by default creates all the CA's required to run the cluster[^10]. Let's instead sign the cluster CA's with an external root CA[^12].

1. Create ca.crt and ca.key like an intermediate CA, copy the root/intermediate certs chain used to the appropriate certs directory on all the nodes, then kubeadm init (see roles k8s-control-plane and k8s-common). etcd/ca.{key,crt} and front-proxy-ca.{key,crt} are the other two CA's kubernetes needs.
  
2. Could go one step further and not copy the .key files. You would have to sign everthing externally. (not doing that for now) kubadm config ClusterConfiguration version v1beta4 will bring alternate ciphers. Currently kubeadm only generates rsa2048 from the CAs provided.

With this setup you need to renew the CAs (ca, etcd/ca and front-proxy-ca) manually, kubelet renew their client certs automatically[^13], everything else control plane related should renew during kubeadm control-plane upgrades[^11].

[^10]: https://kubernetes.io/docs/setup/best-practices/certificates/
[^11]: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/
[^12]: https://kubernetes.io/docs/tasks/administer-cluster/certificates/
[^13]: https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/#certificate-rotation


#### Cilium
https://docs.cilium.io/en/stable/security/tls-visibility/
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