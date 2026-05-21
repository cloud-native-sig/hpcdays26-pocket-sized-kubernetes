# Exercise 4 - Monitoring and telemetry 
## Grafana and Prometheus
## iperf3

Part 1 — Deploy an iperf3 Server

Create:

apiVersion: apps/v1
kind: Deployment

metadata:
  name: iperf-server

spec:
  replicas: 1

  selector:
    matchLabels:
      app: iperf-server

  template:
    metadata:
      labels:
        app: iperf-server

    spec:
      containers:
        - name: iperf3

          image: iperf3

          command:
            - iperf3

          args:
            - -s

          ports:
            - containerPort: 5201

Apply it:

kubectl apply -f iperf-server.yaml
Expose the Server

Create a Service:

kubectl expose deployment iperf-server \
    --port=5201 \
    --target-port=5201 \
    --name=iperf-service

Inspect it:

kubectl get svc
Part 2 — Launch a Client Pod

Create an interactive client pod:

kubectl run iperf-client \
    --image=iperf3 \
    -it --rm \
    --restart=Never -- sh

Inside the pod, test DNS:

nslookup iperf-service
Part 3 — Run a Bandwidth Test

Still inside the client pod:

iperf3 -c iperf-service

You should see throughput measurements similar to:

[ ID] Interval           Transfer     Bitrate
[  5]   0.00-10.00 sec   1.10 GBytes   945 Mbits/sec

This traffic is:

pod-to-service,
routed through Kubernetes networking,
and potentially crossing worker nodes.

Part 4 — Scaling the Server

Scale the deployment:

kubectl scale deployment iperf-server \
    --replicas=3

Check the pods:

kubectl get pods -o wide

The Service will now load balance connections across multiple backend pods.

Observing Load Balancing

Describe the Service:

kubectl describe service iperf-service

You should see multiple endpoints listed.

Run multiple client tests:

iperf3 -c iperf-service

Traffic may be directed to different backend pods on each connection.

Optional — Direct Pod Communication

Instead of using the Service, connect directly to a pod IP.

Find pod addresses:

kubectl get pods -o wide

Then from the client:

iperf3 -c <pod-ip>

This demonstrates:

pod IP routability,
direct pod networking,
and the role Services play in abstraction and stability.

Optional — Continuous Monitoring

In another terminal:

kubectl top pods

or:

kubectl top nodes

while running traffic tests.

This can introduce discussions around:

network bottlenecks,
CPU overhead of networking,
packet processing,
and resource contention.