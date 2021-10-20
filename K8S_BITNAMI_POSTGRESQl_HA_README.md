# HA solution with postgresql/pgpool on K8s
## Steps to deploy k8s cluster on Hetzner Cloud

### Install hetzner-kube command locally 
Build hetzner-kube from source:
~~~
sudo yum install golang # RHEL
sudo apt-get install golang # Ubuntu
git clone https://github.com/xetys/hetzner-kube.git
cd hetzner-kube/
/usr/local/go/bin/go build -o hetzner-kube
sudo mv hetzner-kube /usr/local/bin/hetzner-kube
~~~
Go version must be at least 1.15

### Generate Hetzner API token key (if not exist)
### Add context and ssh public key for Hetzner using commands:
~~~
hetzner-kube context add k8s #insert from step2 API token here
hetzner-kube ssh-key add --name k8s # Be sure you have id_rsa.pub in ~/.ssh/ folder
~~~

### Deploy k8s cluster on Hetzner Cloud:
~~~
hetzner-kube cluster create --name k8s --ssh-key k8s --master-count 1 --worker-count 1 --datacenters nbg1-dc3 
~~~
This will create 2 nodes k8s cluster after 5-10 minutes.

### Generate kubeconfig for k8s cluster
~~~
hetzner-kube cluster kubeconfig k8s
~~~
This step is neeeded for kubectl.

### Install addons on Hetzner Cloud k8s cluster
~~~
hetzner-kube cluster addon list
~~~

### Install dashboard, hetzner-csi addons
~~~
hetzner-kube cluster addon install dashboard -n k8s #optional
hetzner-kube cluster addon install hetzner-csi -n k8s
~~~
hetzner-csi addon needed for persistent storage for PostgreSQL DB's on Hetzner Cloud.

## Steps to setup on k8s master helm chart for HA postgresql
### Fix controller-manager and scheduler on k8s
In case of controller-manager and scheduler in Unhealthy status there is need to remove the string "- --port=0" in the following yaml-files and restart kubelet:
/etc/kubernetes/manifests/kube-scheduler.yaml
/etc/kubernetes/manifests/kube-controller-manager.yaml
See the block (spec->containers->command).
And restart kubelet using command below:
~~~
sudo systemctl restart kubelet.service
~~~

### Install Helm3 on k8s master node (required for bitnami chart)
~~~
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod u+x get_helm.sh
./get_helm.sh
~~~

### Install bitnami helm chart with Pgpool
~~~
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-release bitnami/postgresql-ha
~~~
You can see 2 attached storage disk on Hetzner with 10Gb size mounted to worker node.  

### Save user passwords
~~~
root@k8s-master-01:~# export POSTGRES_PASSWORD=$(kubectl get secret --namespace default my-release-postgresql-ha-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
root@k8s-master-01:~# echo $POSTGRES_PASSWORD
jv7IWhXiOX
root@k8s-master-01:~# export REPMGR_PASSWORD=$(kubectl get secret --namespace default my-release-postgresql-ha-postgresql -o jsonpath="{.data.repmgr-password}" | base64 --decode)
root@k8s-master-01:~# echo $REPMGR_PASSWORD
nZ6UpNwZTX
~~~

### Connect to PG databases 
To connect to your database via pgpool run the following command:

kubectl run my-release-postgresql-ha-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql-repmgr:11.13.0-debian-10-r33 --env="PGPASSWORD=$POSTGRES_PASSWORD" --command -- psql -h my-release-postgresql-ha-pgpool -p 5432 -U postgres -d postgres

To connect to your database from outside the cluster execute the following commands:

kubectl port-forward --namespace default svc/my-release-postgresql-ha-pgpool 5432:5432 &
psql -h 127.0.0.1 -p 5432 -U postgres -d postgres

### Install postgresql-client packages on k8s master node for checking access to db:
~~~
apt install telnet postgresql-client-common postgresql-client-12 postgresql-contrib
~~~

### Connect to pods from k8s master node (pgpool and postgres) 
~~~
psql -h 10.244.1.11 -p 5432 -U postgres -d postgres #primary node
psql -h 10.244.1.6 -p 5432 -U postgres -d postgres #slave node
psql -h 10.244.1.4 -p 5432 -U postgres -d postgres #pgpool node
postgres=# show pool_nodes;
node_id |                                      hostname                                      | port | status | lb_weight |  role   | select_cnt | load_balance_node | replication_delay | replication_state | replication_sync_state | last_status_change  
---------+------------------------------------------------------------------------------------+------+--------+-----------+---------+------------+-------------------+-------------------+-------------------+------------------------+---------------------
 0       | my-release-postgresql-ha-postgresql-0.my-release-postgresql-ha-postgresql-headless | 5432 | up     | 0.500000  | primary | 713        | false             | 0                 |                   |                        | 2021-09-22 19:30:21
 1       | my-release-postgresql-ha-postgresql-1.my-release-postgresql-ha-postgresql-headless | 5432 | up     | 0.500000  | standby | 688        | true              | 0                 |                   |                        | 2021-09-22 19:31:06

