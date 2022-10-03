# 4G-core-mme-loadbalancer

Repo is to show how an IPVS LB can be used for multiple MMEs in a 4G core.

Summary of software used:

- KIND kubernetes
- Open5gs 4G core using Helm Chart
- Calico CNI
- IPVS Loadbalancer running in docker container
- srsRAN simulator running in docker container

**_KIND deployment:_**

```
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.16.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

sudo kind create cluster -n open5gs-4g-core --config=kind-manifest/cluster-config.yaml

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/tigera-operator.yaml

kubectl create -f kind-manifest/custom-resources.yaml

kubectl create ns open5gs

kubectl create -f open5gs-helm/mongodb/

wget https://github.com/k8snetworkplumbingwg/multus-cni/archive/refs/tags/v3.9.1.tar.gz

tar -xzf v3.9.1.tar.gz

kubectl apply -f multus-cni-3.9.1/deployments/multus-daemonset-thick-plugin.yml

docker network create --subnet 172.20.0.0/16 ran-core

docker network connect --ip 172.20.128.2 ran-core open5gs-4g-core-worker

kubectl -n open5gs create secret generic diameter-ca --from-file=open5gs-helm/tls-certs/cacert.pem

kubectl -n open5gs create secret tls hss-tls \
  --cert=open5gs-helm/tls-certs/hss.cert.pem \
  --key=open5gs-helm/tls-certs/hss.key.pem
  
kubectl -n open5gs create secret tls mme-tls \
  --cert=open5gs-helm/tls-certs/mme.cert.pem \
  --key=open5gs-helm/tls-certs/mme.key.pem

kubectl -n open5gs create secret tls pcrf-tls \
  --cert=open5gs-helm/tls-certs/pcrf.cert.pem \
  --key=open5gs-helm/tls-certs/pcrf.key.pem

kubectl -n open5gs create secret tls smf-tls \
  --cert=open5gs-helm/tls-certs/smf.cert.pem \
  --key=open5gs-helm/tls-certs/smf.key.pem

helm upgrade --install -n open5gs core4g open5gs-helm/
```

**_Set POD route to go via KIND worker-node container IP_**

```
sudo ip route add 10.240.0.0/16 via 172.18.0.3
```

**_Inside MME-LB container. no need to run, it has been included in the docker-compose_**

```
tcpdump -nnni eth0 sctp port 36412
```

**_Inside MongoDB POD_**

```
cat << EOF > ./account.js
db = db.getSiblingDB('open5gs')
cursor = db.accounts.find()
if ( cursor.count() == 0 ) {
    db.accounts.insert({ salt: 'f5c15fa72622d62b6b790aa8569b9339729801ab8bda5d13997b5db6bfc1d997', hash: '402223057db5194899d2e082aeb0802f6794622e1cbc47529c419e5a603f2cc592074b4f3323b239ffa594c8b756d5c70a4e1f6ecd3f9f0d2d7328c4cf8b1b766514effff0350a90b89e21eac54cd4497a169c0c7554a0e2cd9b672e5414c323f76b8559bc768cba11cad2ea3ae704fb36abc8abc2619231ff84ded60063c6e1554a9777a4a464ef9cfdfa90ecfdacc9844e0e3b2f91b59d9ff024aec4ea1f51b703a31cda9afb1cc2c719a09cee4f9852ba3cf9f07159b1ccf8133924f74df770b1a391c19e8d67ffdcbbef4084a3277e93f55ac60d80338172b2a7b3f29cfe8a36738681794f7ccbe9bc98f8cdeded02f8a4cd0d4b54e1d6ba3d11792ee0ae8801213691848e9c5338e39485816bb0f734b775ac89f454ef90992003511aa8cceed58a3ac2c3814f14afaaed39cbaf4e2719d7213f81665564eec02f60ede838212555873ef742f6666cc66883dcb8281715d5c762fb236d72b770257e7e8d86c122bb69028a34cf1ed93bb973b440fa89a23604cd3fefe85fbd7f55c9b71acf6ad167228c79513f5cfe899a2e2cc498feb6d2d2f07354a17ba74cecfbda3e87d57b147e17dcc7f4c52b802a8e77f28d255a6712dcdc1519e6ac9ec593270bfcf4c395e2531a271a841b1adefb8516a07136b0de47c7fd534601b16f0f7a98f1dbd31795feb97da59e1d23c08461cf37d6f2877d0f2e437f07e25015960f63', username: 'admin', roles: [ 'admin' ], "__v" : 0})
}
EOF

mongo open5gs ./account.js


apt-get update;apt-get install wget -y
wget https://github.com/open5gs/open5gs/raw/main/misc/db/open5gs-dbctl;chmod +x open5gs-dbctl
./open5gs-dbctl add 208930100001111 8baf473f2f8fd09487cccbd7097c6862 e734f8734007d6c5ce7a0508809e7e9c
./open5gs-dbctl showall
```
