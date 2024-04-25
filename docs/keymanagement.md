A short summary of key management. I limited the scope to the technical side of a single application or set of applications that need to communicate securely. 

### Overview

Network encryption of https traffic is done with TLS[^1]. The server managing the security of the connection needs access to private and public TLS keys and a certificate issued by an Authority (CA). The certificate is a document by the Authority that guarantees the servers name and public key are authentic. The client starting the connection with the server can validate the certificate after which it uses the servers public key to setup the connection. Lastly the servers private key is used in decrypting communication from clients during the handshake. After the handhsake the connection is private, authenticated and tamper proof.
[^1]: [Wikipedia TLS][TLS]

Typically a client does not provide proof of authenticity. In a environment with applications communicating we can set up two side authentication. This is called mutual TLS(mTLS)[^2]. Using mTLS provides some access control through authentication with the CA.
[^2]: [Cloudflare mTLS][mTLS]

More info on this and the broader topic of security can be found by investigating the Zero Trust Model.

### Certificate Authority
A private CA needs to be created verify, issue and revoke certificates for the applications within the cluster domain. 

### Managing keys in a cluster.
#### Kubernetes
#### Cilium
#### Nifi
#### Kafka
#### Sidecars (for applications without or outdated mTLS?)


### Links
- Publications on cyber security by NCSC: https://english.ncsc.nl/publications
- TLS PKI Tools by Cloudflare: https://github.com/cloudflare/cfssl
- Kubernetes TLS: https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/
- Cloudflare Geo Key Manager: https://blog.cloudflare.com/inside-geo-key-manager-v2
- NCSC TLS Guidelines: https://english.ncsc.nl/publications/publications/2021/january/19/it-security-guidelines-for-transport-layer-security-2.1

[K8sAAA]: https://kubernetes.io/docs/reference/access-authn-authz/

[TLS]: https://en.wikipedia.org/wiki/Transport_Layer_Security
[mTLS]: https://www.cloudflare.com/learning/access-management/what-is-mutual-tls/
