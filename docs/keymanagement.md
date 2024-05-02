A short summary of key management. I limited the scope to the technical side of a single application or set of applications that need to communicate securely. Specifically avoiding key policy, procedures and such.

TODO: When done, set expiration for all certs to 1 hour and see what breaks first :)  
TODO: diagram the setup
TODO:
- spire linked to root ca
- external tls using cert+trust manager? need that intermediate-endpoint bundle
- haproxy for external access trust check

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
- (cipher) Algorithm for bulk encryption: AES-256-GCM + HMAC-SHA-512

Good options for tls1.3: no tls compression, 0-rtt off, ocsp stapling on.

Guidelines on TLS can be found in publications by NIST[^4] as well as recommendations on elliptic curve selection[^5] and alot more.

Note: tried sha3-512 instead of sha-512, could not verify certificate signing requests with openssl due "unknown signature algorithm" error. Seems the consensus is there is no current use for a wider hash range, so alternative hashing algorithms like sha 3 have not been adopted yet amongst other reasons.[^8]  
Note: kubernetes control-plane is limited by golang supported ciphers. Selecting tlsMinVersion 1.3 will disallow selecting a specific cipher as they all are deemed safe by golang.[^golangcipherdiscussion]   
Note: using kubeadm to set up kubernetes forces rsa for auto-generated keys. Need to setup external CA and control the entire cert chain to use other algorithms.  

[^3]: [NCSC-NL TLS Guidelines][TLSGuidelines]
[^4]: [NIST TLS Guidelines][NISTTLSGuidelines]
[^5]: [NIST Elliptic Curve Recommendations][NISTECRecommendations]
[^8]: https://crypto.stackexchange.com/questions/72507/why-isn-t-sha-3-in-wider-use
[^golangcipherdiscussion]: https://github.com/golang/go/issues/29349

### Creating a root CA 
For examples see the OpenSSL docs[^6] and x509 cert conf format[^7], example with cert functionality we might need later to revoke?[^9]. After making a config, generate the private key and self-sign a certificate, which generates a public key and signature.
```
openssl ecparam -list_curves         
openssl genpkey -out root-private.key -algorithm EC -pkeyopt ec_paramgen_curve:secp384r1 -aes256
openssl req -config root.config -new -x509 -sha-512 -key root-private.key -out root.crt -days 3650
openssl x509 -in root.crt -text
```

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

#### Potential issues related to intermediate CAs
The pki truststore contains the CA certificates for authenticating a request. 
When making the choice on how and where to distribute the cert chain,
trust-manager (a certificate bundler) says the following about adding intermediates to truststores: "the intermediate cannot be safely rotated without all trust stores which contain it being updated first"[^bundlingintermediatesissue]

When managing a single truststore adding an intermediate can be ok, but when independent projects with independent truststores start forming...

In short for cross service mainability:
- only distribute the root CA to trust stores
- configure endpoints with the full chain from endpoint up to this root CA (the endpoint cert and any intermediate to the root)


[^bundlingintermediatesissue]: https://cert-manager.io/docs/trust/trust-manager/#bundling-intermediates
[^chainlimitations]: https://github.com/kubernetes/kubeadm/issues/2360#issuecomment-986901379

### Service Certificates (svc.cluster.domain.tld)
Depends on how you deploy the CA etc. Let's first get that setup and functional before wrinting this section. Making CA's available across the cluster, Signing certs for the service, etc. In general for internal services, sign with internal dns, external services add the external dns / ip

### Managing keys in a cluster.
By default kubernetes uses tokens for authentication and RBAC as the authorization check on the control plane.[^clusteraccess][^securingacluster]  
Note: not sure how tokens are checked. Both admin.conf and the tls for apiserver only contain kubernetes-ca, no intermediate ca. And connection was established despite intermediate ca between root and kubernete-ca not being in truststore or passed to kubernetes. May be sufficient for control plane to know its a valid token and signature originating from its own cert? // TODO: look into this

