# Final Project Pipeline - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `ACT_OFFLINE=1 ./security/run-pipeline.sh run` on 2026-10-08 (the second run - see [README.md](README.md) for what failed in the first).

```text

==============================================================
STEP 1 - tools and the local registry that stands in for ghcr.io
==============================================================
act version 0.2.89
docker 29.6.1
registry: s21-registry registry:2 127.0.0.1:5057->5000/tcp
event file: {"act": true}
commit under test: 888cd81 on main

==============================================================
STEP 2 - act push (the whole pipeline)
==============================================================
$ act push -W .github/workflows/final-project.yml -e final-devops-project/.act/event-push.json \
      -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest --container-architecture linux/arm64 \
      --artifact-server-path final-devops-project/.act/artifacts --artifact-server-port 34570 --rm --pull=false --action-offline-mode

time="2026-10-08T00:19:49+05:30" level=info msg="Using docker host 'unix:///var/run/docker.sock', and daemon socket 'unix:///var/run/docker.sock'"
time="2026-10-08T00:19:49+05:30" level=info msg="Start server on http://100.128.166.254:34570"
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ] ⭐ Run Set up job
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] ⭐ Run Set up job
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] Cleaning up services for job Backend - lint, test, migrations
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] Cleaning up network for job Backend - lint, test, migrations, and network name is: act-S21-Final-Project--Campus-Lost--Found-Backend--lint-test-mi-d7b13b2e15896c1e88e378e49d8f59dda28baeccc57da69af64ae6a0550ad132-backend-test-network
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   ✅  Success - Set up job
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   ☁  git clone 'https://github.com/actions/setup-node' # ref=v6
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] container health of bec119e62fe7bb5cf21010228b320f3c622509a6f9c66f5ead373a82e6300460 (postgres:17-alpine) is starting
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ] ⭐ Run Main actions/checkout@v6
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] container health of bec119e62fe7bb5cf21010228b320f3c622509a6f9c66f5ead373a82e6300460 (postgres:17-alpine) is starting
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] container health of bec119e62fe7bb5cf21010228b320f3c622509a6f9c66f5ead373a82e6300460 (postgres:17-alpine) is starting
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   ✅  Success - Main actions/checkout@v6 [4.063626542s]
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ] ⭐ Run Main actions/setup-node@v6
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] container health of bec119e62fe7bb5cf21010228b320f3c622509a6f9c66f5ead373a82e6300460 (postgres:17-alpine) is healthy
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   ✅  Success - Set up job
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | Found in cache @ /opt/hostedtoolcache/node/22.23.3/arm64
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] ⭐ Run Main actions/checkout@v6
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | node: v22.23.3
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | npm: 10.9.9
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | yarn: 
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   ✅  Success - Main actions/setup-node@v6 [3.718138917s]
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ] ⭐ Run Main npm ci
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   ✅  Success - Main actions/checkout@v6 [4.506870667s]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] ⭐ Run Main actions/setup-python@v6
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | 
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | added 21 packages, and audited 22 packages in 5s
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | 
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | found 0 vulnerabilities
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   ✅  Success - Main npm ci [5.33351825s]
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ] ⭐ Run Main npm run build
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | 
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | > lostfound-frontend@1.0.0 build
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | > vite build
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | 
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | vite v8.3.3 building client environment for production...
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | transforming...
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | Successfully set up CPython (3.13.16)
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | ✓ 17 modules transformed.
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   ✅  Success - Main actions/setup-python@v6 [2.804693792s]
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | rendering chunks...
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] ⭐ Run Main Install dependencies
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | computing gzip size...
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | dist/index.html                   0.40 kB │ gzip:  0.27 kB
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | dist/assets/index-CW2q_e7p.css    3.55 kB │ gzip:  1.22 kB
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | dist/assets/index-2hhLKh1j.js   225.31 kB │ gzip: 70.50 kB
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | 
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | ✓ built in 854ms
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | dist:
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | total 8
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | drwxr-xr-x 2 root root 4096 Oct  7 18:50 assets
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | -rw-r--r-- 1 root root  408 Oct  7 18:50 index.html
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | 
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | dist/assets:
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | total 228
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | -rw-r--r-- 1 root root 225312 Oct  7 18:50 index-2hhLKh1j.js
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | -rw-r--r-- 1 root root   3551 Oct  7 18:50 index-CW2q_e7p.css
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   ✅  Success - Main npm run build [2.23880075s]
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ] ⭐ Run Main actions/upload-artifact@v5
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   ✅  Success - Main Install dependencies [1.96467425s]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] ⭐ Run Main ruff check + ruff format --check
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | 11 files already formatted
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   ✅  Success - Main ruff check + ruff format --check [341.78825ms]
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | With the provided path, there will be 3 files uploaded
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | Artifact name is valid!
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | Root directory input is valid!
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | Beginning upload of artifact content to blob storage
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] ⭐ Run Main pytest with coverage (SQLite, set in tests/conftest.py)
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | Uploaded bytes 71613
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | Finished uploading artifact content to blob storage!
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | SHA256 digest of uploaded artifact zip is cd87edc4da2fb81978a9017ed1e8a8150d8b7fe6a72f1f9f059409dff781c189
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | Finalizing artifact upload
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | Artifact frontend-dist.zip successfully finalized. Artifact ID 1427224128
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | Artifact frontend-dist has been successfully uploaded! Final size is 71613 bytes. Artifact ID is 1427224128
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/1427224128
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   ✅  Success - Main actions/upload-artifact@v5 [2.282422292s]
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ] ⭐ Run Post actions/setup-node@v6
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   ✅  Success - Post actions/setup-node@v6 [434.362292ms]
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ] ⭐ Run Complete job
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ] Cleaning up container for job Frontend - npm ci + build
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ]   ✅  Success - Complete job
[S21 Final Project - Campus Lost & Found/Frontend - npm ci + build       ] 🏁  Job succeeded
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | ============================= test session starts ==============================
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /opt/hostedtoolcache/Python/3.13.16/arm64/bin/python
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | cachedir: .pytest_cache
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | rootdir: /Users/pratyushmohanty/Devops-assignment/final-devops-project/application/backend
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | configfile: pytest.ini
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | testpaths: tests
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | plugins: anyio-4.15.1, cov-7.1.0, platformdirs-4.12.3
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | collecting ... collected 13 items
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | 
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tests/test_api.py::test_health_does_not_need_db PASSED                   [  7%]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tests/test_api.py::test_ready_reports_database PASSED                    [ 15%]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tests/test_api.py::test_create_item PASSED                               [ 23%]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tests/test_api.py::test_create_rejects_bad_kind PASSED                   [ 30%]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tests/test_api.py::test_create_rejects_short_title PASSED                [ 38%]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tests/test_api.py::test_list_and_filter PASSED                           [ 46%]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tests/test_api.py::test_get_item_and_404 PASSED                          [ 53%]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tests/test_api.py::test_update_status_to_claimed PASSED                  [ 61%]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tests/test_api.py::test_update_rejects_unknown_status PASSED             [ 69%]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tests/test_api.py::test_delete_item PASSED                               [ 76%]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tests/test_api.py::test_stats PASSED                                     [ 84%]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tests/test_api.py::test_metrics_exposed PASSED                           [ 92%]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tests/test_api.py::test_info_shows_environment PASSED                    [100%]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | 
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | - generated xml file: /Users/pratyushmohanty/Devops-assignment/final-devops-project/application/backend/reports/junit.xml -
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | ================================ tests coverage ================================
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | _______________ coverage: platform linux, python 3.13.16-final-0 _______________
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | 
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | Name                   Stmts   Miss  Cover   Missing
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | ----------------------------------------------------
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | app/__init__.py            0      0   100%
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | app/config.py             21      1    95%   31
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | app/db.py                 25      3    88%   17, 38-39
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | app/main.py               82      3    96%   53-54, 95
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | app/models.py             18      0   100%
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | app/observability.py      44      0   100%
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | app/schemas.py            38      0   100%
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | ----------------------------------------------------
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | TOTAL                    228      7    97%
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | Coverage XML written to file reports/coverage.xml
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | ============================== 13 passed in 0.55s ==============================
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   ✅  Success - Main pytest with coverage (SQLite, set in tests/conftest.py) [4.503725625s]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] ⭐ Run Main Alembic upgrade head / downgrade base on real Postgres 17
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | postgres at localhost:25432
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | INFO  [alembic.runtime.migration] Will assume transactional DDL.
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | INFO  [alembic.runtime.migration] Running upgrade  -> 0001, create items table
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | INFO  [alembic.runtime.migration] Will assume transactional DDL.
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | 0001 (head)
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tables: ['alembic_version', 'items']
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | INFO  [alembic.runtime.migration] Will assume transactional DDL.
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | INFO  [alembic.runtime.migration] Running downgrade 0001 -> , create items table
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | INFO  [alembic.runtime.migration] Will assume transactional DDL.
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | tables: ['alembic_version']
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   ✅  Success - Main Alembic upgrade head / downgrade base on real Postgres 17 [3.916306167s]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] ⭐ Run Main Upload test report and coverage
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | With the provided path, there will be 2 files uploaded
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | Artifact name is valid!
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | Root directory input is valid!
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | Beginning upload of artifact content to blob storage
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | Uploaded bytes 1675
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | Finished uploading artifact content to blob storage!
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | SHA256 digest of uploaded artifact zip is 3d4c77e5474a175001c0598f80ccd61543df2b2498b442d1aeb83dad28c63d7c
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | Finalizing artifact upload
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | Artifact backend-test-report.zip successfully finalized. Artifact ID 674919351
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | Artifact backend-test-report has been successfully uploaded! Final size is 1675 bytes. Artifact ID is 674919351
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/674919351
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   ✅  Success - Main Upload test report and coverage [1.171504459s]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] ⭐ Run Post actions/setup-python@v6
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   ✅  Success - Post actions/setup-python@v6 [215.268834ms]
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] ⭐ Run Complete job
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] Cleaning up container for job Backend - lint, test, migrations
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] Cleaning up services for job Backend - lint, test, migrations
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] Cleaning up network for job Backend - lint, test, migrations, and network name is: act-S21-Final-Project--Campus-Lost--Found-Backend--lint-test-mi-d7b13b2e15896c1e88e378e49d8f59dda28baeccc57da69af64ae6a0550ad132-backend-test-network
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations]   ✅  Success - Complete job
[S21 Final Project - Campus Lost & Found/Backend - lint, test, migrations] 🏁  Job succeeded
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ] ⭐ Run Set up job
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ] ⭐ Run Set up job
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ] ⭐ Run Set up job
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ] ⭐ Run Set up job
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   ✅  Success - Set up job
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   ✅  Success - Set up job
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   ✅  Success - Set up job
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   ✅  Success - Set up job
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   ☁  git clone 'https://github.com/actions/setup-node' # ref=v6
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ] ⭐ Run Main actions/checkout@v6
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ] ⭐ Run Main actions/checkout@v6
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ] ⭐ Run Main actions/checkout@v6
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ] ⭐ Run Main actions/checkout@v6
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   ✅  Success - Main actions/checkout@v6 [7.026205083s]
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   ✅  Success - Main actions/checkout@v6 [7.52815s]
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   ✅  Success - Main actions/checkout@v6 [7.430531583s]
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ] ⭐ Run Main actions/setup-python@v6
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ] ⭐ Run Main Install gitleaks (pinned, checksum verified)
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ] ⭐ Run Main actions/setup-python@v6
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   ✅  Success - Main actions/checkout@v6 [7.854466s]
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ] ⭐ Run Main docker build both images
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | installed gitleaks (arm64, sha256 verified) -> /root/.local/bin/gitleaks
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   ✅  Success - Main Install gitleaks (pinned, checksum verified) [2.417145791s]
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ] ⭐ Run Main gitleaks over final-devops-project/ only
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #0 building with "default" instance using docker driver
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #1 [internal] load build definition from backend.Dockerfile
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #1 transferring dockerfile:
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | 6:50PM INF scanned ~132184 bytes (132.18 KB) in 175ms
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | 6:50PM INF no leaks found
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   ✅  Success - Main gitleaks over final-devops-project/ only [1.499584375s]
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ] ⭐ Run Main actions/upload-artifact@v5
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #1 transferring dockerfile: 1.55kB 0.0s done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #1 DONE 0.2s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #2 [internal] load metadata for docker.io/library/python:3.13-slim
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #2 DONE 0.2s
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   | Successfully set up CPython (3.13.16)
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Successfully set up CPython (3.13.16)
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   ✅  Success - Main actions/setup-python@v6 [4.642470541s]
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   ✅  Success - Main actions/setup-python@v6 [4.580760709s]
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #3 [internal] load .dockerignore
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #3 transferring context: 111B 0.0s done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #3 DONE 0.1s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #4 [internal] load build context
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ] ⭐ Run Main actions/setup-node@v6
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ] ⭐ Run Main bandit -r app (any finding fails the job)
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #4 transferring context: 17.96kB 0.0s done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #4 DONE 0.1s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #5 [deps 1/4] FROM docker.io/library/python:3.13-slim@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #5 resolve docker.io/library/python:3.13-slim@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c 0.1s done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #5 CACHED
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #6 [deps 2/4] RUN python -m venv /opt/venv
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #6 CACHED
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #7 [deps 3/4] COPY requirements.txt .
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #7 CACHED
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #8 [deps 4/4] RUN pip install -r requirements.txt && pip uninstall -y pip
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #8 CACHED
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #9 [stage-1 2/9] RUN /usr/local/bin/python3 -m pip uninstall -y --root-user-action=ignore pip
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | With the provided path, there will be 1 file uploaded
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | Artifact name is valid!
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | Root directory input is valid!
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | Beginning upload of artifact content to blob storage
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | Uploaded bytes 145
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | Finished uploading artifact content to blob storage!
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | SHA256 digest of uploaded artifact zip is c7824b997ae4071b2464b61376266269c7a217ae2a2e9a40e4b3465248a5afa0
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | Finalizing artifact upload
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | Artifact report-secrets.zip successfully finalized. Artifact ID 3564946595
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | Artifact report-secrets has been successfully uploaded! Final size is 145 bytes. Artifact ID is 3564946595
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/3564946595
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   ✅  Success - Main actions/upload-artifact@v5 [6.044386542s]
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ] ⭐ Run Complete job
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ] Cleaning up container for job Secret scan (gitleaks)
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | [main]	INFO	profile include tests: None
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | [main]	INFO	profile exclude tests: None
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | [main]	INFO	cli include tests: None
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | [main]	INFO	cli exclude tests: None
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | [json]	INFO	JSON output written to file: reports/bandit.json
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #9 8.054 Found existing installation: pip 26.2.1
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | [main]	INFO	profile include tests: None
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | [main]	INFO	profile exclude tests: None
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | [main]	INFO	cli include tests: None
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | [main]	INFO	cli exclude tests: None
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | [main]	INFO	using config: ../../security/bandit.yaml
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | [main]	INFO	running on Python 3.13.16
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ]   ✅  Success - Complete job
[S21 Final Project - Campus Lost & Found/Secret scan (gitleaks)          ] 🏁  Job succeeded
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #9 8.198 Uninstalling pip-26.2.1:
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Run started:2026-10-07 18:50:45.962195+00:00
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Test results:
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 	No issues identified.
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Code scanned:
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 	Total lines of code: 306
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 	Total lines skipped (#nosec): 0
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 	Total potential issues skipped due to specifically being disabled (e.g., #nosec BXXX): 0
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Run metrics:
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 	Total issues (by severity):
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 		Undefined: 0
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 		Low: 0
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 		Medium: 0
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 		High: 0
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 	Total issues (by confidence):
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 		Undefined: 0
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 		Low: 0
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 		Medium: 0
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | 		High: 0
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Files skipped (0):
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   ✅  Success - Main bandit -r app (any finding fails the job) [8.470449542s]
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ] ⭐ Run Main actions/upload-artifact@v5
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   | Found in cache @ /opt/hostedtoolcache/node/22.23.3/arm64
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #9 8.913   Successfully uninstalled pip-26.2.1
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #9 DONE 9.3s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #10 [stage-1 3/9] RUN groupadd --gid 10001 app && useradd --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   | node: v22.23.3
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   | npm: 10.9.9
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   | yarn: 
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   ✅  Success - Main actions/setup-node@v6 [9.869018041s]
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ] ⭐ Run Main pip-audit on the pinned backend requirements
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #10 DONE 0.9s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #11 [stage-1 4/9] WORKDIR /app
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #11 DONE 0.1s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #12 [stage-1 5/9] COPY --from=deps /opt/venv /opt/venv
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | With the provided path, there will be 1 file uploaded
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Artifact name is valid!
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Root directory input is valid!
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Beginning upload of artifact content to blob storage
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Uploaded bytes 427
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Finished uploading artifact content to blob storage!
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | SHA256 digest of uploaded artifact zip is fe7f33b0464960b12b646b63545925ae57e5348ccd2a378448ca075d299fab3e
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Finalizing artifact upload
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Artifact report-sast.zip successfully finalized. Artifact ID 862344689
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Artifact report-sast has been successfully uploaded! Final size is 427 bytes. Artifact ID is 862344689
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/862344689
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   ✅  Success - Main actions/upload-artifact@v5 [2.535788125s]
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ] ⭐ Run Post actions/setup-python@v6
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   ✅  Success - Post actions/setup-python@v6 [380.924917ms]
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ] ⭐ Run Complete job
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ] Cleaning up container for job SAST (Bandit)
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ]   ✅  Success - Complete job
[S21 Final Project - Campus Lost & Found/SAST (Bandit)                   ] 🏁  Job succeeded
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #12 DONE 2.1s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #13 [stage-1 6/9] COPY alembic.ini ./
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #13 DONE 0.1s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #14 [stage-1 7/9] COPY alembic ./alembic
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #14 DONE 0.1s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #15 [stage-1 8/9] COPY app ./app
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #15 DONE 0.1s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #16 [stage-1 9/9] COPY --chmod=755 entrypoint.sh ./
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #16 DONE 0.1s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #17 exporting to image
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #17 exporting layers
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #17 exporting layers 3.1s done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #17 exporting manifest sha256:7d7cbcba9c2ba23891b50d13c9fc7ee7074effe7c09010f11a231e2b70655244 done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #17 exporting config sha256:b821333e19d0d196a2d53b49b4bc68fdb5abd28f2457d19d3db5732f72c907eb done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #17 naming to docker.io/library/lostfound-backend:888cd81 done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #17 unpacking to docker.io/library/lostfound-backend:888cd81
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #17 unpacking to docker.io/library/lostfound-backend:888cd81 0.6s done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #17 DONE 3.7s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #0 building with "default" instance using docker driver
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #1 [internal] load build definition from frontend.Dockerfile
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #1 transferring dockerfile: 1.12kB done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #1 DONE 0.0s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #2 [internal] load metadata for docker.io/library/node:22-alpine
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #2 DONE 0.1s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #3 [internal] load metadata for docker.io/nginxinc/nginx-unprivileged:1.29-alpine
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #3 DONE 0.1s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #4 [internal] load .dockerignore
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #4 transferring context: 60B done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #4 DONE 0.1s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #5 [internal] load build context
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #5 DONE 0.0s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #6 [stage-1 1/4] FROM docker.io/nginxinc/nginx-unprivileged:1.29-alpine@sha256:0c79d56aee561a1d81c63f00eee5fb5fe29279560cdc55e91425133104c7fbe6
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #6 resolve docker.io/nginxinc/nginx-unprivileged:1.29-alpine@sha256:0c79d56aee561a1d81c63f00eee5fb5fe29279560cdc55e91425133104c7fbe6
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #6 resolve docker.io/nginxinc/nginx-unprivileged:1.29-alpine@sha256:0c79d56aee561a1d81c63f00eee5fb5fe29279560cdc55e91425133104c7fbe6 0.1s done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #6 DONE 0.1s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #7 [build 1/6] FROM docker.io/library/node:22-alpine@sha256:0a7108bf6c7bf5de370ffb1a3ed6be93d405b43ff159f681a8d18c0e2bc2e402
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #7 resolve docker.io/library/node:22-alpine@sha256:0a7108bf6c7bf5de370ffb1a3ed6be93d405b43ff159f681a8d18c0e2bc2e402 0.1s done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #7 DONE 0.1s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #5 [internal] load build context
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #5 transferring context: 41.20kB done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #5 DONE 0.0s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #8 [stage-1 3/4] COPY nginx.conf.template /etc/nginx/templates/default.conf.template
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #8 CACHED
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #9 [build 4/6] RUN npm ci --no-audit --no-fund
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #9 CACHED
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #10 [build 5/6] COPY . .
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #10 CACHED
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #11 [build 6/6] RUN npm run build
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #11 CACHED
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #12 [build 2/6] WORKDIR /src
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #12 CACHED
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #13 [build 3/6] COPY package.json package-lock.json ./
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #13 CACHED
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #14 [stage-1 2/4] RUN apk upgrade --no-cache
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #14 CACHED
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #15 [stage-1 4/4] COPY --from=build /src/dist /usr/share/nginx/html
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #15 CACHED
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | 
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #16 exporting to image
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #16 exporting layers done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #16 exporting manifest sha256:ae0fb218aa64bc43923b61cd2403626ee5ed424dba3c8248cc618069f834bf86 0.1s done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #16 exporting config sha256:976ae615b8c995453a808f35e1286d01594ac3e943cf08cdd27c004631a4f653
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #16 exporting config sha256:976ae615b8c995453a808f35e1286d01594ac3e943cf08cdd27c004631a4f653 0.0s done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #16 naming to docker.io/library/lostfound-frontend:888cd81 done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #16 unpacking to docker.io/library/lostfound-frontend:888cd81
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #16 unpacking to docker.io/library/lostfound-frontend:888cd81 0.2s done
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | #16 DONE 0.4s
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | IMAGE                        ID             DISK USAGE   CONTENT SIZE   EXTRA
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | lostfound-backend:888cd81    7d7cbcba9c2b        303MB         65.3MB        
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | lostfound-frontend:888cd81   ae0fb218aa64        112MB         32.4MB        
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | total 94M
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | -rw------- 1 root root 63M Oct  7 18:50 backend.tar
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | -rw------- 1 root root 31M Oct  7 18:50 frontend.tar
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   ✅  Success - Main docker build both images [26.38137125s]
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ] ⭐ Run Main actions/upload-artifact@v5
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | With the provided path, there will be 2 files uploaded
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Artifact name is valid!
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Root directory input is valid!
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Beginning upload of artifact content to blob storage
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Uploaded bytes 8388608
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Uploaded bytes 16777216
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Uploaded bytes 25165824
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Uploaded bytes 33554432
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Uploaded bytes 41943040
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   | No known vulnerabilities found
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   ✅  Success - Main pip-audit on the pinned backend requirements [15.555599s]
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ] ⭐ Run Main npm audit (fails on high or critical)
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Uploaded bytes 50331648
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Uploaded bytes 58720256
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Uploaded bytes 67108864
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Uploaded bytes 75497472
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Uploaded bytes 83886080
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   | found 0 vulnerabilities
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   ✅  Success - Main npm audit (fails on high or critical) [1.481287084s]
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ] ⭐ Run Post actions/setup-node@v6
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Uploaded bytes 92274688
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   ✅  Success - Post actions/setup-node@v6 [227.170708ms]
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ] ⭐ Run Post actions/setup-python@v6
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Uploaded bytes 97131489
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Finished uploading artifact content to blob storage!
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | SHA256 digest of uploaded artifact zip is 88fb41f12f2964f067a464e9b54b30ad26328df46605ffeac07f9000d58e55bc
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Finalizing artifact upload
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Artifact images.zip successfully finalized. Artifact ID 3520546475
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Artifact images has been successfully uploaded! Final size is 97131489 bytes. Artifact ID is 3520546475
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/3520546475
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   ✅  Success - Main actions/upload-artifact@v5 [5.695166666s]
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ] ⭐ Run Complete job
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ] Cleaning up container for job Docker build (tag = short SHA)
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   ✅  Success - Post actions/setup-python@v6 [291.830875ms]
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ] ⭐ Run Complete job
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ] Cleaning up container for job SCA (pip-audit + npm audit)
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ]   ✅  Success - Complete job
[S21 Final Project - Campus Lost & Found/Docker build (tag = short SHA)  ] 🏁  Job succeeded
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ]   ✅  Success - Complete job
[S21 Final Project - Campus Lost & Found/SCA (pip-audit + npm audit)     ] 🏁  Job succeeded
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ] ⭐ Run Set up job
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   ✅  Success - Set up job
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   ☁  git clone 'https://github.com/actions/download-artifact' # ref=v7
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ] ⭐ Run Main actions/checkout@v6
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   ✅  Success - Main actions/checkout@v6 [2.068207334s]
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ] ⭐ Run Main actions/download-artifact@v7
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Downloading single artifact
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Preparing to download the following artifacts:
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | - images (ID: 3520546475, Size: 96, Expected Digest: undefined)
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Redirecting to blob download url: http://100.128.166.254:34570/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/final-devops-project/dist
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | SHA256 digest of downloaded artifact is 88fb41f12f2964f067a464e9b54b30ad26328df46605ffeac07f9000d58e55bc
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Artifact download completed successfully.
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Total of 1 artifact(s) downloaded
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Download artifact has finished successfully
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   ✅  Success - Main actions/download-artifact@v7 [2.767173916s]
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ] ⭐ Run Main Install Trivy (pinned, checksum verified)
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | installed trivy (arm64, sha256 verified) -> /root/.local/bin/trivy
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   ✅  Success - Main Install Trivy (pinned, checksum verified) [9.911987875s]
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ] ⭐ Run Main Trivy - HIGH,CRITICAL with a fix available fails the job
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | === backend image (lostfound-backend:888cd81) ===
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | 
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Report Summary
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | 
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ┌──────────────────────────────────────────────────────────────────────────────────┬────────────┬─────────────────┐
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │                                      Target                                      │    Type    │ Vulnerabilities │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ dist/backend.tar (debian 13.7)                                                   │   debian   │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/alembic-1.20.0.dist-info/METADATA          │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/annotated_doc-0.0.5.dist-info/METADATA     │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/annotated_types-0.8.0.dist-info/METADATA   │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/anyio-4.15.1.dist-info/METADATA            │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/click-8.5.0.dist-info/METADATA             │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/fastapi-0.142.2.dist-info/METADATA         │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/h11-0.16.0.dist-info/METADATA              │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/idna-3.20.dist-info/METADATA               │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/mako-1.4.3.dist-info/METADATA              │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/markupsafe-3.0.4.dist-info/METADATA        │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/opentelemetry_api-1.45.1.dist-info/METADA- │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ TA                                                                               │            │                 │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/prometheus_client-0.26.0.dist-info/METADA- │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ TA                                                                               │            │                 │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/psycopg-3.3.6.dist-info/METADATA           │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/psycopg_binary-3.3.6.dist-info/METADATA    │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/pydantic-2.13.5.dist-info/METADATA         │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/pydantic_core-2.46.5.dist-info/METADATA    │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/sqlalchemy-2.1.4.dist-info/METADATA        │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/starlette-1.7.0.dist-info/METADATA         │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/typing_extensions-4.16.0.dist-info/METADA- │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ TA                                                                               │            │                 │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/typing_inspection-0.4.4.dist-info/METADATA │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├──────────────────────────────────────────────────────────────────────────────────┼────────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ opt/venv/lib/python3.13/site-packages/uvicorn-0.54.0.dist-info/METADATA          │ python-pkg │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | └──────────────────────────────────────────────────────────────────────────────────┴────────────┴─────────────────┘
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Legend:
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | - '-': Not scanned
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | - '0': Clean (no security findings detected)
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | 
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | === frontend image (lostfound-frontend:888cd81) ===
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | 
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Report Summary
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | 
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ┌───────────────────────────────────┬────────┬─────────────────┐
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │              Target               │  Type  │ Vulnerabilities │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | ├───────────────────────────────────┼────────┼─────────────────┤
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | │ dist/frontend.tar (alpine 3.23.4) │ alpine │        0        │
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | └───────────────────────────────────┴────────┴─────────────────┘
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Legend:
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | - '-': Not scanned
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | - '0': Clean (no security findings detected)
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | 
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   ✅  Success - Main Trivy - HIGH,CRITICAL with a fix available fails the job [27.623150542s]
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ] ⭐ Run Main actions/upload-artifact@v5
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | With the provided path, there will be 2 files uploaded
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Artifact name is valid!
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Root directory input is valid!
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Beginning upload of artifact content to blob storage
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Uploaded bytes 1116
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Finished uploading artifact content to blob storage!
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | SHA256 digest of uploaded artifact zip is 8a1042badcd8f3e6de4a7fee9b414966943f89a5e3b9e51732d637098a6c286c
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Finalizing artifact upload
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Artifact report-image-scan.zip successfully finalized. Artifact ID 501775323
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Artifact report-image-scan has been successfully uploaded! Final size is 1116 bytes. Artifact ID is 501775323
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/501775323
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   ✅  Success - Main actions/upload-artifact@v5 [1.637080792s]
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ] ⭐ Run Complete job
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ] Cleaning up container for job Image scan (Trivy)
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ]   ✅  Success - Complete job
[S21 Final Project - Campus Lost & Found/Image scan (Trivy)              ] 🏁  Job succeeded
[S21 Final Project - Campus Lost & Found/Security gate                   ] ⭐ Run Set up job
[S21 Final Project - Campus Lost & Found/Security gate                   ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S21 Final Project - Campus Lost & Found/Security gate                   ]   ✅  Success - Set up job
[S21 Final Project - Campus Lost & Found/Security gate                   ] ⭐ Run Main Every check must be green
[S21 Final Project - Campus Lost & Found/Security gate                   ]   | CHECK          TOOL                     FAILS ON                               RESULT   GATE
[S21 Final Project - Campus Lost & Found/Security gate                   ]   | Unit tests     pytest + alembic         any failing test or migration          success  PASS
[S21 Final Project - Campus Lost & Found/Security gate                   ]   | Frontend       npm ci + vite build      build error                            success  PASS
[S21 Final Project - Campus Lost & Found/Security gate                   ]   | SAST           bandit 1.9.4             any finding in app/                    success  PASS
[S21 Final Project - Campus Lost & Found/Security gate                   ]   | SCA            pip-audit + npm audit    any Python vuln; npm high/critical     success  PASS
[S21 Final Project - Campus Lost & Found/Security gate                   ]   | Secrets        gitleaks 8.30.1          any leak                               success  PASS
[S21 Final Project - Campus Lost & Found/Security gate                   ]   | Build          docker build             build error                            success  PASS
[S21 Final Project - Campus Lost & Found/Security gate                   ]   | Image scan     trivy 0.74.0             HIGH/CRITICAL with a fix               success  PASS
[S21 Final Project - Campus Lost & Found/Security gate                   ]   | gate open
[S21 Final Project - Campus Lost & Found/Security gate                   ]   ✅  Success - Main Every check must be green [130.872792ms]
[S21 Final Project - Campus Lost & Found/Security gate                   ]   ⚙  Summary - ### Security gate - commit `888cd81`

| Check | Tool | Fails on | Job result | Gate |
|---|---|---|---|---|
| Unit tests | pytest + alembic | any failing test or migration | `success` | **PASS** |
| Frontend | npm ci + vite build | build error | `success` | **PASS** |
| SAST | bandit 1.9.4 | any finding in app/ | `success` | **PASS** |
| SCA | pip-audit + npm audit | any Python vuln; npm high/critical | `success` | **PASS** |
| Secrets | gitleaks 8.30.1 | any leak | `success` | **PASS** |
| Build | docker build | build error | `success` | **PASS** |
| Image scan | trivy 0.74.0 | HIGH/CRITICAL with a fix | `success` | **PASS** |

Gate **open** - images may be pushed.
[S21 Final Project - Campus Lost & Found/Security gate                   ] ⭐ Run Complete job
[S21 Final Project - Campus Lost & Found/Security gate                   ] Cleaning up container for job Security gate
[S21 Final Project - Campus Lost & Found/Security gate                   ]   ✅  Success - Complete job
[S21 Final Project - Campus Lost & Found/Security gate                   ] 🏁  Job succeeded
[S21 Final Project - Campus Lost & Found/Push images                     ] ⭐ Run Set up job
[S21 Final Project - Campus Lost & Found/Push images                     ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S21 Final Project - Campus Lost & Found/Push images                     ]   ✅  Success - Set up job
[S21 Final Project - Campus Lost & Found/Push images                     ]   ☁  git clone 'https://github.com/actions/download-artifact' # ref=v7
[S21 Final Project - Campus Lost & Found/Push images                     ]   ☁  git clone 'https://github.com/docker/login-action' # ref=v4
[S21 Final Project - Campus Lost & Found/Push images                     ] ⭐ Run Main actions/checkout@v6
[S21 Final Project - Campus Lost & Found/Push images                     ]   ✅  Success - Main actions/checkout@v6 [1.776104083s]
[S21 Final Project - Campus Lost & Found/Push images                     ] ⭐ Run Main actions/download-artifact@v7
[S21 Final Project - Campus Lost & Found/Push images                     ]   | Downloading single artifact
[S21 Final Project - Campus Lost & Found/Push images                     ]   | Preparing to download the following artifacts:
[S21 Final Project - Campus Lost & Found/Push images                     ]   | - images (ID: 3520546475, Size: 96, Expected Digest: undefined)
[S21 Final Project - Campus Lost & Found/Push images                     ]   | Redirecting to blob download url: http://100.128.166.254:34570/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S21 Final Project - Campus Lost & Found/Push images                     ]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/final-devops-project/dist
[S21 Final Project - Campus Lost & Found/Push images                     ]   | SHA256 digest of downloaded artifact is 88fb41f12f2964f067a464e9b54b30ad26328df46605ffeac07f9000d58e55bc
[S21 Final Project - Campus Lost & Found/Push images                     ]   | Artifact download completed successfully.
[S21 Final Project - Campus Lost & Found/Push images                     ]   | Total of 1 artifact(s) downloaded
[S21 Final Project - Campus Lost & Found/Push images                     ]   | Download artifact has finished successfully
[S21 Final Project - Campus Lost & Found/Push images                     ]   ✅  Success - Main actions/download-artifact@v7 [1.833471417s]
[S21 Final Project - Campus Lost & Found/Push images                     ] ⭐ Run Main Push the scanned images
[S21 Final Project - Campus Lost & Found/Push images                     ]   | Loaded image: lostfound-backend:888cd81
[S21 Final Project - Campus Lost & Found/Push images                     ]   | The push refers to repository [127.0.0.1:5057/bypratyush/lostfound-backend]
[S21 Final Project - Campus Lost & Found/Push images                     ]   | 06e46a800cec: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | a332d4f41a6b: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | 1a1fdf765ce7: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | 6989a8b2c7ac: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | 43ff2d8d3819: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | b9364f134827: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | 74202e18a58b: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | 7cbd17afacbc: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | a2c5ac708d8b: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | e41644b4b81a: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | 5df6da6a35be: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | bbeda6b4abb7: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | 888cd81: digest: sha256:7d7cbcba9c2ba23891b50d13c9fc7ee7074effe7c09010f11a231e2b70655244 size: 2566
[S21 Final Project - Campus Lost & Found/Push images                     ]   | pushed 127.0.0.1:5057/bypratyush/lostfound-backend:888cd81 (sha256:7d7cbcba9c2ba23891b50d13c9fc7ee7074effe7c09010f11a231e2b70655244)
[S21 Final Project - Campus Lost & Found/Push images                     ]   | Loaded image: lostfound-frontend:888cd81
[S21 Final Project - Campus Lost & Found/Push images                     ]   | The push refers to repository [127.0.0.1:5057/bypratyush/lostfound-frontend]
[S21 Final Project - Campus Lost & Found/Push images                     ]   | efe71cce129c: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | f80a6b970ac4: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | d27683448c0c: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | 2e8f0db82156: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | efd9363af940: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | 08fa14c2bd6c: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | a7f61ceba4c6: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | 8f2bc8b5e1fa: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | d17f077ada11: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | f9acf50bb7d8: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | b3dde35da7c0: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | 99b282e43958: Pushed
[S21 Final Project - Campus Lost & Found/Push images                     ]   | 888cd81: digest: sha256:ae0fb218aa64bc43923b61cd2403626ee5ed424dba3c8248cc618069f834bf86 size: 2568
[S21 Final Project - Campus Lost & Found/Push images                     ]   | pushed 127.0.0.1:5057/bypratyush/lostfound-frontend:888cd81 (sha256:ae0fb218aa64bc43923b61cd2403626ee5ed424dba3c8248cc618069f834bf86)
[S21 Final Project - Campus Lost & Found/Push images                     ]   ✅  Success - Main Push the scanned images [2.267018584s]
[S21 Final Project - Campus Lost & Found/Push images                     ]   ⚙  Summary - | Image | Digest |
|---|---|
| `127.0.0.1:5057/bypratyush/lostfound-backend:888cd81` | `sha256:7d7cbcba9c2ba23891b50d13c9fc7ee7074effe7c09010f11a231e2b70655244` |
| `127.0.0.1:5057/bypratyush/lostfound-frontend:888cd81` | `sha256:ae0fb218aa64bc43923b61cd2403626ee5ed424dba3c8248cc618069f834bf86` |
[S21 Final Project - Campus Lost & Found/Push images                     ] ⭐ Run Complete job
[S21 Final Project - Campus Lost & Found/Push images                     ] Cleaning up container for job Push images
[S21 Final Project - Campus Lost & Found/Push images                     ]   ✅  Success - Complete job
[S21 Final Project - Campus Lost & Found/Push images                     ] 🏁  Job succeeded

act exit code: 0

==============================================================
STEP 3 - job results
==============================================================
  Frontend - npm ci + build: succeeded
  Backend - lint, test, migrations: succeeded
  Secret scan (gitleaks): succeeded
  SAST (Bandit): succeeded
  Docker build (tag = short SHA): succeeded
  SCA (pip-audit + npm audit): succeeded
  Image scan (Trivy): succeeded
  Security gate: succeeded
  Push images: succeeded
  Deploy (GitOps - bump image.tag for Argo CD): skipped (github.event.act is true)

==============================================================
STEP 4 - artifacts kept by act's artifact server
==============================================================
artifacts/1/backend-test-report/backend-test-report.zip
artifacts/1/frontend-dist/frontend-dist.zip
artifacts/1/images/images.zip
artifacts/1/report-image-scan/report-image-scan.zip
artifacts/1/report-sast/report-sast.zip
artifacts/1/report-secrets/report-secrets.zip

==============================================================
STEP 5 - what reached the registry (tagged with the short SHA, no :latest)
==============================================================
{"repositories":["bypratyush/lostfound-backend","bypratyush/lostfound-frontend"]}

{"name":"bypratyush/lostfound-backend","tags":["888cd81"]}

{"name":"bypratyush/lostfound-frontend","tags":["888cd81"]}

act containers left: 0
```
