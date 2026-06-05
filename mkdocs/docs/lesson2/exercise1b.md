# Exercise 1b — Monitoring and Telemetry

In this exercise we will explore lightweight Kubernetes monitoring and telemetry using:

- `kubectl top`
- `metrics-server`
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

## Part 1 — Kubernetes Metrics

If `metrics-server` is installed (see [Extra reading](../extra-reading.md#kubernetes-metrics-server)), Kubernetes can expose live resource usage information through the Kubernetes API.

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

At the moment the cluster may appear relatively idle. We will now generate network traffic and workload activity to make the telemetry more interesting.

## Part 2 — Deploy an iperf3 Server and expose it

```bash
kubectl create namespace iperf-demo
kubectl apply -f $RES_HOME/iperf3.yaml
```

Inspect it:

```bash
kubectl get pods,svc
```

## Part 3 — Launch a Client Pod

Create an interactive client pod:

```bash
kubectl run iperf3-client \
    --image=workshop-tools:arm64 \
    -it --rm \
    --restart=Never -- sh
/ # 
```
And verify DNS resolution:
```bash
/ # nslookup iperf3-service
```

## Part 4 — Generate Network Traffic

In the client Run a bandwidth test:

```bash
/ # iperf3 -c iperf3-service
```

You should see output similar to:

```text
[ ID] Interval           Transfer     Bitrate
[  5]   0.00-10.00 sec   1.10 GBytes   945 Mbits/sec
```

This traffic is pod-to-service, routed through Kubernetes networking, and potentially crossing worker nodes. 

### Observing Cluster Metrics

We can observe some of the metrics using `kubectl top`. In the client, run `iperf3 -c iperf3-service -P 8 -t 20` to send multiple network connections between pods. Whilst it is running, open another terminal and watch node metrics update live with:

```bash
watch kubectl top pods
```

You should notice slight increases to the CPU activity, as well as changes in memory usage, and workload activity across nodes.

Even though this is only a small cluster, the same principles apply to much larger Kubernetes environments. Even with the production level monitoring, kube-state metrics can still be very useful.

### Optional: Inspecting Pod Placement

View where workloads are running:

```bash
kubectl get pods -o wide
```

Check:

- which node the server pod is running on,
- where the client pod landed,
- whether traffic may be crossing worker nodes.

<!--
This introduces useful discussions around:

- overlay networking,
- container network interfaces (CNIs),
- and virtual networking overhead.
-->

## Clean up
You can end the interactive client with `ctrl-d` then
```bash
kubectl delete deployment iperf-server
```
to remove the deployment including client and server pods.
<!--
# I don't think these are necessary
kubectl delete pod iperf3-client
kubectl delete service iperf-service
-->

## Summary

In production Kubernetes environments, telemetry is often collected and visualised using:

- Prometheus for metrics collection,
- and Grafana for dashboards and visualisation.

These systems allow:

- historical monitoring,
- alerting,
- performance analysis,
- and cluster-wide observability.

However, they also introduce additional operational overhead and resource consumption, which is why we are using the lighter-weight metrics pipeline for this workshop.

In this exercise you:

- explored Kubernetes telemetry,
- monitored resource usage with `kubectl top`,
- generated live traffic using `iperf3`,
- and observed workload behaviour across the cluster.

You also saw how Kubernetes exposes operational metrics that can later be integrated into larger observability platforms such as Prometheus and Grafana.
