# Exercise 4 — Jobs and Batch Execution

In this exercise we will explore several of Kubernetes’ most important workload types for research computing and HPC-style environments:

- Jobs
- CronJobs
- distributed batch execution

Unlike long-running services such as web applications, batch workloads produce
outputs until completion at which point they terminate.
This makes them ideal for tasks such as simulations with parameter sweeps, data processing and machine learning.
Kubernetes supports such activities using Jobs and CronJobs with parallel execution and
automatic retry behaviour.

## Kubernetes Job Concepts

### Jobs

A Kubernetes Job creates one or more pods and ensures they complete successfully.

Unlike Deployments jobs are *not* intended to run forever and will terminate once work is complete.
Kubernetes tracks successful completions, failures, retries and execution state.

### CronJobs

CronJobs schedule Jobs periodically using cron syntax.
Examples applications include nightly backups or telemetry collection.

## Part 1 — A Simple Job

Move to a `jobs-demo` namespace and apply our 'hello-job' deployment:
```bash
kubectl create namespace jobs-demo
kubectl config set-context --current --namespace=jobs-demo
kubectl apply -f $RES_HOME/hello-job.yaml
```

You should now see the job lists via
```bash
kubectl get jobs
```
and be able to inspect the pods created:
```bash
kubectl get pods
```
You should notice the pod runs briefly, completes, and then enters the `Completed` state unlike in the case for
deployments, where pods are typically left `Running`.

### Viewing Job Logs

Logs for a job can be retrieved in the obvious way:
```bash
kubectl logs job/hello-job
```
You should see:
```text
Hello from Kubernetes Jobs!
Job complete.
```

## Part 2 — Parallel Batch Execution

Typical HPC workloads include being able to run multiple tasks in parallel, including parameter sweeps and ensemble simulations. In Kubernetes the Jobs resource is used to schedule parallel batch execution. We will start with a single parallel job:
```bash
kubectl apply -f $RES_HOME/parallel-job.yaml
```

### Observing Parallel Execution

Watch the pods,
```bash
kubectl get pods -w
```
and notice how multiple pods run simultaneously and complete independently of
one another. For a summary you can inspect the associated job:
```bash
kubectl describe job parallel-job
```
Look for completions, parallelism, success counters, and pod status.

## Part 3 — CronJobs

Next we will schedule a recurring task:
```bash
kubectl apply -f $RES_HOME/cronjob.yaml
```

### Observing Scheduled Jobs

Watch Jobs appear automatically:

```bash
kubectl get jobs -w
```

Every minute a new Job will be created, execute and terminate.

Inspect the CronJob:

```bash
kubectl get cronjobs
```

View logs from one execution:

```bash
kubectl logs job/<job-name>
```

!!! Note  
    It's worth noting, since the Rasberry Pi's are baked goods (air-gapped) they do not know what the time really is. 

## Part 4 — Capstone Demo: Distributed Monte Carlo π Estimation

We will now build a simple distributed scientific workload.

Monte Carlo methods estimate values using repeated random sampling.

We can estimate π by:

- randomly generating points,
- checking whether they fall inside a unit circle,
- and computing the resulting ratio.

This will demonstrate not only how Monte Carlo tasks are highly parallel (the
results can be aggregated) but also the independence of workers in a Kubernetes cluster.

### Monte Carlo π Refresher

Imagine a circle inscribed inside a square.

A square spanning \([-1, 1]\) on both axes has a side length of \(2\), and an area of \(2^2 = 4\).

The inscribed circle has a radius of \(1\), giving it an area of \(π × r^2 = π\).

Random points fall inside the circle with probability `circle_area / square_area` or

```math
P = π / 4
```
Estimating P from the proportion of points falling inside the circle during the
simulation, we can solve for an estimate of π:

```math
inside_points ≈ circle_area
total_points ≈ square_area
π ≈ 4 × (inside_points / total_points)
```

The principle of Monte Carlo is that the more samples that are generated, the better the estimate becomes.

### Distributed Monte Carlo Workers

Apply it:

```bash
kubectl apply -f $RES_HOME/monte-carlo.yaml
```

Observe the Workers.

```bash
kubectl get pods -w
```

Inspect the logs from all workers:

```bash
kubectl logs -l job-name=monte-carlo-pi
```

You should see slightly different estimates from each pod, for example:

```text
Hostname: monte-carlo-pi-xxxxx
Estimated π = 3.14184
Hostname: monte-carlo-pi-yyyyy
Estimated π = 3.13892
```

Although this example is simple, the same execution model scales to more complex
scientific simulations, rendering and machine learning inference.

### Scaling the job  

As with all things in Kubernetes, this can be scaled. By editing the manifest using vim, increase the number of completions by 20.

```bash
vi $RES_HOME/monte-carlo.yaml 
# Set completions: 20
```

To update the job, we will need to remove the old one first.

```bash
kubectl delete job monte-carlo-pi
kubectl apply -f $RES_HOME/monte-carlo.yaml
```

You should see the number of pods scale up to 20, but as we're using the same samples, the accuracy of the estimate will be similar. You can play around with editing the job via the yaml file.

## Clean-up

```bash
kubectl delete job hello-job
kubectl delete job parallel-job
kubectl delete cronjob time-printer
kubectl delete job monte-carlo-pi
```

## Summary

In this exercise you explored Kubernetes Jobs and CronJobs, and how distributed
batch workloads can be realised as Jobs with parallel execution across many pods.

You also built a simple distributed Monte Carlo simulation using Kubernetes Jobs.

This execution model is one of the reasons Kubernetes has become increasingly popular for:
scientific computing and research infrastructure as well as generally cloud-native HPC workflows.
