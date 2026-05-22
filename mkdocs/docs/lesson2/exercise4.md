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

Create:

```yaml
apiVersion: batch/v1
kind: CronJob

metadata:
  name: time-printer

spec:
  schedule: "*/1 * * * *"

  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never

          containers:
            - name: clock

              image: bash

              command:
                - /bin/sh
                - -c
                - |
                  echo "Current time:"
                  date
```

Apply it:

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

## Part 4 — Capstone Demo: Distributed Monte Carlo π Estimation

We will now build a simple distributed scientific workload.

Monte Carlo methods estimate values using repeated random sampling.

We can estimate π by:

- randomly generating points,
- checking whether they fall inside a unit circle,
- and computing the resulting ratio.

This is an excellent Kubernetes example because:

- each worker is independent,
- tasks are embarrassingly parallel,
- and results can be aggregated afterwards.

### Monte Carlo π Refresher

The area of:

- a unit square is `1`
- a unit circle is `π`

If random points fall inside the circle with probability:

:contentReference[oaicite:0]{index=0}

then:

:contentReference[oaicite:1]{index=1}

The more samples we generate, the better the estimate becomes.

### Distributed Monte Carlo Workers

Apply it:

```bash
kubectl apply -f $RES_HOME/monte-carlo.yaml
```

### Observing the Workers

Watch the Job:

```bash
kubectl get pods -w
```

Inspect logs from all workers:

```bash
kubectl logs -l job-name=monte-carlo-pi
```

You should see slightly different estimates from each pod.

Example:

```text
Hostname: monte-carlo-pi-xxxxx
Estimated π = 3.14184
```

```text
Hostname: monte-carlo-pi-yyyyy
Estimated π = 3.13892
```

---

### Why This Is a Good HPC Example

This demonstrates several important distributed computing ideas:

- embarrassingly parallel workloads,
- independent task execution,
- distributed compute,
- workload scheduling,
- and aggregation of independent results.

Although the example is simple, the same execution model scales to:

- scientific simulations,
- rendering,
- machine learning inference,
- and parameter sweeps.

### Failure Recovery Demonstration

Delete one of the running worker pods:

```bash
kubectl get pods
```

```bash
kubectl delete pod <pod-name>
```

Observe Kubernetes recreate it automatically.

The Job controller ensures the requested number of successful completions still occurs.

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
- and failure recovery.

You also built a simple distributed Monte Carlo simulation using Kubernetes Jobs.

This execution model is one of the reasons Kubernetes has become increasingly popular for:

- scientific computing,
- research infrastructure,
- and cloud-native HPC workflows.
