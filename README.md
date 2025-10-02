# DevOps CI/CD

## To deploy application locally on kind cluster
1. Push code to Github and the pipeline will create and update container image on GHCR.
2. Make sure kind k8s cluster is up and running. Then run `./kind-load.sh` to load this image into the your local kind cluster.
3. Run a postgres database instance first, because the next steps will need it
   * Run `./run-postgres.sh` script
   * Make sure the Postgres database has started by checking that there is a postgres container running if you run
   command ` docker ps --filter name=orders-pg `
   * Do not proceed with next steps until database is up and running
4. Create self-signed certs (needed by Ingress)
   * Run `./create-tls-certs.sh` (only needed once at startup)
5. Go to `terraform` folder and run `terraform apply` to deploy the helm release for app. 
   * This should automatically deploy first deploy the secret and configmap required for accessing database and then also deploy the orders app. 
   * Once deployed and if the docker image changes, you may run `kubectl rollout restart deployment/orders` to pick up the new image.

## For testing application
### Port-forward
If using `443` port-forward must be done via sudo
```
sudo kubectl -n ingress-nginx port-forward pod/ingress-nginx-controller-7c8dfb995b-bw9dn 443:443

```

If you want to avoid sudo, then use port `8443` instead of `443`. But then all following commands, you must add `:8443`
```
kubectl -n ingress-nginx port-forward pod/ingress-nginx-controller-7c8dfb995b-bw9dn 8443:443
```
Note: `-k` is needed here because we're using self-signed certificate. If not used, curl tries to verify the cert which is not possible here. 

### Check health endpoint
```
curl -k https://orders.localtest.me/health
```

### Add orders
```
curl -k -X POST https://orders.localtest.me/orders -H 'Content-Type: application/json' -d '{"amount":"12.36"}'
```

### List existing orders
```
curl -k https://orders.localtest.me/orders
```

### View FastAPI UI Webpage
Open in browser: 
https://orders.localtest.me/


## For installing Prometheus
From `observability` folder, run:
```
./prometheus-grafana.sh
```

Then:
```
kubectl -n monitoring port-forward svc/kps-grafana 3000:80
```
Then in a browser, open: http://grafana.localtest.me:3000/

