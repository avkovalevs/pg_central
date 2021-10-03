# Steps to deploy k8s cluster on Hetzner Cloud

1. Install hetzner-kube command locally 
Build hetzner-kube from source:
~~~
sudo yum install golang
git clone https://github.com/xetys/hetzner-kube.git
cd hetzner-kube/
go build -o hetzner-kube
sudo mv hetzner-kube /usr/local/bin/hetzner-kube
~~~

2. Generate Hetzner API token key (if not exist)
3. Add context and ssh public key for Hetzner using commands:

~~~
hetzner-kube context add k8s #insert from step2 API token here
hetzner-kube ssh-key add --name k8s # Be sure you have id_rsa.pub in ~/.ssh/ folder
~~~

4. Install kubectl command locally (if not exist)
~~~
curl -LO https://dl.k8s.io/release/v1.22.0/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
~~~

5. Deploy k8s cluster:
~~~
hetzner-kube cluster create --name k8s --ssh-key k8s --master-count 1 --worker-count 1 --datacenters nbg1-dc3 
~~~
This will create 2 nodes k8s cluster after 5-10 minutes.

6. Generate kubeconfig for k8s cluster
~~~
hetzner-kube cluster kubeconfig k8s
~~~

7. Install Helm3 on k8s master node (required for bitnami chart)
~~~
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod u+x get_helm.sh
./get_helm.sh
~~~

8. Install addons to cluster. 
8.1 Check existing addon
~~~
hetzner-kube cluster addon list
~~~
8.2 Install  dashboard, hetzner-csi
~~~
hetzner-kube cluster addon install dashboard -n k8s #optional
hetzner-kube cluster addon install hetzner-csi -n k8s
~~~
hetzner-csi needed for persistent storage on Hetzner Cloud.

8.3 Save token for dashboard to file:
Use the following token to login to the dashboard: eyJhbGciOiJSUzI1NiIsImtpZCI6Ilc4LW11U2tLS0duTzF5VUhkTkhMTFhhMF9Sbkl3QUNJVDE4U2RlQS1aRDAifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLXZkazlnIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiIyMDNhNTc2ZS1mZGI0LTRkYWUtYmYxMy1iOTBjODk2M2YyZDQiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZS1zeXN0ZW06YWRtaW4tdXNlciJ9.clO2qOJvt9cFQHItB3Fsp6PENdfZAkyiparwmLJ3_TXOdMidnkFTZNvYo7KocuK7Ok-7foIIktxkZD82E2fAgDyTDotOlvTkASpKcV8BdVd6woFfQ-gcvEWdbsye666lR1Ocwwx_fJ1LqoMO-qAX-IkSsXM8yjGFZqkM0QhA2qDPJuW27CFTRZQi13zVF9fyODA35Xgx20KaxkF0I6TzvYzNTDV3izAfJX2hHvv76Z3Z7Y2GOBrrCKUS2Vn5z9oc6FuvS5ptumYfQQ561_zuz1TOzGlxpfYL9niKJ6EGY568iOLPJg5rgx3ERw0EaSY_UsRYCwUdWfbn2-524U25uQ

9. Install bitnami helm chart with Pgpool
~~~
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-release bitnami/postgresql-ha
~~~
You can see 2 attached storage disk on Hetzner with 10Gb size mounted to worker node.  

10. Save user passwords
~~~
root@k8s-master-01:~# export POSTGRES_PASSWORD=$(kubectl get secret --namespace default my-release-postgresql-ha-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
root@k8s-master-01:~# echo $POSTGRES_PASSWORD
jv7IWhXiOX
root@k8s-master-01:~# export REPMGR_PASSWORD=$(kubectl get secret --namespace default my-release-postgresql-ha-postgresql -o jsonpath="{.data.repmgr-password}" | base64 --decode)
root@k8s-master-01:~# echo $REPMGR_PASSWORD
nZ6UpNwZTX
~~~

11. Connect to PG databases. 
11.1
To connect to your database via pgpool run the following command:

kubectl run my-release-postgresql-ha-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql-repmgr:11.13.0-debian-10-r33 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql -h my-release-postgresql-ha-pgpool -p 5432 -U postgres -d postgres

To connect to your database from outside the cluster execute the following commands:

kubectl port-forward --namespace default svc/my-release-postgresql-ha-pgpool 5432:5432 &
psql -h 127.0.0.1 -p 5432 -U postgres -d postgres

11.2 Install postgresql-client packages on k8s master node for checking access to db:
~~~
apt install telnet
apt install postgresql-client-common
apt install postgresql-client-12
~~~

11.3 Connect to pods from k8s master node (pgpool and postgres). 
~~~
psql -h 10.244.1.9 -p 5432 -U postgres -d postgres #primary node
psql -h 10.244.1.8 -p 5432 -U postgres -d postgres #slave node
psql -h 10.244.1.7 -p 5432 -U postgres -d postgres #pgpool node
postgres=# show pool_nodes;
node_id |                                      hostname                                      | port | status | lb_weight |  role   | select_cnt | load_balance_node | replication_delay | replication_state | replication_sync_state | last_status_change  
---------+------------------------------------------------------------------------------------+------+--------+-----------+---------+------------+-------------------+-------------------+-------------------+------------------------+---------------------
 0       | my-release-postgresql-ha-postgresql-0.my-release-postgresql-ha-postgresql-headless | 5432 | up     | 0.500000  | primary | 713        | false             | 0                 |                   |                        | 2021-09-22 19:30:21
 1       | my-release-postgresql-ha-postgresql-1.my-release-postgresql-ha-postgresql-headless | 5432 | up     | 0.500000  | standby | 688        | true              | 0                 |                   |                        | 2021-09-22 19:31:06

~~~
The easy check on create database will show the replication and health of the nodes.
The IP addresses you can see in the "kubectl describe pod <name_of_the_pod>" command.

12. Check the postgres-ha cluster status:
~~~
root@k8s-master-01:~# kubectl get pods
NAME                                               READY   STATUS    RESTARTS   AGE
my-release-postgresql-ha-pgpool-56bc757cd4-k5f88   1/1     Running   0          6m9s
my-release-postgresql-ha-postgresql-0              1/1     Running   0          6m9s
my-release-postgresql-ha-postgresql-1              1/1     Running   0          6m9s
~~~

13. Optional step.
In case of controller-manager and scheduler in Unhealthy status there is need to remove the string "- --port=0" in the following yaml-files:
/etc/kubernetes/manifests/kube-scheduler.yaml
/etc/kubernetes/manifests/kube-controller-manager.yaml
See the block (spec->containers->command).
And restart kubelet using command below:
~~~
sudo systemctl restart kubelet.service
~~~

Check the controller-manager and scheduler healthy status again:
~~~
root@k8s-master-01:~# kubectl get cs
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok                  
controller-manager   Healthy   ok                  
etcd-0               Healthy   {"health":"true"}   
~~~

14. Run tests on pgpool load balancing and failover:
15. To delete k8s cluster use the following command:
~~~
hetzner-kube cluster delete k8s
~~~
