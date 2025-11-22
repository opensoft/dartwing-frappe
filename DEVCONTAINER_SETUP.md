# Dartwing Skinny DevContainer

This repository provides the **lightweight** VS Code DevContainer that attaches to an existing Frappe bench instead of recreating the entire stack. It is tailored for day‑to‑day development of the Dartwing app while the Frappe services (MariaDB, Redis, socket.io, etc.) continue to run from the primary bench container.

## Repository Contents (git-tracked)

```
dartwing-frappe/
├── .devcontainer/
│   ├── devcontainer.json            # VS Code entrypoint (attaches to compose service)
│   ├── docker-compose.yml           # Skinny container definition + network wiring
│   ├── docker-compose.override.yml  # Local overrides (optional)
│   ├── Dockerfile                   # Tooling image
│   ├── setup_dartwing_in_frappeBench.sh  # Main postStart hook
│   ├── setup_new_frappe-app-dartwing.sh  # Emergency app bootstrap helper
│   ├── setup-frappe.sh              # Legacy bench bootstrap helper
│   ├── nginx.conf / *.md            # Docs and supporting config
│   └── .env.example                 # Template for local secrets
├── .gitignore
└── README.md
```

Everything under `development/` and the `.devcontainer/.env` file remain ignored so you can mount an existing bench safely.

## Generated at Runtime (git-ignored)

```
development/
└── frappe-bench/                    # Checked out or created outside this repo
    ├── apps/
    │   ├── frappe/                  # Comes from frappe/frappe
    │   └── frappe-app-dartwing/     # Cloned or bootstrapped by our scripts
    ├── sites/
    │   └── dartwing.localhost/
    ├── env/, config/, logs/, etc.
```

> The skinny container **expects** this bench directory to exist (either initialized previously or produced by `.devcontainer/setup-frappe.sh`). The directory persists through container rebuilds because it lives on the host filesystem and is bind-mounted into `/workspace/development/frappe-bench`.

## Container Architecture & Mounts

| Path inside container | Host binding / source                                  | Purpose |
|-----------------------|--------------------------------------------------------|---------|
| `/workspace`          | Whole repo root (`../`)                                | Gives the container access to this repo and the `development/` bench tree. |
| `/workspace/src`      | `${FRAPPE_DARTWING_APP_SRC_PATH}` (default `../development/frappe-bench/apps/dartwing_frappe/dartwing`) | Direct mount of the Dartwing Python package for editors and tooling that expect a flat `src/`. |
| `frappe-network`      | External Docker network                                | Connects to the already-running Frappe infrastructure (MariaDB + Redis containers). |
| `/var/run/docker.sock`| Host Docker socket                                     | Optional access to Docker CLI inside the devcontainer. |

Because the bench already manages MariaDB/Redis, `docker-compose.yml` only declares the single `dartwing-dev` service (the skinny container) and relies on the external `frappe-network`.

## DevContainer Lifecycle

1. **`devcontainer.json`** launches the `dartwing-dev` service defined in `.devcontainer/docker-compose.yml`.
2. On each start, VS Code runs `.devcontainer/setup_dartwing_in_frappeBench.sh`. This script:
   - Ensures MariaDB host settings exist inside the bench.
   - Creates/updates the `dartwing.localhost` site.
   - Checks for the Dartwing app under `apps/frappe-app-dartwing`.
   - Clones `https://github.com/Opensoft/frappe-app-dartwing.git` if the folder is missing.
   - Falls back to `development/frappe-bench/setup_new_frappe-app-dartwing.sh` to generate a brand-new local app if cloning fails (useful when developing without network access or when starting fresh).
3. After setup the script installs the app on the site and runs `bench use dartwing.localhost`.

## Preparing the Bench (one-time)

1. **Provision the base Frappe bench**: run `.devcontainer/setup-frappe.sh` or your standard bench init process on the host so that `development/frappe-bench` exists. This step usually happens in the heavyweight “core” devcontainer.
2. **Share the Docker network**: ensure the primary bench stack has created the `frappe-network`. The skinny container attaches to it automatically; if the network is missing the initialize command warns you.

## Day-to-Day Usage

1. Clone this repo and `code .`.
2. Copy `.devcontainer/.env.example` to `.devcontainer/.env` and adjust any overrides (e.g., `FRAPPE_BENCH_PATH`, `FRAPPE_DARTWING_APP_SRC_PATH`, credentials).
3. Reopen in DevContainer. The post-start script handles app + site setup.
4. Develop using either of the following entry points:
   - **Flat package view**: edit files directly under `/workspace/src`. This mirrors the `dartwing` Python package and is ideal for editors or scripts expecting a traditional `src/` layout.
   - **Bench context**: when you need full bench paths (`bench start`, exporting fixtures, etc.) work from `/workspace/development/frappe-bench/apps/frappe-app-dartwing`.
5. Use standard Frappe commands from `/workspace/development/frappe-bench` (bench start, migrate, tests). Because this container only carries tooling, the actual web server/processes still run from the original bench stack.

## Resetting the App

- To re-clone from GitHub, delete `development/frappe-bench/apps/frappe-app-dartwing` and rerun the DevContainer—`setup_dartwing_in_frappeBench.sh` will fetch it.
- To bootstrap a clean local app without Git, run `development/frappe-bench/setup_new_frappe-app-dartwing.sh`. The main script automatically invokes it whenever the repo is missing and cloning fails.
- To nuke everything, remove `development/frappe-bench`, rebuild the primary bench container, then reopen this skinny container.

## Configuration Reference

| Variable | Where it’s used | Description |
|----------|-----------------|-------------|
| `FRAPPE_BENCH_PATH` | Setup scripts | Absolute path to the shared bench. Defaults to `/workspace/development/frappe-bench`. |
| `FRAPPE_DARTWING_APP_SRC_PATH` | docker-compose volume | Source directory bound to `/workspace/src`. Defaults to the Dartwing package inside the bench app. |
| `FRAPPE_SITE_NAME`, `ADMIN_PASSWORD`, etc. | Setup scripts | Override site/app credentials when needed. |
| `DB_HOST`, `REDIS_*` | docker-compose environment | Connection strings pointing at the infrastructure running on `frappe-network`. |

Store overrides in `.devcontainer/.env`; the file is gitignored.

## Troubleshooting & Tips

- If VS Code warns that `frappe-network` does not exist, start the primary bench devcontainer first (it is responsible for creating the network and services).
- When the post-start script fails, re-run it manually via `bash .devcontainer/setup_dartwing_in_frappeBench.sh` inside the DevContainer to review logs.
- Bench commands still run in the shared bench directory; the skinny container does not start background services automatically.
- For additional hints see `.devcontainer/README.md` and the inline comments within each script.
