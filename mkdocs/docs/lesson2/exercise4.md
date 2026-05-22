# Exercise 4 — Monitoring and Telemetry

In this exercise we will explore lightweight Kubernetes monitoring and telemetry using:

- `kubectl top`
- metrics-server
- and live traffic generated with `iperf3`

The goal is to observe how workload behaviour appears through cluster metrics in real time.

Rather than treating monitoring as something separate from workloads, we will generate traffic ourselves and watch the cluster respond.

## Why Monitoring Matters

Once workloads become distributed across multiple nodes and containers, it becomes difficult to understand cluster behaviour from logs alone.

Monitoring systems help answer questions such as:

- Which workloads are consuming CPU?
- Which nodes are under pressure?
- Are applications healthy?
- Where are bottlenecks occurring?

In larger Kubernetes environments this telemetry is often collected using systems such as:

- Prometheus
- Grafana
- Loki
- OpenTelemetry

For this workshop we will use the lighter-weight Kubernetes metrics pipeline already available in the cluster.

## Part 1 - Kubernetes Metrics

If `metrics-server` is installed, see [Extra reading](../extra-reading.md#kubernetes-metrics-server), Kubernetes can expose live resource usage information through the Kubernetes API.

This includes:

- CPU usage,
- memory consumption,
- and node utilisation.

Inspect node metrics:

```bash
kubectl top nodes
```

Inspect pod metrics:

```bash
kubectl top pods
```

At the moment the cluster may appear relatively idle.

We will now generate network traffic and workload activity to make the telemetry more interesting.

---

## Part 2 — Deploy an iperf3 Server

Create:

```yaml
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
```

Apply it:

```bash
kubectl apply -f iperf-server.yaml
```

### Expose the Server

Create a Service:

```bash
kubectl expose deployment iperf-server \
    --port=5201 \
    --target-port=5201 \
    --name=iperf-service
```

Inspect it:

```bash
kubectl get svc
```

## Part 3 — Launch a Client Pod

Create an interactive client pod:

```bash
kubectl run iperf-client \
    --image=iperf3 \
    -it --rm \
    --restart=Never -- sh
```

Verify DNS resolution:

```bash
nslookup iperf-service
```

---

## Part 4 — Generate Network Traffic

Run a bandwidth test:

```bash
iperf3 -c iperf-service
```

You should see output similar to:

```text
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-10.00 sec   1.10 GBytes   945 Mbits/sec
```

This traffic is:
- pod-to-service,
- routed through Kubernetes networking,
- and potentially crossing worker nodes.

### Observing Cluster Metrics

While `iperf3` is running, open another terminal.

Watch node metrics update live:

```bash
watch kubectl top nodes
```

Or observe pod resource usage:

```bash
watch kubectl top pods
```

You should notice:
- increased CPU activity,
- changing memory usage,
- and workload activity across nodes.

Even though this is only a small cluster, the same principles apply to much larger Kubernetes environments.

---

### Inspecting Pod Placement

View where workloads are running:

```bash
kubectl get pods -o wide
```

Check:
- which node the server pod is running on,
- where the client pod landed,
- and whether traffic may be crossing worker nodes.

This introduces useful discussions around:
- overlay networking,
- container network interfaces (CNIs),
- and virtual networking overhead.

---

### Optional — Scaling the Server

Scale the server deployment:

```bash
kubectl scale deployment iperf-server \
    --replicas=3
```

Inspect the endpoints:

```bash
kubectl describe service iperf-service
```

The Service should now load balance traffic across multiple backend pods.

---

### Optional — Direct Pod Communication

Instead of using the Service abstraction, connect directly to a pod IP.

Find pod addresses:

```bash
kubectl get pods -o wide
```

Then from the client:

```bash
iperf3 -c <pod-ip>
```

This demonstrates:
- direct pod networking,
- pod IP routability,
- and the role Kubernetes Services play in abstraction and stability.

## Summary and Discussion 

### Prometheus and Grafana

In production Kubernetes environments, telemetry is often collected and visualised using:

- Prometheus for metrics collection,
- and Grafana for dashboards and visualisation.

These systems allow:
- historical monitoring,
- alerting,
- performance analysis,
- and cluster-wide observability.

However, they also introduce additional operational overhead and resource consumption, which is why we are using the lighter-weight metrics pipeline for this workshop.

### Cleanup

```bash
kubectl delete deployment iperf-server
kubectl delete service iperf-service
```

---

### Summary

In this exercise you:

- explored Kubernetes telemetry,
- monitored resource usage with `kubectl top`,
- generated live traffic using `iperf3`,
- and observed workload behaviour across the cluster.

You also saw how Kubernetes exposes operational metrics that can later be integrated into larger observability platforms such as Prometheus and Grafana.