~~~
The easy check on create database will show the replication and health of the nodes.
The IP addresses you can see in the "kubectl describe pod <name_of_the_pod> | grep IP" command.

## Tuning K8s cluster with HA postgresql
### Install kubectl command locally (if not exist)
~~~
curl -LO https://dl.k8s.io/release/v1.22.0/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
~~~

### Check the postgres-ha cluster status:
~~~
# kubectl get pods
NAME                                               READY   STATUS    RESTARTS   AGE
my-release-postgresql-ha-pgpool-56bc757cd4-k5f88   1/1     Running   0          6m9s
my-release-postgresql-ha-postgresql-0              1/1     Running   0          6m9s
my-release-postgresql-ha-postgresql-1              1/1     Running   0          6m9s
~~~

### Check the controller-manager and scheduler healthy status again:
~~~
# kubectl get cs
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok                  
controller-manager   Healthy   ok                  
etcd-0               Healthy   {"health":"true"}   
~~~

## Run tests on pgpool load balancing and failover operations:

### Pgpool HA test
Kill the pgpool pod using command below:
~~~
kubectl delete pod my-release-postgresql-ha-pgpool-56bc757cd4-dcb4s
~~~
After 5-7 seconds you can see that pgpool pod will automatically started again.
This means that application running in k8s will reconnected to pgpool quickly.
Check the status pg nodes using command:
~~~
kubectl get pods -o wide
NAME                                               READY   STATUS    RESTARTS   AGE   IP            NODE            NOMINATED NODE   READINESS GATES
my-release-postgresql-ha-pgpool-56bc757cd4-dcb4s   1/1     Running   0          68m   10.244.1.4    k8s-worker-01   <none>           <none>
my-release-postgresql-ha-postgresql-0              1/1     Running   0          21s   10.244.1.11   k8s-worker-01   <none>           <none>
my-release-postgresql-ha-postgresql-1              1/1     Running   0          68m   10.244.1.6    k8s-worker-01   <none>           <none>
~~~

### Generate RW workload via pgpool and emulate the PG master failover
Copy script generate_1min_insert_workload.sql to k8s master and run workload via pgpool.
~~~
psql -h 10.244.1.4 -p 5432 -U postgres -d postgres -c "create database test;"
psql -h 10.244.1.4 -p 5432 -U postgres -d test -f generate_1min_insert_workload.sql
~~~

Open a new terminal and kill the PG master pod during the workload running.
~~~
kubectl delete pod my-release-postgresql-ha-postgresql-0;
~~~
After this command the pod will be deleted (killed) and restared again. As you can see the session with workload generation will be freezed on 10-15 sec and be continued. Check the number of rows in the table t_random using command:
~~~
select count(*) from t_random;
~~~
Expected result:
SELECT 5000000

### Load balancing tests
Create the database "xample" with 5000000 tuples using commands:
~~~
psql -h 10.244.1.4 -d postgres -U postgres -c "create database xample;"
pgbench -h 10.244.1.4 -U postgres -i -s 50 xample
~~~
Run a lot of select queries (10k) in order to generate workload for database:
~~~ 
pgbench -h 10.244.1.4 -U postgres -c 10 -j 2 -S -t 10000 xample
Password: 
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 50
query mode: simple
number of clients: 10
number of threads: 2
number of transactions per client: 10000
number of transactions actually processed: 100000/100000
latency average = 44.019 ms
tps = 227.172466 (including connections establishing)
tps = 227.184780 (excluding connections establishing)
~~~

Check the number of select_cnt in "show pool_nodes;" view.
As a result, the LB mechanism has split the workload between nodes.
Moreover, the default value for lb_weight is 0.5. It means both nodes will get equal number of queries.

### PG failover tests
Kill the PG master node using command below:
~~~
kubectl delete pod my-release-postgresql-ha-postgresql-0
~~~
Killing the PG master pod will not promote the replica to master. Master pod will be restarted by Kubernetes before repmgd will promote the replica pod to a new master.
The restart process of the PG master pod usually takes 10-15 seconds. In this case, a failback operation will not be needed. If the PG master and replica are outside the Kubernetes cluster failover and failback operations are taking place.

## Final step (optional): 
Destroy the k8s infrastructure on Hetzner Cloud 
~~~
hetzner-kube cluster delete k8s
~~~
