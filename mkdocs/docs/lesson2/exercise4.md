# Exercise 4 — Jobs and Batch Execution

In this exercise we will explore one of Kubernetes’ most important workload types for research computing and HPC-style environments:

- Jobs
- CronJobs
- and distributed batch execution

Unlike long-running services such as web applications, batch workloads:

- run to completion,
- produce outputs,
- and then terminate.

This makes them ideal for:

- simulations,
- data processing,
- scientific pipelines,
- machine learning tasks,
- and parameter sweeps.

## Why Batch Workloads Matter

Many HPC and research workloads are naturally batch-oriented.

Examples include:

- Monte Carlo simulations,
- genome analysis,
- image processing,
- parameter sweeps,
- finite element simulations,
- and workflow pipelines.

Kubernetes supports these using:

- Jobs
- CronJobs
- parallel execution
- and automatic retry behaviour.

## Kubernetes Job Concepts

### Jobs

A Kubernetes Job creates one or more pods and ensures they complete successfully.

Unlike Deployments:

- Jobs are not intended to run forever,
- pods terminate once work is complete.

Kubernetes tracks:

- successful completions,
- failures,
- retries,
- and execution state.

### CronJobs

CronJobs schedule Jobs periodically using cron syntax.

Examples:

- nightly backups,
- scheduled analysis,
- telemetry collection,
- or automated reporting.

## Part 1 — A Simple Job

```bash
kubectl create namespace jobs-demo
kubectl config set-context --current --namespace=jobs-demo
```

Apply it:

```bash
kubectl apply -f $RES_HOME/hello-job.yaml
```

### Inspecting the Job

View the Job:

```bash
kubectl get jobs
```

Inspect the pods created by the Job:

```bash
kubectl get pods
```

You should notice the pod runs briefly, completes, and enters the `Completed` state.

Unlike Deployments, this is expected behaviour.

### Viewing Job Logs

Inspect the output:

```bash
kubectl logs job/hello-job
```

You should see:

```text
Hello from Kubernetes Jobs!
Job complete.
```

## Part 2 — Parallel Batch Execution

Kubernetes Jobs can also run multiple tasks in parallel.

This is extremely useful for:

- parameter sweeps,
- ensemble simulations,
- and embarrassingly parallel workloads.

Apply it:

```bash
kubectl apply -f $RES_HOME/parallel-job.yaml
```

### Observing Parallel Execution

Watch the pods:

```bash
kubectl get pods -w
```

Notice:

- multiple pods running simultaneously,
- pods completing independently,
- and Kubernetes tracking progress automatically.

Inspect the Job:

```bash
kubectl describe job parallel-job
```

Look for:

- completions,
- parallelism,
- success counters,
- and pod status.

## Part 3 — CronJobs

Now we will schedule a recurring task.

```bash
kubectl apply -f $RES_HOME/cronjob.yaml
```

### Observing Scheduled Jobs

Watch Jobs appear automatically:

```bash
kubectl get jobs -w
```

Every minute:

- a new Job will be created,
- execute,
- and terminate.

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

Within Kubernetes we can use this example to show that:

- each worker is independent,
- Monte Carlo tasks are highly parallel,
- and results can be aggregated.

### Monte Carlo π Refresher

Imagine a circle inscribed inside a square.

A square spanning \([-1, 1]\) on both axes has a side length of \(2\), and an area of \(2^2 = 4\).

The inscribed circle has a radius of \(1\), giving it an area of \(π × r^2 = π\).

Random points fall inside the circle with probability `circle_area / square_area`:

```math
P = π / 4
```

Then we solve the equation for π. If we substitute the area for points inside or outside, we have an estimate for pi:

```math
inside_points ≈ circle_area
total_points ≈ square_area
π ≈ 4 × (inside_points / total_points)
```

The principle of Monte Carlo estimates is that the more samples we generate, the better the estimate becomes.

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

Although this example is simple, the same execution model scales to more complex scenarios like:

- scientific simulations,
- rendering,
- machine learning inference,
- and parameter sweeps.

### Scaling the job  

As with all things in Kubernetes, this can be scaled. By editing the manifest using vim, increase the number of completions 20.

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

## Summary and clean-up

```bash
kubectl delete job hello-job
kubectl delete job parallel-job
kubectl delete cronjob time-printer
kubectl delete job monte-carlo-pi
```

In this exercise you explored:

- Kubernetes Jobs,
- CronJobs,
- parallel execution,
- distributed batch workloads,

You also built a simple distributed Monte Carlo simulation using Kubernetes Jobs.

This execution model is one of the reasons Kubernetes has become increasingly popular for:

- scientific computing,
- research infrastructure,
- and cloud-native HPC workflows.