Spire uses SPIFF ID(spiff://trust_domain/id) encoded in a x509 certificate to prove the identity of a service.[^tetrateoverview]  Cilium Mutual Authentication automates the creation of SVID identities for in-cluster service level mTLS connections.[^mutualauthcil] 

Cert-manager supplies and renews certs to pods for application level mTLS. It has a spire csi driver to enable dynamic SVID generation for the lifetime of any pod.[^certmanagersvid] Cert-manager can also distribute and mount the root certificate into pods.

Trust-manager can be used to supply bundles of certificates in the cluster using a Bundle resource. It seems to preserve order and therefore could serve as a way to distribute cert chains too? 

Remains the problem of constructing the leaf + intermediates (+ optional root). Might have to use an init command/container to construct it on pod creation? Or maybe theres an option somewhere in spire, cert-manager, or cilium.

Maybe https://github.com/spiffe/spire/pull/391/commits/bb6cd7610ccc39bb6aabeebacd09b71ba79cc6ee upstreambundle for spire config? If this works as I read it then it would solve the entire chain problem, removing the need for trust-manager?

[^clusteraccess]: https://kubernetes.io/docs/concepts/security/controlling-access/
[^securingacluster]: https://kubernetes.io/docs/tasks/administer-cluster/securing-a-cluster/
[^tetrateoverview]: https://tetrate.io/blog/managing-certificates-in-istio-with-cert-manager-and-spire/
[^mutualauthcil]: https://docs.cilium.io/en/latest/network/servicemesh/mutual-authentication/mutual-authentication/
[^certmanagersvid]: https://cert-manager.io/docs/usage/csi-driver-spiffe/













#### Kubernetes control plane
Min tls version, false auth

// TODO; rewrite reflecting the changes made for twotier and then the cilium spire ca
The command return apiserver cert, not including kubernetes-ca cert? 
kinda makes sense kubernetes only there for the control plane, so as long as someone does not have access to the control plane nodes or keys are external, k8s can just check against its own root/intermediate CA

// TODO: https://kubernetes.io/docs/reference/access-authn-authz/kubelet-authn-authz/
check against those settings

```
echo | openssl s_client -showcerts -servername localhost -connect localhost:6443
```
Kubeadm by default creates all the CA's required to run the cluster[^10]. Let's instead sign the cluster CA's with an external root CA[^12]. Secondly set the minimum TLS to 1.3 for the initConfiguration, joinConfiguration and clusterConfiguration.

1. Create ca.crt and ca.key like an intermediate CA, copy the root certs to the appropriate certs directory on all the nodes, then kubeadm init (see roles k8s-control-plane and k8s-common). etcd/ca.{key,crt} and front-proxy-ca.{key,crt} are the other two CA's kubernetes needs. The ca.crt need to be a full chain up to the root CA (leaf, intermediate crts...)
  
2. Could go one step further and not copy the .key files. You would have to sign everthing externally. (not doing that for now) kubadm config ClusterConfiguration version v1beta4 will bring alternate ciphers. Currently kubeadm only generates rsa2048 from the CAs provided.

With this setup you need to renew the CAs (ca, etcd/ca and front-proxy-ca) manually, kubelet renew their client certs automatically[^13], everything else control plane related should renew during kubeadm control-plane upgrades[^11].

[^10]: https://kubernetes.io/docs/setup/best-practices/certificates/
[^11]: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/
[^12]: https://kubernetes.io/docs/tasks/administer-cluster/certificates/
[^13]: https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/#certificate-rotation
#### Kubernetes pods
Applications running in pods still need to be configured for mTLS, per application setup can be daunting, so let's first have a look at the Cilium Service Mesh, which enables mTLS at the service level, and Transparent Encryption for pod-to-pod encryption on cilium managed pods. Transparent Encryption does specifically does not provide any auth. The methods for wireguard and spire do not currently make use of the root ca we created for the control plane previously.


#### Cilium Transparent Encryption
https://isovalent.com/blog/post/zero-trust-security-with-cilium/

// TODO rewrite with the changes made spire

Let's enable WireGuard tunnels for encryption between pods and nodes[^14]. Add encryption.{enabled, type, nodeEncryption} to the cilium config. Also open port 51871 on the cloud/node firewalls. The control plane encryption is explicitly not managed by cilium, but by kubernetes mTLS impl.  
Note: This could result in traffic to pods on Control Plane nodes that are not part of the control plane if PreferNoSchedule taint is set on control-plane node-role (see last section of link above, node-to-node encryption). Therefore removed setting "scheduling_on_control_plane: allow" from kubernetesconfig in the local testconfig.

[^14]: https://docs.cilium.io/en/latest/security/network/encryption-wireguard/

Test the Transparent Encryption on various control/worker nodes with:
```
kubectl -n kube-system exec -ti <cilium-pod> -- cilium-dbg status | grep Encryption
```
Control plane nodes will display NodeEncryption: OptedOut.

Now that encryption is enabled we can enable service mesh mutual authentication.[^16][^17] 



1. create cilium namespace with intermediate CA for spire as secrets tls and a configmap with disk
     (insert spire link)
   sign the intermediate CA with the kubernetes-ca since that one is auto distributed with secrets?

spire docs for config 
https://spiffe.io/docs/latest/deploying/spire_server/
https://github.com/spiffe/spire/blob/v1.9.3/doc/plugin_server_upstreamauthority_disk.md
```
UpstreamAuthority "disk" {
    plugin_data {
        cert_file_path = "cert-chain: concat the {spire-cert, intermediate-certs-to-root...}.crt files"
        key_file_path = "spire-key"
        bundle_file_path = "root-cert"
    }
}
```
need to mount the files somehow

2. create the api


----
Ok, at this point, managing certificates becomes cumbersome. Problems:
1. Generating certs
2. Assigning certs to workloads
3. Loading certs into workloads
4. Updating certs

There are kubernetes cncf solutions for this:
1. trust-manager - distributes bundles of certs https://cert-manager.io/docs/trust/trust-manager/
2. cert-manager - generates key,certs for workloads

By using these abstractions, you will get a more unified way of generating trust and distributing it. It still requires point 3, but limits its scope to integration with the workload.

---




Spire-server holds a secrets reference to the kuberenetes-ca crt.

Mounts:
      /run/spire/bundle from spire-bundle (rw)      spire CA issuer 73:7e:51:64:57:ff:2a:f6:3f:19:1c:f1:53:4e:ec:0f subj
      /run/spire/config from spire-config (ro)   config
      /run/spire/sockets from spire-agent-socket (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-sd8gg (ro)
      /var/run/secrets/tokens from spire-agent (rw)


Information on improvements in ciliums mutual auth security [^15]. Enable authentication.mutual.spire settings in cilium config. 

TODO: review networkpolicies
TODO: extern/ingress mTLS  
TODO: tie internal auth to the external root ca (not possible through cilium? so external spire, or custom spire image authentication.mutual.spire.install.agent.image) 
TODO: https://docs.cilium.io/en/stable/security/tls-visibility/  
TODO: https://docs.cilium.io/en/latest/security/threat-model/    
TODO: read link https://www.cloudexpoeurope.de/news/securing-microservices-communication-mtls-kubernetes
TODO: cert-manager / trust-manager   

[^15]: https://cilium.io/blog/2024/03/20/improving-mutual-auth-security/
[^16]: https://docs.cilium.io/en/latest/network/servicemesh/mutual-authentication/mutual-authentication/
[^17]: https://www.youtube.com/watch?v=tE9U1gNWzqs




#### HAProxy

### observability
### accesslogging
### renewal
### app specific:
#### Nifi
#### Kafka
#### Sidecars (for applications without or outdated mTLS?)

### External CA
TODO: https://github.com/smallstep/certificates external ca?  
TODO: https://github.com/smallstep/autocert  

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