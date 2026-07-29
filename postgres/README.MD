# Helm chart for PostgreSQL

Wraps the [CloudNativePG](https://cloudnative-pg.io/charts/) `cluster` chart (aliased as `cnpg`).

## Parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `auth.username` | string | `postgres` | Superuser name stored in the generated secret |
| `auth.password` | string | `""` | Superuser password, the secret is only created when set |
| `pdb.enabled` | bool | `false` | Create an extra PodDisruptionBudget for the cluster pods |
| `pdb.minAvailable` | int/string | `nil` | Minimum available pods, takes precedence over `maxUnavailable` |
| `pdb.maxUnavailable` | int/string | `1` | Maximum unavailable pods, ignored when `minAvailable` is set |
| `pdb.unhealthyPodEvictionPolicy` | string | `""` | `IfHealthyBudget` or `AlwaysAllow` (Kubernetes >= 1.27) |
| `pdb.selectorLabels` | object | `{}` | Override the pod selector, defaults to `cnpg.io/cluster: <fullname>` |
| `cnpg.*` | object | | Values passed through to the upstream `cluster` chart |

> The CloudNativePG operator already manages PodDisruptionBudgets for a `Cluster`
> (toggled by `cnpg.cluster.enablePDB`). Enable `pdb.enabled` only when you need
> an additional, stricter budget on top of it. The rendered budget is named
> `<fullname>-pdb` so it never collides with the operator-managed ones.
