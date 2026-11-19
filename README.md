# rybbit-railway

Wrapper images that let [Rybbit](https://github.com/rybbit-io/rybbit) (open-source web analytics)
deploy on Railway as a template with an empty deploy form.

| Directory | Image | What it adds to upstream |
| --- | --- | --- |
| `app` | `ghcr.io/bon5co/rybbit-railway` | the published client plus nginx: one public domain serving the UI and `/api`, sign-up refused at the edge |
| `backend` | `ghcr.io/bon5co/rybbit-railway-backend` | creates the first admin from `ADMIN_EMAIL` / `ADMIN_PASSWORD`, then starts with `DISABLE_SIGNUP=true` |
| `clickhouse` | `ghcr.io/bon5co/rybbit-railway-clickhouse` | upstream's compose `configs:` baked in, volume chown, thread limit from the cgroup |

Base images are pinned by digest. Rebuilt weekly.
