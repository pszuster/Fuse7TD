#!/bin/sh

h=$(hostname -s)
name=fisworkshop
long=${#name}
num=${h:$long}

DOMAIN=rhtechofficelatam.com
fisDomain=fis$num.$DOMAIN
fisHost=$name.$fisDomain


## IGNITE
oc new-project ignite --display-name="Fuse Ignite"
oc create -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/install/serviceaccount-as-oauthclient-restricted.yml -n ignite
oc create -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/install/fuse-ignite-ocp.yml -n ignite

var=$(oc sa get-token syndesis-oauth-client -n ignite)
echo $var
oc new-app --template "fuse-ignite" --param=ROUTE_HOSTNAME=fuse-ignite.$fisDomain --param=OPENSHIFT_PROJECT=ignite --param=OPENSHIFT_OAUTH_CLIENT_SECRET=$var --param=IMAGE_STREAM_NAMESPACE=openshift


