#!/bin/sh
sudo iptables -F


myExtIP=$(curl -s http://www.opentlc.com/getip)
myGUID=$(hostname|cut -f2 -d-|cut -f1 -d.)

echo IP: $myExtIP
echo GUID: $myGUID


if [[ $myGUID == 'repl' ]]
   then
	DOMAIN=$myExtIP.xip.io
else

	DOMAIN=$myGUID.generic.opentlc.com
	HOST=fuseignite-$DOMAIN
fi
echo DOMAIN: $DOMAIN
profile=ignite

echo y | /home/jboss/oc-cluster-wrapper/oc-cluster destroy $profile
rm -rf /root/.oc
/home/jboss/oc-cluster-wrapper/oc-cluster up $profile --public-hostname=$HOST --routing-suffix=apps.$DOMAIN

sleep 10s

#echo y | oc login https://localhost:8443 --username=admin --password=admin --insecure-skip-tls-verify
echo y | oc login -u system:admin --insecure-skip-tls-verify
oc delete project myproject

chcat -d /root/.oc/profiles/$profile/volumes/vol{01..10}

### IMPORT IMAGE STREAMS
oc create -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/install/fuse-ignite-image-streams.yml -n openshift
oc create -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/amq/amq63-image-stream.json -n openshift
oc create -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/rhdg/datagrid71-image-stream.json -n openshift
oc create -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/StockApp/openjdk18-image-stream.json -n openshift
### Create Assets

### DB
oc new-project db --display-name="Database"
oc adm policy add-scc-to-user anyuid system:serviceaccount:db:default
oc create -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/db/db-template.json
oc new-app --template=db-template --param=DB_ROUTE=db.$DOMAIN


### WebService
sleep 10s
oc new-project stockapp --display-name="RHOAR - Stock App"
oc new-app redhat-openjdk18-openshift:1.3~https://github.com/pszuster/Fuse7TD --context-dir="StockApp" --name="stockapp"
oc expose svc stockapp --hostname=stock.$DOMAIN


### FTP
oc new-project ftp --display-name="FTP Server"
oc adm policy add-scc-to-user anyuid system:serviceaccount:ftp:default
oc process -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/ftp/ftp-template.json --param=NET2FTP_HOSTNAME=ftp.$DOMAIN | oc create -f -

### CRM
oc new-project opencrx --display-name="CRM"
oc adm policy add-scc-to-user anyuid system:serviceaccount:opencrx:default
oc process -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/crm/opencrx-template.json --param=OpenCRX_URL=opencrx.$DOMAIN | oc create -f -

### AMQ
oc new-project amq --display-name="Red Hat AMQ"
oc process -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/amq/amq63-basic.json --param=MQ_QUEUES=invoices --param=MQ_USERNAME=admin --param=MQ_PASSWORD=password | oc create -f -

### RHDG
oc new-project rhdg --display-name="Red Hat Data Grid"
oc new-app --name=stockcache --image-stream=jboss-datagrid71-openshift:1.3 -e INFINISPAN_CONNECTORS=rest -e CACHE_NAMES=stock
oc expose svc stockcache --hostname=rhdg.$DOMAIN

## IGNITE
oc new-project ignite --display-name="Fuse Ignite"
oc create -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/install/serviceaccount-as-oauthclient-restricted.yml -n ignite
oc create -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/install/fuse-ignite-ocp.yml -n ignite

sleep 5s

echo y | sudo oc login https://localhost:8443 --username=admin --password=admin --insecure-skip-tls-verify
var=$(sudo oc sa get-token syndesis-oauth-client -n ignite)
oc new-app --template "fuse-ignite" --param=ROUTE_HOSTNAME=fuse-ignite.$DOMAIN --param=OPENSHIFT_PROJECT=ignite --param=OPENSHIFT_OAUTH_CLIENT_SECRET=$var --param=IMAGE_STREAM_NAMESPACE=openshift

