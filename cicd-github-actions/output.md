# CI/CD with GitHub Actions - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh` on 2026-10-07, run locally with act 0.2.89. Two invocations, both verbatim:

1. `./run.sh all` - green CI, the deliberately failing CI run, CD blocked by the red run, then a CD attempt that **failed on a network timeout** while act was cloning `docker/login-action` from github.com (STEP 9; nothing was deployed, so STEP 10/11 show an empty result).
2. After adding `--action-offline-mode` (reuse the actions act had already cached): `./run.sh cd`, `./run.sh verify`, `./run.sh cleanup` - green CD and the deployed container.

## 1. `./run.sh all`

```text

==============================================================
STEP 1 - The jobs act found in the CI workflow
==============================================================
time="2026-10-07T23:53:38+05:30" level=info msg="Using docker host 'unix:///var/run/docker.sock', and daemon socket 'unix:///var/run/docker.sock'"
Stage  Job ID        Job name                                    Workflow name              Workflow file               Events                             
0      lint          Lint                                        S16 CI - grade calculator  cicd-github-actions-ci.yml  push,pull_request,workflow_dispatch
1      test          Test (Python ${{ matrix.python-version }})  S16 CI - grade calculator  cicd-github-actions-ci.yml  push,pull_request,workflow_dispatch
2      build         Build image                                 S16 CI - grade calculator  cicd-github-actions-ci.yml  push,pull_request,workflow_dispatch
3      verify-image  Verify image artifact                       S16 CI - grade calculator  cicd-github-actions-ci.yml  push,pull_request,workflow_dispatch

==============================================================
STEP 2 - Run the CI workflow (push event)
==============================================================
$ act push -W .github/workflows/cicd-github-actions-ci.yml -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest --container-architecture linux/arm64 \
      --artifact-server-path .act/artifacts --secret-file .secrets --rm 

time="2026-10-07T23:53:40+05:30" level=info msg="Using docker host 'unix:///var/run/docker.sock', and daemon socket 'unix:///var/run/docker.sock'"
time="2026-10-07T23:53:40+05:30" level=info msg="Start server on http://100.128.166.254:34567"
time="2026-10-07T23:53:40+05:30" level=info msg="deleted cache: &{ID:2 Key:setup-python-linux-arm64-24.04-ubuntu-python-3.12.15-pip-83e03b56e196981201cf7d652c994ee6813071c7f89ce913ec86c82a5960f11d Version:dc4f892d7358e35233e412252917e6c8e7bf9fdeb0aa86c0a09998b5a784f0af Size:14966326 Complete:true UsedAt:1791396774 CreatedAt:1791396515}" module=artifactcache
[S16 CI - grade calculator/Lint] ⭐ Run Set up job
[S16 CI - grade calculator/Lint] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S16 CI - grade calculator/Lint]   ✅  Success - Set up job
[S16 CI - grade calculator/Lint]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S16 CI - grade calculator/Lint] ⭐ Run Main Check out code
[S16 CI - grade calculator/Lint]   ✅  Success - Main Check out code [5.2213895s]
[S16 CI - grade calculator/Lint] ⭐ Run Main Set up Python
[S16 CI - grade calculator/Lint]   | Successfully set up CPython (3.13.16)
[S16 CI - grade calculator/Lint]   ✅  Success - Main Set up Python [5.513389042s]
[S16 CI - grade calculator/Lint] ⭐ Run Main Install ruff
[S16 CI - grade calculator/Lint]   ✅  Success - Main Install ruff [3.4042065s]
[S16 CI - grade calculator/Lint] ⭐ Run Main ruff check (pyflakes, pycodestyle, bugbear, bandit rules)
[S16 CI - grade calculator/Lint]   ✅  Success - Main ruff check (pyflakes, pycodestyle, bugbear, bandit rules) [1.124636166s]
[S16 CI - grade calculator/Lint] ⭐ Run Main ruff format --check
[S16 CI - grade calculator/Lint]   | 4 files already formatted
[S16 CI - grade calculator/Lint]   ✅  Success - Main ruff format --check [462.434125ms]
[S16 CI - grade calculator/Lint] ⭐ Run Post Set up Python
[S16 CI - grade calculator/Lint]   ✅  Success - Post Set up Python [1.303536833s]
[S16 CI - grade calculator/Lint] ⭐ Run Complete job
[S16 CI - grade calculator/Lint] Cleaning up container for job Lint
[S16 CI - grade calculator/Lint]   ✅  Success - Complete job
[S16 CI - grade calculator/Lint] 🏁  Job succeeded
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Set up job
[S16 CI - grade calculator/Test (Python 3.12)-1] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Set up job
[S16 CI - grade calculator/Test (Python 3.13)-2] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Set up job
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Set up job
[S16 CI - grade calculator/Test (Python 3.12)-1]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S16 CI - grade calculator/Test (Python 3.13)-2]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S16 CI - grade calculator/Test (Python 3.12)-1]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S16 CI - grade calculator/Test (Python 3.13)-2]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S16 CI - grade calculator/Test (Python 3.12)-1] 🧪  Matrix: map[python-version:3.12]
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Main Check out code
[S16 CI - grade calculator/Test (Python 3.13)-2] 🧪  Matrix: map[python-version:3.13]
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Main Check out code
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Main Check out code [7.503058291s]
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Main Set up Python 3.12
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Main Check out code [6.372689375s]
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Main Set up Python 3.13
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Successfully set up CPython (3.12.15)
[S16 CI - grade calculator/Test (Python 3.12)-1]   | [command]/opt/hostedtoolcache/Python/3.12.15/arm64/bin/pip cache dir
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Successfully set up CPython (3.13.16)
[S16 CI - grade calculator/Test (Python 3.13)-2]   | [command]/opt/hostedtoolcache/Python/3.13.16/arm64/bin/pip cache dir
[S16 CI - grade calculator/Test (Python 3.12)-1]   | /root/.cache/pip
[S16 CI - grade calculator/Test (Python 3.13)-2]   | /root/.cache/pip
[S16 CI - grade calculator/Test (Python 3.12)-1]   ⚙  ***
[S16 CI - grade calculator/Test (Python 3.13)-2]   ⚙  ***
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Cache Size: ~4 MB (4253929 B)
[S16 CI - grade calculator/Test (Python 3.13)-2]   | [command]/usr/bin/tar -xf /tmp/99966600-e787-44f8-b7d7-0717e85c8ed6/cache.tzst -P -C /Users/pratyushmohanty/Devops-assignment --use-compress-program unzstd
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Cache restored successfully
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Cache restored from key: setup-python-linux-arm64-24.04-ubuntu-python-3.13.16-pip-83e03b56e196981201cf7d652c994ee6813071c7f89ce913ec86c82a5960f11d
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Cache Size: ~14 MB (14964785 B)
[S16 CI - grade calculator/Test (Python 3.12)-1]   | [command]/usr/bin/tar -xf /tmp/1925f6f4-5d47-4d7b-99cf-0ddf4f37d23e/cache.tzst -P -C /Users/pratyushmohanty/Devops-assignment --use-compress-program unzstd
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Main Set up Python 3.13 [8.958030542s]
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Cache restored successfully
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Cache restored from key: setup-python-linux-arm64-24.04-ubuntu-python-3.12.15-pip-83e03b56e196981201cf7d652c994ee6813071c7f89ce913ec86c82a5960f11d
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Main Set up Python 3.12 [13.031605042s]
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Main Install dependencies
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Main Install dependencies
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Main Install dependencies [6.261626292s]
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Main Install dependencies [7.35909575s]
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Main Run unit tests with coverage
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Main Run unit tests with coverage
[S16 CI - grade calculator/Test (Python 3.13)-2]   | ============================= test session starts ==============================
[S16 CI - grade calculator/Test (Python 3.13)-2]   | platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0
[S16 CI - grade calculator/Test (Python 3.13)-2]   | rootdir: /Users/pratyushmohanty/Devops-assignment/cicd-github-actions
[S16 CI - grade calculator/Test (Python 3.13)-2]   | configfile: pyproject.toml
[S16 CI - grade calculator/Test (Python 3.13)-2]   | testpaths: tests
[S16 CI - grade calculator/Test (Python 3.13)-2]   | plugins: cov-7.1.0
[S16 CI - grade calculator/Test (Python 3.13)-2]   | collected 38 items
[S16 CI - grade calculator/Test (Python 3.13)-2]   | 
[S16 CI - grade calculator/Test (Python 3.13)-2]   | tests/test_api.py ...........                                            [ 28%]
[S16 CI - grade calculator/Test (Python 3.12)-1]   | ============================= test session starts ==============================
[S16 CI - grade calculator/Test (Python 3.12)-1]   | platform linux -- Python 3.12.15, pytest-9.1.1, pluggy-1.6.0
[S16 CI - grade calculator/Test (Python 3.12)-1]   | rootdir: /Users/pratyushmohanty/Devops-assignment/cicd-github-actions
[S16 CI - grade calculator/Test (Python 3.12)-1]   | configfile: pyproject.toml
[S16 CI - grade calculator/Test (Python 3.12)-1]   | testpaths: tests
[S16 CI - grade calculator/Test (Python 3.12)-1]   | plugins: cov-7.1.0
[S16 CI - grade calculator/Test (Python 3.12)-1]   | collected 38 items
[S16 CI - grade calculator/Test (Python 3.12)-1]   | 
[S16 CI - grade calculator/Test (Python 3.13)-2]   | tests/test_grading.py ...........................                        [100%]
[S16 CI - grade calculator/Test (Python 3.13)-2]   | 
[S16 CI - grade calculator/Test (Python 3.13)-2]   | - generated xml file: /Users/pratyushmohanty/Devops-assignment/cicd-github-actions/reports/junit.xml -
[S16 CI - grade calculator/Test (Python 3.13)-2]   | ================================ tests coverage ================================
[S16 CI - grade calculator/Test (Python 3.13)-2]   | _______________ coverage: platform linux, python 3.13.16-final-0 _______________
[S16 CI - grade calculator/Test (Python 3.13)-2]   | 
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Name              Stmts   Miss Branch BrPart  Cover   Missing
[S16 CI - grade calculator/Test (Python 3.13)-2]   | -------------------------------------------------------------
[S16 CI - grade calculator/Test (Python 3.13)-2]   | app/__init__.py      43      0      6      0   100%
[S16 CI - grade calculator/Test (Python 3.13)-2]   | app/grading.py       36      0     16      0   100%
[S16 CI - grade calculator/Test (Python 3.13)-2]   | -------------------------------------------------------------
[S16 CI - grade calculator/Test (Python 3.13)-2]   | TOTAL                79      0     22      0   100%
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Coverage XML written to file reports/coverage.xml
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Required test coverage of 90% reached. Total coverage: 100.00%
[S16 CI - grade calculator/Test (Python 3.13)-2]   | ============================== 38 passed in 0.97s ==============================
[S16 CI - grade calculator/Test (Python 3.12)-1]   | tests/test_api.py ...........                                            [ 28%]
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Main Run unit tests with coverage [3.67705575s]
[S16 CI - grade calculator/Test (Python 3.12)-1]   | tests/test_grading.py ...........................                        [100%]
[S16 CI - grade calculator/Test (Python 3.12)-1]   | 
[S16 CI - grade calculator/Test (Python 3.12)-1]   | - generated xml file: /Users/pratyushmohanty/Devops-assignment/cicd-github-actions/reports/junit.xml -
[S16 CI - grade calculator/Test (Python 3.12)-1]   | ================================ tests coverage ================================
[S16 CI - grade calculator/Test (Python 3.12)-1]   | _______________ coverage: platform linux, python 3.12.15-final-0 _______________
[S16 CI - grade calculator/Test (Python 3.12)-1]   | 
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Name              Stmts   Miss Branch BrPart  Cover   Missing
[S16 CI - grade calculator/Test (Python 3.12)-1]   | -------------------------------------------------------------
[S16 CI - grade calculator/Test (Python 3.12)-1]   | app/__init__.py      43      0      6      0   100%
[S16 CI - grade calculator/Test (Python 3.12)-1]   | app/grading.py       36      0     16      0   100%
[S16 CI - grade calculator/Test (Python 3.12)-1]   | -------------------------------------------------------------
[S16 CI - grade calculator/Test (Python 3.12)-1]   | TOTAL                79      0     22      0   100%
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Coverage XML written to file reports/coverage.xml
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Required test coverage of 90% reached. Total coverage: 100.00%
[S16 CI - grade calculator/Test (Python 3.12)-1]   | ============================== 38 passed in 1.28s ==============================
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Main Upload test report and coverage
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Main Run unit tests with coverage [3.962212417s]
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Main Upload test report and coverage
[S16 CI - grade calculator/Test (Python 3.12)-1]   | (node:97) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
[S16 CI - grade calculator/Test (Python 3.12)-1]   | (Use `node --trace-deprecation ...` to show where the warning was created)
[S16 CI - grade calculator/Test (Python 3.13)-2]   | (node:101) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
[S16 CI - grade calculator/Test (Python 3.13)-2]   | (Use `node --trace-deprecation ...` to show where the warning was created)
[S16 CI - grade calculator/Test (Python 3.12)-1]   | With the provided path, there will be 2 files uploaded
[S16 CI - grade calculator/Test (Python 3.13)-2]   | With the provided path, there will be 2 files uploaded
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Artifact name is valid!
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Root directory input is valid!
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Artifact name is valid!
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Root directory input is valid!
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Beginning upload of artifact content to blob storage
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Beginning upload of artifact content to blob storage
[S16 CI - grade calculator/Test (Python 3.13)-2]   | (node:101) [DEP0169] DeprecationWarning: `url.parse()` behavior is not standardized and prone to errors that have security implications. Use the WHATWG URL API instead. CVEs are not issued for `url.parse()` vulnerabilities.
[S16 CI - grade calculator/Test (Python 3.12)-1]   | (node:97) [DEP0169] DeprecationWarning: `url.parse()` behavior is not standardized and prone to errors that have security implications. Use the WHATWG URL API instead. CVEs are not issued for `url.parse()` vulnerabilities.
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Uploaded bytes 1533
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Uploaded bytes 1543
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Finished uploading artifact content to blob storage!
[S16 CI - grade calculator/Test (Python 3.12)-1]   | SHA256 digest of uploaded artifact zip is a1e8f71600d1d45dc88d58c97cdcb0e12c56f8e449fb9756655dda168be6be00
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Finalizing artifact upload
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Finished uploading artifact content to blob storage!
[S16 CI - grade calculator/Test (Python 3.13)-2]   | SHA256 digest of uploaded artifact zip is 49744f470d51f3cddcb4811ebfaf555f4b77c3d2577f61082a737c340975dbd1
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Finalizing artifact upload
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Artifact test-report-py3.12.zip successfully finalized. Artifact ID 3323523448
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Artifact test-report-py3.12 has been successfully uploaded! Final size is 1533 bytes. Artifact ID is 3323523448
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/3323523448
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Artifact test-report-py3.13.zip successfully finalized. Artifact ID 3340301067
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Artifact test-report-py3.13 has been successfully uploaded! Final size is 1543 bytes. Artifact ID is 3340301067
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/3340301067
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Main Upload test report and coverage [4.604804125s]
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Main Upload test report and coverage [5.700152209s]
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Post Set up Python 3.13
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Post Set up Python 3.12
[S16 CI - grade calculator/Test (Python 3.12)-1]   | [command]/usr/bin/tar --posix -cf cache.tzst --exclude cache.tzst -P -C /Users/pratyushmohanty/Devops-assignment --files-from manifest.txt --use-compress-program zstdmt
[S16 CI - grade calculator/Test (Python 3.13)-2]   | [command]/usr/bin/tar --posix -cf cache.tzst --exclude cache.tzst -P -C /Users/pratyushmohanty/Devops-assignment --files-from manifest.txt --use-compress-program zstdmt
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Cache Size: ~4 MB (4253932 B)
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Cache saved successfully
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Cache saved with the key: setup-python-Linux-arm64-24.04-Ubuntu-python-3.13.16-pip-83e03b56e196981201cf7d652c994ee6813071c7f89ce913ec86c82a5960f11d
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Post Set up Python 3.13 [2.000186167s]
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Complete job
[S16 CI - grade calculator/Test (Python 3.13)-2] Cleaning up container for job Test (Python 3.13)
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Cache Size: ~14 MB (14965101 B)
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Cache saved successfully
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Cache saved with the key: setup-python-Linux-arm64-24.04-Ubuntu-python-3.12.15-pip-83e03b56e196981201cf7d652c994ee6813071c7f89ce913ec86c82a5960f11d
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Post Set up Python 3.12 [3.115254916s]
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Complete job
[S16 CI - grade calculator/Test (Python 3.12)-1] Cleaning up container for job Test (Python 3.12)
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Complete job
[S16 CI - grade calculator/Test (Python 3.13)-2] 🏁  Job succeeded
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Complete job
[S16 CI - grade calculator/Test (Python 3.12)-1] 🏁  Job succeeded
[S16 CI - grade calculator/Build image         ] ⭐ Run Set up job
[S16 CI - grade calculator/Build image         ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S16 CI - grade calculator/Build image         ]   ✅  Success - Set up job
[S16 CI - grade calculator/Build image         ]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S16 CI - grade calculator/Build image         ] ⭐ Run Main Check out code
[S16 CI - grade calculator/Build image         ]   ✅  Success - Main Check out code [6.502017375s]
[S16 CI - grade calculator/Build image         ] ⭐ Run Main Work out the image tag
[S16 CI - grade calculator/Build image         ]   | Image will be grade-calculator:888cd81
[S16 CI - grade calculator/Build image         ]   ✅  Success - Main Work out the image tag [148.117791ms]
[S16 CI - grade calculator/Build image         ] ⭐ Run Main docker build
[S16 CI - grade calculator/Build image         ]   | #0 building with "default" instance using docker driver
[S16 CI - grade calculator/Build image         ]   | 
[S16 CI - grade calculator/Build image         ]   | #1 [internal] load build definition from Dockerfile
[S16 CI - grade calculator/Build image         ]   | #1 transferring dockerfile:
[S16 CI - grade calculator/Build image         ]   | #1 transferring dockerfile: 1.29kB 0.0s done
[S16 CI - grade calculator/Build image         ]   | #1 DONE 0.2s
[S16 CI - grade calculator/Build image         ]   | 
[S16 CI - grade calculator/Build image         ]   | #2 [internal] load metadata for docker.io/library/python:3.13-slim
[S16 CI - grade calculator/Build image         ]   | #2 DONE 0.0s
[S16 CI - grade calculator/Build image         ]   | 
[S16 CI - grade calculator/Build image         ]   | #3 [internal] load .dockerignore
[S16 CI - grade calculator/Build image         ]   | #3 transferring context:
[S16 CI - grade calculator/Build image         ]   | #3 transferring context: 318B done
[S16 CI - grade calculator/Build image         ]   | #3 DONE 0.0s
[S16 CI - grade calculator/Build image         ]   | 
[S16 CI - grade calculator/Build image         ]   | #4 [internal] load build context
[S16 CI - grade calculator/Build image         ]   | #4 transferring context: 4.72kB 0.0s done
[S16 CI - grade calculator/Build image         ]   | #4 DONE 0.1s
[S16 CI - grade calculator/Build image         ]   | 
[S16 CI - grade calculator/Build image         ]   | #5 [1/6] FROM docker.io/library/python:3.13-slim@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c
[S16 CI - grade calculator/Build image         ]   | #5 resolve docker.io/library/python:3.13-slim@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c 0.1s done
[S16 CI - grade calculator/Build image         ]   | #5 DONE 0.1s
[S16 CI - grade calculator/Build image         ]   | 
[S16 CI - grade calculator/Build image         ]   | #6 [5/6] RUN groupadd --gid 10001 app  && useradd --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app
[S16 CI - grade calculator/Build image         ]   | #6 CACHED
[S16 CI - grade calculator/Build image         ]   | 
[S16 CI - grade calculator/Build image         ]   | #7 [3/6] COPY requirements.txt .
[S16 CI - grade calculator/Build image         ]   | #7 CACHED
[S16 CI - grade calculator/Build image         ]   | 
[S16 CI - grade calculator/Build image         ]   | #8 [4/6] RUN pip install -r requirements.txt
[S16 CI - grade calculator/Build image         ]   | #8 CACHED
[S16 CI - grade calculator/Build image         ]   | 
[S16 CI - grade calculator/Build image         ]   | #9 [2/6] WORKDIR /srv
[S16 CI - grade calculator/Build image         ]   | #9 CACHED
[S16 CI - grade calculator/Build image         ]   | 
[S16 CI - grade calculator/Build image         ]   | #10 [6/6] COPY app/ app/
[S16 CI - grade calculator/Build image         ]   | #10 CACHED
[S16 CI - grade calculator/Build image         ]   | 
[S16 CI - grade calculator/Build image         ]   | #11 exporting to image
[S16 CI - grade calculator/Build image         ]   | #11 exporting layers 0.0s done
[S16 CI - grade calculator/Build image         ]   | #11 exporting manifest sha256:a8616af865acf597f9a8fb0364b13c23b0ce2248fe53c746a3f52ef6d52b8714 done
[S16 CI - grade calculator/Build image         ]   | #11 exporting config sha256:09249bfe2054fb0aaecca03018b8d0bcd7a7ad607583104f12acca4155e799df done
[S16 CI - grade calculator/Build image         ]   | #11 exporting attestation manifest sha256:85557b1f89a6e139cb69870e118632a399b6aaf04472d6c36f44e6440b6937d7 0.1s done
[S16 CI - grade calculator/Build image         ]   | #11 exporting manifest list sha256:9cdbad625f3c7f3add2e45f20d313b89affae6b5d15e84b9015e59ec09a7a3fe
[S16 CI - grade calculator/Build image         ]   | #11 exporting manifest list sha256:9cdbad625f3c7f3add2e45f20d313b89affae6b5d15e84b9015e59ec09a7a3fe 0.1s done
[S16 CI - grade calculator/Build image         ]   | #11 naming to docker.io/library/grade-calculator:888cd81 done
[S16 CI - grade calculator/Build image         ]   | #11 unpacking to docker.io/library/grade-calculator:888cd81
[S16 CI - grade calculator/Build image         ]   | #11 unpacking to docker.io/library/grade-calculator:888cd81 0.0s done
[S16 CI - grade calculator/Build image         ]   | #11 DONE 0.4s
[S16 CI - grade calculator/Build image         ]   | IMAGE                      ID             DISK USAGE   CONTENT SIZE   EXTRA
[S16 CI - grade calculator/Build image         ]   | grade-calculator:888cd81   9cdbad625f3c        212MB         45.6MB        
[S16 CI - grade calculator/Build image         ]   ✅  Success - Main docker build [3.852008334s]
[S16 CI - grade calculator/Build image         ] ⭐ Run Main Save image as a tarball
[S16 CI - grade calculator/Build image         ]   | total 44M
[S16 CI - grade calculator/Build image         ]   | -rw-r--r-- 1 root root 44M Oct  7 18:25 grade-calculator.tar.gz
[S16 CI - grade calculator/Build image         ]   ✅  Success - Main Save image as a tarball [4.8425445s]
[S16 CI - grade calculator/Build image         ] ⭐ Run Main Upload image artifact
[S16 CI - grade calculator/Build image         ]   | (node:126) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
[S16 CI - grade calculator/Build image         ]   | (Use `node --trace-deprecation ...` to show where the warning was created)
[S16 CI - grade calculator/Build image         ]   | With the provided path, there will be 1 file uploaded
[S16 CI - grade calculator/Build image         ]   | Artifact name is valid!
[S16 CI - grade calculator/Build image         ]   | Root directory input is valid!
[S16 CI - grade calculator/Build image         ]   | Beginning upload of artifact content to blob storage
[S16 CI - grade calculator/Build image         ]   | (node:126) [DEP0169] DeprecationWarning: `url.parse()` behavior is not standardized and prone to errors that have security implications. Use the WHATWG URL API instead. CVEs are not issued for `url.parse()` vulnerabilities.
[S16 CI - grade calculator/Build image         ]   | Uploaded bytes 8388608
[S16 CI - grade calculator/Build image         ]   | Uploaded bytes 16777216
[S16 CI - grade calculator/Build image         ]   | Uploaded bytes 25165824
[S16 CI - grade calculator/Build image         ]   | Uploaded bytes 33554432
[S16 CI - grade calculator/Build image         ]   | Uploaded bytes 41943040
[S16 CI - grade calculator/Build image         ]   | Uploaded bytes 45111534
[S16 CI - grade calculator/Build image         ]   | Finished uploading artifact content to blob storage!
[S16 CI - grade calculator/Build image         ]   | SHA256 digest of uploaded artifact zip is 67293e4c8ddc9235b3130652e132a6b465f46ada91a836c21718905dab8c039a
[S16 CI - grade calculator/Build image         ]   | Finalizing artifact upload
[S16 CI - grade calculator/Build image         ]   | Artifact image-grade-calculator.zip successfully finalized. Artifact ID 3443597459
[S16 CI - grade calculator/Build image         ]   | Artifact image-grade-calculator has been successfully uploaded! Final size is 45111534 bytes. Artifact ID is 3443597459
[S16 CI - grade calculator/Build image         ]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/3443597459
[S16 CI - grade calculator/Build image         ]   ✅  Success - Main Upload image artifact [10.370535125s]
[S16 CI - grade calculator/Build image         ] ⭐ Run Complete job
[S16 CI - grade calculator/Build image         ] Cleaning up container for job Build image
[S16 CI - grade calculator/Build image         ]   ✅  Success - Complete job
[S16 CI - grade calculator/Build image         ] 🏁  Job succeeded
[S16 CI - grade calculator/Verify image artifact] ⭐ Run Set up job
[S16 CI - grade calculator/Verify image artifact] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S16 CI - grade calculator/Verify image artifact]   ✅  Success - Set up job
[S16 CI - grade calculator/Verify image artifact]   ☁  git clone 'https://github.com/actions/download-artifact' # ref=v7
[S16 CI - grade calculator/Verify image artifact] ⭐ Run Main Check out code
[S16 CI - grade calculator/Verify image artifact]   ✅  Success - Main Check out code [11.519442667s]
[S16 CI - grade calculator/Verify image artifact] ⭐ Run Main Download the image built by the previous job
[S16 CI - grade calculator/Verify image artifact]   | Downloading single artifact
[S16 CI - grade calculator/Verify image artifact]   | Preparing to download the following artifacts:
[S16 CI - grade calculator/Verify image artifact]   | - image-grade-calculator (ID: 3443597459, Size: 96, Expected Digest: undefined)
[S16 CI - grade calculator/Verify image artifact]   | Redirecting to blob download url: http://100.128.166.254:34567/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S16 CI - grade calculator/Verify image artifact]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/cicd-github-actions/dist
[S16 CI - grade calculator/Verify image artifact]   | (node:31) [DEP0005] DeprecationWarning: Buffer() is deprecated due to security and usability issues. Please use the Buffer.alloc(), Buffer.allocUnsafe(), or Buffer.from() methods instead.
[S16 CI - grade calculator/Verify image artifact]   | (Use `node --trace-deprecation ...` to show where the warning was created)
[S16 CI - grade calculator/Verify image artifact]   | SHA256 digest of downloaded artifact is 67293e4c8ddc9235b3130652e132a6b465f46ada91a836c21718905dab8c039a
[S16 CI - grade calculator/Verify image artifact]   | Artifact download completed successfully.
[S16 CI - grade calculator/Verify image artifact]   | Total of 1 artifact(s) downloaded
[S16 CI - grade calculator/Verify image artifact]   | Download artifact has finished successfully
[S16 CI - grade calculator/Verify image artifact]   ✅  Success - Main Download the image built by the previous job [10.291184958s]
[S16 CI - grade calculator/Verify image artifact] ⭐ Run Main docker load
[S16 CI - grade calculator/Verify image artifact]   | total 44M
[S16 CI - grade calculator/Verify image artifact]   | -rw-r--r-- 1 root root 44M Oct  7 18:26 grade-calculator.tar.gz
[S16 CI - grade calculator/Verify image artifact]   | Loaded image: grade-calculator:888cd81
[S16 CI - grade calculator/Verify image artifact]   ✅  Success - Main docker load [2.332532084s]
[S16 CI - grade calculator/Verify image artifact] ⭐ Run Main Start the container
[S16 CI - grade calculator/Verify image artifact]   | 282e7c443ddfcfd101a9f906030de9ff134afe7ea59afc803900bdad305f3cd6
[S16 CI - grade calculator/Verify image artifact]   ✅  Success - Main Start the container [1.9972315s]
[S16 CI - grade calculator/Verify image artifact] ⭐ Run Main Smoke test
[S16 CI - grade calculator/Verify image artifact]   | --- waiting for the Docker HEALTHCHECK to report healthy
[S16 CI - grade calculator/Verify image artifact]   | health status: healthy (after ~4s)
[S16 CI - grade calculator/Verify image artifact]   | container s16-ci-verify is at http://172.17.0.4:8080
[S16 CI - grade calculator/Verify image artifact]   | --- endpoints
[S16 CI - grade calculator/Verify image artifact]   |   GET /health                                  HTTP 200  {"status":"ok"}
[S16 CI - grade calculator/Verify image artifact]   |   GET /version                                 HTTP 200  {"commit":"888cd817ad3fcef35caa73374366c0af95030157","version":"1.2.0"}
[S16 CI - grade calculator/Verify image artifact]   |   image was built from the expected commit
[S16 CI - grade calculator/Verify image artifact]   |   GET /api/grade?score=91                      HTTP 200  {"grade":"O","points":10,"score":91.0}
[S16 CI - grade calculator/Verify image artifact]   |   GET /api/grade?score=abc (bad)               HTTP 400  {"error":"score must be a number"}
[S16 CI - grade calculator/Verify image artifact]   |   POST /api/sgpa                               HTTP 200  {"courses":[{"credits":4,"grade":"O","name":"DevOps","points":10},{"credits":3,"grade":"A","name":"DBMS","poin
[S16 CI - grade calculator/Verify image artifact]   | --- container hardening
[S16 CI - grade calculator/Verify image artifact]   |   process runs as uid 10001
[S16 CI - grade calculator/Verify image artifact]   | --- secret-protected endpoint
[S16 CI - grade calculator/Verify image artifact]   |   ADMIN_API_KEY secret is present (30 chars)
[S16 CI - grade calculator/Verify image artifact]   |   GET /api/admin/stats (no key)                HTTP 401  {"error":"invalid or missing X-API-Key"}
[S16 CI - grade calculator/Verify image artifact]   |   GET /api/admin/stats (with key)              HTTP 200  {"pid":7,"requests_served":{"grade":1,"sgpa":1},"uptime_seconds":4.6}
[S16 CI - grade calculator/Verify image artifact]   | smoke test passed
[S16 CI - grade calculator/Verify image artifact]   ✅  Success - Main Smoke test [7.891644s]
[S16 CI - grade calculator/Verify image artifact] ⭐ Run Main Write job summary
[S16 CI - grade calculator/Verify image artifact]   ✅  Success - Main Write job summary [613.754917ms]
[S16 CI - grade calculator/Verify image artifact]   ⚙  Summary - ### Grade calculator - CI image check

| Item | Value |
|---|---|
| Image | `grade-calculator:888cd81` |
| Commit | `888cd817ad3fcef35caa73374366c0af95030157` |
| Size | 44M |
| Runs as | uid 10001 |
| Health | healthy |
[S16 CI - grade calculator/Verify image artifact] ⭐ Run Main Remove the container
[S16 CI - grade calculator/Verify image artifact]   | s16-ci-verify
[S16 CI - grade calculator/Verify image artifact]   ✅  Success - Main Remove the container [3.758257708s]
[S16 CI - grade calculator/Verify image artifact] ⭐ Run Complete job
[S16 CI - grade calculator/Verify image artifact] Cleaning up container for job Verify image artifact
[S16 CI - grade calculator/Verify image artifact]   ✅  Success - Complete job
[S16 CI - grade calculator/Verify image artifact] 🏁  Job succeeded

act exit code: 0

==============================================================
STEP 3 - Artifacts the CI run uploaded (act's artifact server on disk)
==============================================================
artifacts/1/image-grade-calculator/image-grade-calculator.zip
artifacts/1/test-report-py3.12/test-report-py3.12.zip
artifacts/1/test-report-py3.13/test-report-py3.13.zip

==============================================================
STEP 4 - Deliberately break the code: 90 is no longer an O grade
==============================================================
--- app/grading.py (original)	2026-10-07 23:56:36
+++ app/grading.py	2026-10-07 23:56:36
@@ -5,7 +5,7 @@
 
 # (minimum score, letter grade, grade points) - checked top to bottom
 GRADE_BANDS = [
-    (90, "O", 10),
+    (91, "O", 10),
     (80, "A+", 9),
     (70, "A", 8),
     (60, "B+", 7),

==============================================================
STEP 5 - Run CI against the broken code (expected: test jobs fail, build never starts)
==============================================================
$ act push -W .github/workflows/cicd-github-actions-ci.yml -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest --container-architecture linux/arm64 \
      --artifact-server-path .act/artifacts --secret-file .secrets --rm 

time="2026-10-07T23:56:36+05:30" level=info msg="Using docker host 'unix:///var/run/docker.sock', and daemon socket 'unix:///var/run/docker.sock'"
time="2026-10-07T23:56:37+05:30" level=info msg="Start server on http://100.128.166.254:34567"
[S16 CI - grade calculator/Lint] ⭐ Run Set up job
[S16 CI - grade calculator/Lint] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S16 CI - grade calculator/Lint]   ✅  Success - Set up job
[S16 CI - grade calculator/Lint]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S16 CI - grade calculator/Lint] ⭐ Run Main Check out code
[S16 CI - grade calculator/Lint]   ✅  Success - Main Check out code [2.567907583s]
[S16 CI - grade calculator/Lint] ⭐ Run Main Set up Python
[S16 CI - grade calculator/Lint]   | Successfully set up CPython (3.13.16)
[S16 CI - grade calculator/Lint]   ✅  Success - Main Set up Python [3.64246675s]
[S16 CI - grade calculator/Lint] ⭐ Run Main Install ruff
[S16 CI - grade calculator/Lint]   ✅  Success - Main Install ruff [1.37290275s]
[S16 CI - grade calculator/Lint] ⭐ Run Main ruff check (pyflakes, pycodestyle, bugbear, bandit rules)
[S16 CI - grade calculator/Lint]   ✅  Success - Main ruff check (pyflakes, pycodestyle, bugbear, bandit rules) [252.5035ms]
[S16 CI - grade calculator/Lint] ⭐ Run Main ruff format --check
[S16 CI - grade calculator/Lint]   | 4 files already formatted
[S16 CI - grade calculator/Lint]   ✅  Success - Main ruff format --check [190.829083ms]
[S16 CI - grade calculator/Lint] ⭐ Run Post Set up Python
[S16 CI - grade calculator/Lint]   ✅  Success - Post Set up Python [569.255792ms]
[S16 CI - grade calculator/Lint] ⭐ Run Complete job
[S16 CI - grade calculator/Lint] Cleaning up container for job Lint
[S16 CI - grade calculator/Lint]   ✅  Success - Complete job
[S16 CI - grade calculator/Lint] 🏁  Job succeeded
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Set up job
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Set up job
[S16 CI - grade calculator/Test (Python 3.12)-1] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S16 CI - grade calculator/Test (Python 3.13)-2] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Set up job
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Set up job
[S16 CI - grade calculator/Test (Python 3.13)-2]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S16 CI - grade calculator/Test (Python 3.12)-1]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S16 CI - grade calculator/Test (Python 3.13)-2]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S16 CI - grade calculator/Test (Python 3.12)-1]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S16 CI - grade calculator/Test (Python 3.13)-2] 🧪  Matrix: map[python-version:3.13]
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Main Check out code
[S16 CI - grade calculator/Test (Python 3.12)-1] 🧪  Matrix: map[python-version:3.12]
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Main Check out code
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Main Check out code [1.771877375s]
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Main Set up Python 3.13
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Main Check out code [2.609603791s]
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Main Set up Python 3.12
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Successfully set up CPython (3.13.16)
[S16 CI - grade calculator/Test (Python 3.13)-2]   | [command]/opt/hostedtoolcache/Python/3.13.16/arm64/bin/pip cache dir
[S16 CI - grade calculator/Test (Python 3.13)-2]   | /root/.cache/pip
[S16 CI - grade calculator/Test (Python 3.13)-2]   ⚙  ***
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Cache Size: ~4 MB (4253932 B)
[S16 CI - grade calculator/Test (Python 3.13)-2]   | [command]/usr/bin/tar -xf /tmp/66bb3004-0e75-4796-bbad-eac2ef1221a8/cache.tzst -P -C /Users/pratyushmohanty/Devops-assignment --use-compress-program unzstd
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Cache restored successfully
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Cache restored from key: setup-python-linux-arm64-24.04-ubuntu-python-3.13.16-pip-83e03b56e196981201cf7d652c994ee6813071c7f89ce913ec86c82a5960f11d
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Main Set up Python 3.13 [4.161819541s]
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Main Install dependencies
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Successfully set up CPython (3.12.15)
[S16 CI - grade calculator/Test (Python 3.12)-1]   | [command]/opt/hostedtoolcache/Python/3.12.15/arm64/bin/pip cache dir
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Main Install dependencies [986.277416ms]
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Main Run unit tests with coverage
[S16 CI - grade calculator/Test (Python 3.12)-1]   | /root/.cache/pip
[S16 CI - grade calculator/Test (Python 3.12)-1]   ⚙  ***
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Cache Size: ~14 MB (14965101 B)
[S16 CI - grade calculator/Test (Python 3.12)-1]   | [command]/usr/bin/tar -xf /tmp/acf1bce1-4779-4a14-addb-7add026a6c70/cache.tzst -P -C /Users/pratyushmohanty/Devops-assignment --use-compress-program unzstd
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Cache restored successfully
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Cache restored from key: setup-python-linux-arm64-24.04-ubuntu-python-3.12.15-pip-83e03b56e196981201cf7d652c994ee6813071c7f89ce913ec86c82a5960f11d
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Main Set up Python 3.12 [3.606960333s]
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Main Install dependencies
[S16 CI - grade calculator/Test (Python 3.13)-2]   | ============================= test session starts ==============================
[S16 CI - grade calculator/Test (Python 3.13)-2]   | platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0
[S16 CI - grade calculator/Test (Python 3.13)-2]   | rootdir: /Users/pratyushmohanty/Devops-assignment/cicd-github-actions
[S16 CI - grade calculator/Test (Python 3.13)-2]   | configfile: pyproject.toml
[S16 CI - grade calculator/Test (Python 3.13)-2]   | testpaths: tests
[S16 CI - grade calculator/Test (Python 3.13)-2]   | plugins: cov-7.1.0
[S16 CI - grade calculator/Test (Python 3.13)-2]   | collected 38 items
[S16 CI - grade calculator/Test (Python 3.13)-2]   | 
[S16 CI - grade calculator/Test (Python 3.13)-2]   | tests/test_api.py ...........                                            [ 28%]
[S16 CI - grade calculator/Test (Python 3.13)-2]   | tests/test_grading.py .F.........................                        [100%]
[S16 CI - grade calculator/Test (Python 3.13)-2]   | 
[S16 CI - grade calculator/Test (Python 3.13)-2]   | =================================== FAILURES ===================================
[S16 CI - grade calculator/Test (Python 3.13)-2]   | ___________________ test_grade_band_boundaries[90-expected1] ___________________
[S16 CI - grade calculator/Test (Python 3.13)-2]   | 
[S16 CI - grade calculator/Test (Python 3.13)-2]   | score = 90, expected = ('O', 10)
[S16 CI - grade calculator/Test (Python 3.13)-2]   | 
[S16 CI - grade calculator/Test (Python 3.13)-2]   |     @pytest.mark.parametrize(
[S16 CI - grade calculator/Test (Python 3.13)-2]   |         "score, expected",
[S16 CI - grade calculator/Test (Python 3.13)-2]   |         [
[S16 CI - grade calculator/Test (Python 3.13)-2]   |             (100, ("O", 10)),
[S16 CI - grade calculator/Test (Python 3.13)-2]   |             (90, ("O", 10)),
[S16 CI - grade calculator/Test (Python 3.13)-2]   |             (89.5, ("A+", 9)),
[S16 CI - grade calculator/Test (Python 3.13)-2]   |             (80, ("A+", 9)),
[S16 CI - grade calculator/Test (Python 3.13)-2]   |             (79, ("A", 8)),
[S16 CI - grade calculator/Test (Python 3.13)-2]   |             (60, ("B+", 7)),
[S16 CI - grade calculator/Test (Python 3.13)-2]   |             (50, ("B", 6)),
[S16 CI - grade calculator/Test (Python 3.13)-2]   |             (45, ("C", 5)),
[S16 CI - grade calculator/Test (Python 3.13)-2]   |             (40, ("P", 4)),
[S16 CI - grade calculator/Test (Python 3.13)-2]   |             (39.9, ("F", 0)),
[S16 CI - grade calculator/Test (Python 3.13)-2]   |             (0, ("F", 0)),
[S16 CI - grade calculator/Test (Python 3.13)-2]   |         ],
[S16 CI - grade calculator/Test (Python 3.13)-2]   |     )
[S16 CI - grade calculator/Test (Python 3.13)-2]   |     def test_grade_band_boundaries(score, expected):
[S16 CI - grade calculator/Test (Python 3.13)-2]   | >       assert grade_for(score) == expected
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E       AssertionError: assert ('A+', 9) == ('O', 10)
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E         
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E         At index 0 diff: 'A+' != 'O'
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E         
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E         Full diff:
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E           (
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E         -     'O',
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E         ?      ^
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E         +     'A+',
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E         ?      ^^
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E         -     10,
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E         ?     ^^
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E         +     9,
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E         ?     ^
[S16 CI - grade calculator/Test (Python 3.13)-2]   | E           )
[S16 CI - grade calculator/Test (Python 3.13)-2]   | 
[S16 CI - grade calculator/Test (Python 3.13)-2]   | tests/test_grading.py:23: AssertionError
[S16 CI - grade calculator/Test (Python 3.13)-2]   | - generated xml file: /Users/pratyushmohanty/Devops-assignment/cicd-github-actions/reports/junit.xml -
[S16 CI - grade calculator/Test (Python 3.13)-2]   | ================================ tests coverage ================================
[S16 CI - grade calculator/Test (Python 3.13)-2]   | _______________ coverage: platform linux, python 3.13.16-final-0 _______________
[S16 CI - grade calculator/Test (Python 3.13)-2]   | 
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Name              Stmts   Miss Branch BrPart  Cover   Missing
[S16 CI - grade calculator/Test (Python 3.13)-2]   | -------------------------------------------------------------
[S16 CI - grade calculator/Test (Python 3.13)-2]   | app/__init__.py      43      0      6      0   100%
[S16 CI - grade calculator/Test (Python 3.13)-2]   | app/grading.py       36      0     16      0   100%
[S16 CI - grade calculator/Test (Python 3.13)-2]   | -------------------------------------------------------------
[S16 CI - grade calculator/Test (Python 3.13)-2]   | TOTAL                79      0     22      0   100%
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Coverage XML written to file reports/coverage.xml
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Required test coverage of 90% reached. Total coverage: 100.00%
[S16 CI - grade calculator/Test (Python 3.13)-2]   | =========================== short test summary info ============================
[S16 CI - grade calculator/Test (Python 3.13)-2]   | FAILED tests/test_grading.py::test_grade_band_boundaries[90-expected1] - AssertionError: assert ('A+', 9) == ('O', 10)
[S16 CI - grade calculator/Test (Python 3.13)-2]   |   
[S16 CI - grade calculator/Test (Python 3.13)-2]   |   At index 0 diff: 'A+' != 'O'
[S16 CI - grade calculator/Test (Python 3.13)-2]   |   
[S16 CI - grade calculator/Test (Python 3.13)-2]   |   Full diff:
[S16 CI - grade calculator/Test (Python 3.13)-2]   |     (
[S16 CI - grade calculator/Test (Python 3.13)-2]   |   -     'O',
[S16 CI - grade calculator/Test (Python 3.13)-2]   |   ?      ^
[S16 CI - grade calculator/Test (Python 3.13)-2]   |   +     'A+',
[S16 CI - grade calculator/Test (Python 3.13)-2]   |   ?      ^^
[S16 CI - grade calculator/Test (Python 3.13)-2]   |   -     10,
[S16 CI - grade calculator/Test (Python 3.13)-2]   |   ?     ^^
[S16 CI - grade calculator/Test (Python 3.13)-2]   |   +     9,
[S16 CI - grade calculator/Test (Python 3.13)-2]   |   ?     ^
[S16 CI - grade calculator/Test (Python 3.13)-2]   |     )
[S16 CI - grade calculator/Test (Python 3.13)-2]   | ========================= 1 failed, 37 passed in 0.57s =========================
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Main Install dependencies [870.088458ms]
[S16 CI - grade calculator/Test (Python 3.13)-2]   ❌  Failure - Main Run unit tests with coverage [1.4847085s]
[S16 CI - grade calculator/Test (Python 3.13)-2] exitcode '1': failure
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Main Run unit tests with coverage
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Main Upload test report and coverage
[S16 CI - grade calculator/Test (Python 3.12)-1]   | ============================= test session starts ==============================
[S16 CI - grade calculator/Test (Python 3.12)-1]   | platform linux -- Python 3.12.15, pytest-9.1.1, pluggy-1.6.0
[S16 CI - grade calculator/Test (Python 3.12)-1]   | rootdir: /Users/pratyushmohanty/Devops-assignment/cicd-github-actions
[S16 CI - grade calculator/Test (Python 3.12)-1]   | configfile: pyproject.toml
[S16 CI - grade calculator/Test (Python 3.12)-1]   | testpaths: tests
[S16 CI - grade calculator/Test (Python 3.12)-1]   | plugins: cov-7.1.0
[S16 CI - grade calculator/Test (Python 3.12)-1]   | collected 38 items
[S16 CI - grade calculator/Test (Python 3.12)-1]   | 
[S16 CI - grade calculator/Test (Python 3.12)-1]   | tests/test_api.py ...........                                            [ 28%]
[S16 CI - grade calculator/Test (Python 3.12)-1]   | tests/test_grading.py .F.........................                        [100%]
[S16 CI - grade calculator/Test (Python 3.12)-1]   | 
[S16 CI - grade calculator/Test (Python 3.12)-1]   | =================================== FAILURES ===================================
[S16 CI - grade calculator/Test (Python 3.12)-1]   | ___________________ test_grade_band_boundaries[90-expected1] ___________________
[S16 CI - grade calculator/Test (Python 3.12)-1]   | 
[S16 CI - grade calculator/Test (Python 3.12)-1]   | score = 90, expected = ('O', 10)
[S16 CI - grade calculator/Test (Python 3.12)-1]   | 
[S16 CI - grade calculator/Test (Python 3.12)-1]   |     @pytest.mark.parametrize(
[S16 CI - grade calculator/Test (Python 3.12)-1]   |         "score, expected",
[S16 CI - grade calculator/Test (Python 3.12)-1]   |         [
[S16 CI - grade calculator/Test (Python 3.12)-1]   |             (100, ("O", 10)),
[S16 CI - grade calculator/Test (Python 3.12)-1]   |             (90, ("O", 10)),
[S16 CI - grade calculator/Test (Python 3.12)-1]   |             (89.5, ("A+", 9)),
[S16 CI - grade calculator/Test (Python 3.12)-1]   |             (80, ("A+", 9)),
[S16 CI - grade calculator/Test (Python 3.12)-1]   |             (79, ("A", 8)),
[S16 CI - grade calculator/Test (Python 3.12)-1]   |             (60, ("B+", 7)),
[S16 CI - grade calculator/Test (Python 3.12)-1]   |             (50, ("B", 6)),
[S16 CI - grade calculator/Test (Python 3.12)-1]   |             (45, ("C", 5)),
[S16 CI - grade calculator/Test (Python 3.12)-1]   |             (40, ("P", 4)),
[S16 CI - grade calculator/Test (Python 3.12)-1]   |             (39.9, ("F", 0)),
[S16 CI - grade calculator/Test (Python 3.12)-1]   |             (0, ("F", 0)),
[S16 CI - grade calculator/Test (Python 3.12)-1]   |         ],
[S16 CI - grade calculator/Test (Python 3.12)-1]   |     )
[S16 CI - grade calculator/Test (Python 3.12)-1]   |     def test_grade_band_boundaries(score, expected):
[S16 CI - grade calculator/Test (Python 3.12)-1]   | >       assert grade_for(score) == expected
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E       AssertionError: assert ('A+', 9) == ('O', 10)
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E         
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E         At index 0 diff: 'A+' != 'O'
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E         
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E         Full diff:
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E           (
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E         -     'O',
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E         ?      ^
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E         +     'A+',
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E         ?      ^^
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E         -     10,
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E         ?     ^^
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E         +     9,
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E         ?     ^
[S16 CI - grade calculator/Test (Python 3.12)-1]   | E           )
[S16 CI - grade calculator/Test (Python 3.12)-1]   | 
[S16 CI - grade calculator/Test (Python 3.12)-1]   | tests/test_grading.py:23: AssertionError
[S16 CI - grade calculator/Test (Python 3.12)-1]   | - generated xml file: /Users/pratyushmohanty/Devops-assignment/cicd-github-actions/reports/junit.xml -
[S16 CI - grade calculator/Test (Python 3.12)-1]   | ================================ tests coverage ================================
[S16 CI - grade calculator/Test (Python 3.12)-1]   | _______________ coverage: platform linux, python 3.12.15-final-0 _______________
[S16 CI - grade calculator/Test (Python 3.12)-1]   | 
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Name              Stmts   Miss Branch BrPart  Cover   Missing
[S16 CI - grade calculator/Test (Python 3.12)-1]   | -------------------------------------------------------------
[S16 CI - grade calculator/Test (Python 3.12)-1]   | app/__init__.py      43      0      6      0   100%
[S16 CI - grade calculator/Test (Python 3.12)-1]   | app/grading.py       36      0     16      0   100%
[S16 CI - grade calculator/Test (Python 3.12)-1]   | -------------------------------------------------------------
[S16 CI - grade calculator/Test (Python 3.12)-1]   | TOTAL                79      0     22      0   100%
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Coverage XML written to file reports/coverage.xml
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Required test coverage of 90% reached. Total coverage: 100.00%
[S16 CI - grade calculator/Test (Python 3.12)-1]   | =========================== short test summary info ============================
[S16 CI - grade calculator/Test (Python 3.12)-1]   | FAILED tests/test_grading.py::test_grade_band_boundaries[90-expected1] - AssertionError: assert ('A+', 9) == ('O', 10)
[S16 CI - grade calculator/Test (Python 3.12)-1]   |   
[S16 CI - grade calculator/Test (Python 3.12)-1]   |   At index 0 diff: 'A+' != 'O'
[S16 CI - grade calculator/Test (Python 3.12)-1]   |   
[S16 CI - grade calculator/Test (Python 3.12)-1]   |   Full diff:
[S16 CI - grade calculator/Test (Python 3.12)-1]   |     (
[S16 CI - grade calculator/Test (Python 3.12)-1]   |   -     'O',
[S16 CI - grade calculator/Test (Python 3.12)-1]   |   ?      ^
[S16 CI - grade calculator/Test (Python 3.12)-1]   |   +     'A+',
[S16 CI - grade calculator/Test (Python 3.12)-1]   |   ?      ^^
[S16 CI - grade calculator/Test (Python 3.12)-1]   |   -     10,
[S16 CI - grade calculator/Test (Python 3.12)-1]   |   ?     ^^
[S16 CI - grade calculator/Test (Python 3.12)-1]   |   +     9,
[S16 CI - grade calculator/Test (Python 3.12)-1]   |   ?     ^
[S16 CI - grade calculator/Test (Python 3.12)-1]   |     )
[S16 CI - grade calculator/Test (Python 3.12)-1]   | ========================= 1 failed, 37 passed in 1.01s =========================
[S16 CI - grade calculator/Test (Python 3.12)-1]   ❌  Failure - Main Run unit tests with coverage [2.180003708s]
[S16 CI - grade calculator/Test (Python 3.13)-2]   | (node:99) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
[S16 CI - grade calculator/Test (Python 3.13)-2]   | (Use `node --trace-deprecation ...` to show where the warning was created)
[S16 CI - grade calculator/Test (Python 3.13)-2]   | With the provided path, there will be 2 files uploaded
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Artifact name is valid!
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Root directory input is valid!
[S16 CI - grade calculator/Test (Python 3.12)-1] exitcode '1': failure
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Beginning upload of artifact content to blob storage
[S16 CI - grade calculator/Test (Python 3.13)-2]   | (node:99) [DEP0169] DeprecationWarning: `url.parse()` behavior is not standardized and prone to errors that have security implications. Use the WHATWG URL API instead. CVEs are not issued for `url.parse()` vulnerabilities.
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Uploaded bytes 1902
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Finished uploading artifact content to blob storage!
[S16 CI - grade calculator/Test (Python 3.13)-2]   | SHA256 digest of uploaded artifact zip is 298db3abf4e8a70fed8ea47e81bd094ab48fe5ee1e292f05df46e19695547510
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Finalizing artifact upload
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Artifact test-report-py3.13.zip successfully finalized. Artifact ID 3340301067
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Artifact test-report-py3.13 has been successfully uploaded! Final size is 1902 bytes. Artifact ID is 3340301067
[S16 CI - grade calculator/Test (Python 3.13)-2]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/3340301067
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Main Upload test report and coverage [2.547377709s]
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Main Upload test report and coverage
[S16 CI - grade calculator/Test (Python 3.13)-2] ⭐ Run Complete job
[S16 CI - grade calculator/Test (Python 3.13)-2] Cleaning up container for job Test (Python 3.13)
[S16 CI - grade calculator/Test (Python 3.13)-2]   ✅  Success - Complete job
[S16 CI - grade calculator/Test (Python 3.13)-2] 🏁  Job failed
[S16 CI - grade calculator/Test (Python 3.12)-1]   | (node:100) [DEP0040] DeprecationWarning: The `punycode` module is deprecated. Please use a userland alternative instead.
[S16 CI - grade calculator/Test (Python 3.12)-1]   | (Use `node --trace-deprecation ...` to show where the warning was created)
[S16 CI - grade calculator/Test (Python 3.12)-1]   | With the provided path, there will be 2 files uploaded
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Artifact name is valid!
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Root directory input is valid!
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Beginning upload of artifact content to blob storage
[S16 CI - grade calculator/Test (Python 3.12)-1]   | (node:100) [DEP0169] DeprecationWarning: `url.parse()` behavior is not standardized and prone to errors that have security implications. Use the WHATWG URL API instead. CVEs are not issued for `url.parse()` vulnerabilities.
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Uploaded bytes 1906
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Finished uploading artifact content to blob storage!
[S16 CI - grade calculator/Test (Python 3.12)-1]   | SHA256 digest of uploaded artifact zip is 4f38ce3767dc978bced0e81d9350f9101b097faff6c4d020aaf75eddb1b9f718
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Finalizing artifact upload
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Artifact test-report-py3.12.zip successfully finalized. Artifact ID 3323523448
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Artifact test-report-py3.12 has been successfully uploaded! Final size is 1906 bytes. Artifact ID is 3323523448
[S16 CI - grade calculator/Test (Python 3.12)-1]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/3323523448
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Main Upload test report and coverage [3.891615333s]
[S16 CI - grade calculator/Test (Python 3.12)-1] ⭐ Run Complete job
[S16 CI - grade calculator/Test (Python 3.12)-1] Cleaning up container for job Test (Python 3.12)
[S16 CI - grade calculator/Test (Python 3.12)-1]   ✅  Success - Complete job
[S16 CI - grade calculator/Test (Python 3.12)-1] 🏁  Job failed
Error: Job 'Test (Python ${{ matrix.python-version }})' failed

act exit code: 1

--- job results in this run
  Lint: succeeded
  Test (Python 3.13)-2: failed
  Test (Python 3.12)-1: failed
  Build image: never started
  Verify image artifact: never started

--- failing assertion, from the uploaded test report artifact
<testcase classname="tests.test_grading" name="test_grade_band_boundaries[90-expected1]"
<failure message="AssertionError: assert ('A+', 9) == ('O', 10)&#10;  &#10;  At index 0 diff: 'A+' != 'O'&#10;  &#10;  Full diff:&#10;    (&#10;  -     'O',&#10;  ?      ^&#10;  +     'A+',&#10;  ?      ^^&#10;  -     10,&#10;  ?     ^^&#10;  +     9,&#10;  ?     ^&#10;    )"

CI went red as intended (act exit code 1)

==============================================================
STEP 6 - Restore the file
==============================================================
8:    (90, "O", 10),

==============================================================
STEP 7 - CD after a FAILED CI run (workflow_run, conclusion=failure)
==============================================================
{
  "action": "completed",
  "workflow_run": {
    "name": "S16 CI - grade calculator",
    "event": "push",
    "head_branch": "main",
    "head_sha": "888cd817ad3fcef35caa73374366c0af95030157",
    "conclusion": "failure"
  }
}

$ act workflow_run -W .github/workflows/cicd-github-actions-cd.yml -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest --container-architecture linux/arm64 \
      --artifact-server-path .act/artifacts --secret-file .secrets --rm -e /Users/pratyushmohanty/Devops-assignment/cicd-github-actions/.act/workflow_run-failure.json

time="2026-10-07T23:57:15+05:30" level=info msg="Using docker host 'unix:///var/run/docker.sock', and daemon socket 'unix:///var/run/docker.sock'"
time="2026-10-07T23:57:16+05:30" level=info msg="Start server on http://100.128.166.254:34567"

act exit code: 0

no CD job ran: publish was skipped by its if:, so smoke-test and deploy (needs: publish) never started

==============================================================
STEP 8 - Start the local registry that stands in for ghcr.io
==============================================================
local registry: s16-registry registry:2 127.0.0.1:5055->5000/tcp

==============================================================
STEP 9 - CD after a GREEN CI run (workflow_run, conclusion=success)
==============================================================
{
  "action": "completed",
  "workflow_run": {
    "name": "S16 CI - grade calculator",
    "event": "push",
    "head_branch": "main",
    "head_sha": "888cd817ad3fcef35caa73374366c0af95030157",
    "conclusion": "success"
  }
}

$ act workflow_run -W .github/workflows/cicd-github-actions-cd.yml -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest --container-architecture linux/arm64 \
      --artifact-server-path .act/artifacts --secret-file .secrets --rm -e /Users/pratyushmohanty/Devops-assignment/cicd-github-actions/.act/workflow_run-success.json

time="2026-10-07T23:57:17+05:30" level=info msg="Using docker host 'unix:///var/run/docker.sock', and daemon socket 'unix:///var/run/docker.sock'"
time="2026-10-07T23:57:17+05:30" level=info msg="Start server on http://100.128.166.254:34567"
[S16 CD - grade calculator/Build and push image] ⭐ Run Set up job
[S16 CD - grade calculator/Build and push image] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S16 CD - grade calculator/Build and push image]   ✅  Success - Set up job
[S16 CD - grade calculator/Build and push image]   ☁  git clone 'https://github.com/actions/checkout' # ref=v6
[S16 CD - grade calculator/Build and push image]   ☁  git clone 'https://github.com/docker/login-action' # ref=v4
[S16 CD - grade calculator/Build and push image] ⭐ Run Main Check out the local working tree (act only)
[S16 CD - grade calculator/Build and push image]   ✅  Success - Main Check out the local working tree (act only) [1.513240042s]
[S16 CD - grade calculator/Build and push image] ⭐ Run Main Work out image name and tags
[S16 CD - grade calculator/Build and push image]   | Publishing localhost:5055/bypratyush/grade-calculator:888cd81 (commit 888cd817ad3fcef35caa73374366c0af95030157)
[S16 CD - grade calculator/Build and push image]   ✅  Success - Main Work out image name and tags [117.486958ms]
[S16 CD - grade calculator/Build and push image] ⭐ Run Main docker build
[S16 CD - grade calculator/Build and push image]   | #0 building with "default" instance using docker driver
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #1 [internal] load build definition from Dockerfile
[S16 CD - grade calculator/Build and push image]   | #1 transferring dockerfile: 1.29kB done
[S16 CD - grade calculator/Build and push image]   | #1 DONE 0.0s
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #2 [internal] load metadata for docker.io/library/python:3.13-slim
[S16 CD - grade calculator/Build and push image]   | #2 DONE 0.1s
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #3 [internal] load .dockerignore
[S16 CD - grade calculator/Build and push image]   | #3 transferring context: 318B done
[S16 CD - grade calculator/Build and push image]   | #3 DONE 0.0s
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #4 [internal] load build context
[S16 CD - grade calculator/Build and push image]   | #4 transferring context: 4.72kB 0.0s done
[S16 CD - grade calculator/Build and push image]   | #4 DONE 0.2s
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #5 [1/6] FROM docker.io/library/python:3.13-slim@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c
[S16 CD - grade calculator/Build and push image]   | #5 resolve docker.io/library/python:3.13-slim@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c 0.1s done
[S16 CD - grade calculator/Build and push image]   | #5 DONE 0.1s
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #6 [2/6] WORKDIR /srv
[S16 CD - grade calculator/Build and push image]   | #6 CACHED
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #7 [3/6] COPY requirements.txt .
[S16 CD - grade calculator/Build and push image]   | #7 CACHED
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #8 [4/6] RUN pip install -r requirements.txt
[S16 CD - grade calculator/Build and push image]   | #8 CACHED
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #9 [5/6] RUN groupadd --gid 10001 app  && useradd --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app
[S16 CD - grade calculator/Build and push image]   | #9 CACHED
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #10 [6/6] COPY app/ app/
[S16 CD - grade calculator/Build and push image]   | #10 CACHED
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #11 exporting to image
[S16 CD - grade calculator/Build and push image]   | #11 exporting layers 0.0s done
[S16 CD - grade calculator/Build and push image]   | #11 exporting manifest sha256:a8616af865acf597f9a8fb0364b13c23b0ce2248fe53c746a3f52ef6d52b8714 done
[S16 CD - grade calculator/Build and push image]   | #11 exporting config sha256:09249bfe2054fb0aaecca03018b8d0bcd7a7ad607583104f12acca4155e799df
[S16 CD - grade calculator/Build and push image]   | #11 exporting config sha256:09249bfe2054fb0aaecca03018b8d0bcd7a7ad607583104f12acca4155e799df done
[S16 CD - grade calculator/Build and push image]   | #11 exporting attestation manifest sha256:80a82932d02675a83e19fd5fd76b8c3f2bbfdca2f1f385d90776674e56ed77a3 0.1s done
[S16 CD - grade calculator/Build and push image]   | #11 exporting manifest list sha256:68443814e3110ea9b52f0539bc26e25ddf7d96898dc0f2106ded012aea570471
[S16 CD - grade calculator/Build and push image]   | #11 exporting manifest list sha256:68443814e3110ea9b52f0539bc26e25ddf7d96898dc0f2106ded012aea570471 0.0s done
[S16 CD - grade calculator/Build and push image]   | #11 naming to localhost:5055/bypratyush/grade-calculator:888cd81 done
[S16 CD - grade calculator/Build and push image]   | #11 unpacking to localhost:5055/bypratyush/grade-calculator:888cd81 0.1s done
[S16 CD - grade calculator/Build and push image]   | #11 naming to localhost:5055/bypratyush/grade-calculator:latest 0.0s done
[S16 CD - grade calculator/Build and push image]   | #11 unpacking to localhost:5055/bypratyush/grade-calculator:latest 0.0s done
[S16 CD - grade calculator/Build and push image]   | #11 DONE 0.5s
[S16 CD - grade calculator/Build and push image]   ✅  Success - Main docker build [2.503890084s]
[S16 CD - grade calculator/Build and push image] ⭐ Run Main docker push
[S16 CD - grade calculator/Build and push image]   | The push refers to repository [localhost:5055/bypratyush/grade-calculator]
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Pushed
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Pushed
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Pushed
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Pushed
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Pushed
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Pushed
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Pushed
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Pushed
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Pushed
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Pushed
[S16 CD - grade calculator/Build and push image]   | 888cd81: digest: sha256:68443814e3110ea9b52f0539bc26e25ddf7d96898dc0f2106ded012aea570471 size: 856
[S16 CD - grade calculator/Build and push image]   | The push refers to repository [localhost:5055/bypratyush/grade-calculator]
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Layer already exists
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Layer already exists
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Layer already exists
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Layer already exists
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Layer already exists
[S16 CD - grade calculator/Build and push image]   | b6cce3bd20b0: Already exists
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Layer already exists
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Layer already exists
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Layer already exists
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Layer already exists
[S16 CD - grade calculator/Build and push image]   | latest: digest: sha256:68443814e3110ea9b52f0539bc26e25ddf7d96898dc0f2106ded012aea570471 size: 856
[S16 CD - grade calculator/Build and push image]   | pushed localhost:5055/bypratyush/grade-calculator@sha256:68443814e3110ea9b52f0539bc26e25ddf7d96898dc0f2106ded012aea570471
[S16 CD - grade calculator/Build and push image]   ✅  Success - Main docker push [1.915683458s]
[S16 CD - grade calculator/Build and push image] ⭐ Run Complete job
[S16 CD - grade calculator/Build and push image] Cleaning up container for job Build and push image
[S16 CD - grade calculator/Build and push image]   ✅  Success - Complete job
[S16 CD - grade calculator/Build and push image] 🏁  Job succeeded
[S16 CD - grade calculator/Smoke-test pushed image] ⭐ Run Set up job
[S16 CD - grade calculator/Smoke-test pushed image] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S16 CD - grade calculator/Smoke-test pushed image]   ✅  Success - Set up job
[S16 CD - grade calculator/Smoke-test pushed image]   ☁  git clone 'https://github.com/docker/login-action' # ref=v4
[S16 CD - grade calculator/Smoke-test pushed image] Get "https://github.com/docker/login-action/info/refs?service=git-upload-pack": read tcp 100.128.166.254:50496->20.207.73.82:443: read: operation timed out
[S16 CD - grade calculator/Smoke-test pushed image] ⭐ Run Complete job
[S16 CD - grade calculator/Smoke-test pushed image] Cleaning up container for job Smoke-test pushed image
[S16 CD - grade calculator/Smoke-test pushed image]   ✅  Success - Complete job
[S16 CD - grade calculator/Smoke-test pushed image] 🏁  Job failed
Error: Get "https://github.com/docker/login-action/info/refs?service=git-upload-pack": read tcp 100.128.166.254:50496->20.207.73.82:443: read: operation timed out

act exit code: 1

==============================================================
STEP 10 - What is in the registry now
==============================================================
{"repositories":["bypratyush/grade-calculator"]}

{"name":"bypratyush/grade-calculator","tags":["888cd81","latest"]}


==============================================================
STEP 11 - The deployed 'production' container, called from the Mac
==============================================================
NAMES     IMAGE     STATUS    PORTS

$ curl localhost:18716/version

$ curl 'localhost:18716/api/grade?score=78'


==============================================================
CLEANUP - deployed container, local registry, images built by the runs
==============================================================
s16-registry
left behind by act: 1 containers
```

## 2. `./run.sh cd && ./run.sh verify && ./run.sh cleanup`

```text

==============================================================
STEP 8 - Start the local registry that stands in for ghcr.io
==============================================================
local registry: s16-registry registry:2 127.0.0.1:5055->5000/tcp

==============================================================
STEP 9 - CD after a GREEN CI run (workflow_run, conclusion=success)
==============================================================
{
  "action": "completed",
  "workflow_run": {
    "name": "S16 CI - grade calculator",
    "event": "push",
    "head_branch": "main",
    "head_sha": "888cd817ad3fcef35caa73374366c0af95030157",
    "conclusion": "success"
  }
}

$ act workflow_run -W .github/workflows/cicd-github-actions-cd.yml -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest --container-architecture linux/arm64 \
      --artifact-server-path .act/artifacts --secret-file .secrets --rm -e /Users/pratyushmohanty/Devops-assignment/cicd-github-actions/.act/workflow_run-success.json

time="2026-10-07T23:59:28+05:30" level=info msg="Using docker host 'unix:///var/run/docker.sock', and daemon socket 'unix:///var/run/docker.sock'"
time="2026-10-07T23:59:29+05:30" level=info msg="Start server on http://100.128.166.254:34567"
[S16 CD - grade calculator/Build and push image] ⭐ Run Set up job
[S16 CD - grade calculator/Build and push image] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S16 CD - grade calculator/Build and push image]   ✅  Success - Set up job
[S16 CD - grade calculator/Build and push image]   ☁  git clone 'https://github.com/actions/checkout' # ref=v6
[S16 CD - grade calculator/Build and push image]   ☁  git clone 'https://github.com/docker/login-action' # ref=v4
[S16 CD - grade calculator/Build and push image] ⭐ Run Main Check out the local working tree (act only)
[S16 CD - grade calculator/Build and push image]   ✅  Success - Main Check out the local working tree (act only) [2.355913875s]
[S16 CD - grade calculator/Build and push image] ⭐ Run Main Work out image name and tags
[S16 CD - grade calculator/Build and push image]   | Publishing localhost:5055/bypratyush/grade-calculator:888cd81 (commit 888cd817ad3fcef35caa73374366c0af95030157)
[S16 CD - grade calculator/Build and push image]   ✅  Success - Main Work out image name and tags [170.682791ms]
[S16 CD - grade calculator/Build and push image] ⭐ Run Main docker build
[S16 CD - grade calculator/Build and push image]   | #0 building with "default" instance using docker driver
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #1 [internal] load build definition from Dockerfile
[S16 CD - grade calculator/Build and push image]   | #1 transferring dockerfile: 1.29kB done
[S16 CD - grade calculator/Build and push image]   | #1 DONE 0.0s
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #2 [internal] load metadata for docker.io/library/python:3.13-slim
[S16 CD - grade calculator/Build and push image]   | #2 DONE 0.0s
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #3 [internal] load .dockerignore
[S16 CD - grade calculator/Build and push image]   | #3 transferring context: 318B done
[S16 CD - grade calculator/Build and push image]   | #3 DONE 0.0s
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #4 [build 1/4] FROM docker.io/library/python:3.13-slim@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c
[S16 CD - grade calculator/Build and push image]   | #4 resolve docker.io/library/python:3.13-slim@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c 0.1s done
[S16 CD - grade calculator/Build and push image]   | #4 CACHED
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #5 [internal] load build context
[S16 CD - grade calculator/Build and push image]   | #5 transferring context: 4.72kB done
[S16 CD - grade calculator/Build and push image]   | #5 DONE 0.0s
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #6 [4/6] RUN pip install -r requirements.txt
[S16 CD - grade calculator/Build and push image]   | #6 CACHED
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #7 [5/6] RUN groupadd --gid 10001 app  && useradd --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app
[S16 CD - grade calculator/Build and push image]   | #7 CACHED
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #8 [2/6] WORKDIR /srv
[S16 CD - grade calculator/Build and push image]   | #8 CACHED
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #9 [3/6] COPY requirements.txt .
[S16 CD - grade calculator/Build and push image]   | #9 CACHED
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #10 [6/6] COPY app/ app/
[S16 CD - grade calculator/Build and push image]   | #10 CACHED
[S16 CD - grade calculator/Build and push image]   | 
[S16 CD - grade calculator/Build and push image]   | #11 exporting to image
[S16 CD - grade calculator/Build and push image]   | #11 exporting layers done
[S16 CD - grade calculator/Build and push image]   | #11 exporting manifest sha256:a8616af865acf597f9a8fb0364b13c23b0ce2248fe53c746a3f52ef6d52b8714 done
[S16 CD - grade calculator/Build and push image]   | #11 exporting config sha256:09249bfe2054fb0aaecca03018b8d0bcd7a7ad607583104f12acca4155e799df done
[S16 CD - grade calculator/Build and push image]   | #11 exporting attestation manifest sha256:88276d0c72458ed1c843f8f46713933eae5c9c04f871cc686bc6603ddbd83111 0.0s done
[S16 CD - grade calculator/Build and push image]   | #11 exporting manifest list sha256:7c6b8a95469c4c0e4ff470e2a28c2d3e6ba05da7d57baf9ec85a3b896a2413a8 0.0s done
[S16 CD - grade calculator/Build and push image]   | #11 naming to localhost:5055/bypratyush/grade-calculator:888cd81 done
[S16 CD - grade calculator/Build and push image]   | #11 unpacking to localhost:5055/bypratyush/grade-calculator:888cd81 0.0s done
[S16 CD - grade calculator/Build and push image]   | #11 naming to localhost:5055/bypratyush/grade-calculator:latest done
[S16 CD - grade calculator/Build and push image]   | #11 unpacking to localhost:5055/bypratyush/grade-calculator:latest
[S16 CD - grade calculator/Build and push image]   | #11 unpacking to localhost:5055/bypratyush/grade-calculator:latest 0.0s done
[S16 CD - grade calculator/Build and push image]   | #11 DONE 0.3s
[S16 CD - grade calculator/Build and push image]   ✅  Success - Main docker build [1.231308292s]
[S16 CD - grade calculator/Build and push image] ⭐ Run Main docker push
[S16 CD - grade calculator/Build and push image]   | The push refers to repository [localhost:5055/bypratyush/grade-calculator]
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Pushed
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Pushed
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Pushed
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Pushed
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Pushed
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Pushed
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Pushed
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Pushed
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Pushed
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Pushed
[S16 CD - grade calculator/Build and push image]   | 888cd81: digest: sha256:7c6b8a95469c4c0e4ff470e2a28c2d3e6ba05da7d57baf9ec85a3b896a2413a8 size: 856
[S16 CD - grade calculator/Build and push image]   | The push refers to repository [localhost:5055/bypratyush/grade-calculator]
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Waiting
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Waiting
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Waiting
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Waiting
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Waiting
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Waiting
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Waiting
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Waiting
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Waiting
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Waiting
[S16 CD - grade calculator/Build and push image]   | fa7136ea4be2: Already exists
[S16 CD - grade calculator/Build and push image]   | 7c4b10e82ec6: Layer already exists
[S16 CD - grade calculator/Build and push image]   | bbeda6b4abb7: Layer already exists
[S16 CD - grade calculator/Build and push image]   | a2c5ac708d8b: Layer already exists
[S16 CD - grade calculator/Build and push image]   | e41644b4b81a: Layer already exists
[S16 CD - grade calculator/Build and push image]   | 49b04c8898d4: Layer already exists
[S16 CD - grade calculator/Build and push image]   | 4f4fb700ef54: Layer already exists
[S16 CD - grade calculator/Build and push image]   | d21f6b2afeb7: Layer already exists
[S16 CD - grade calculator/Build and push image]   | 74202e18a58b: Layer already exists
[S16 CD - grade calculator/Build and push image]   | 0e1667fa430b: Layer already exists
[S16 CD - grade calculator/Build and push image]   | latest: digest: sha256:7c6b8a95469c4c0e4ff470e2a28c2d3e6ba05da7d57baf9ec85a3b896a2413a8 size: 856
[S16 CD - grade calculator/Build and push image]   | pushed localhost:5055/bypratyush/grade-calculator@sha256:7c6b8a95469c4c0e4ff470e2a28c2d3e6ba05da7d57baf9ec85a3b896a2413a8
[S16 CD - grade calculator/Build and push image]   ✅  Success - Main docker push [2.48609425s]
[S16 CD - grade calculator/Build and push image] ⭐ Run Complete job
[S16 CD - grade calculator/Build and push image] Cleaning up container for job Build and push image
[S16 CD - grade calculator/Build and push image]   ✅  Success - Complete job
[S16 CD - grade calculator/Build and push image] 🏁  Job succeeded
[S16 CD - grade calculator/Smoke-test pushed image] ⭐ Run Set up job
[S16 CD - grade calculator/Smoke-test pushed image] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S16 CD - grade calculator/Smoke-test pushed image]   ✅  Success - Set up job
[S16 CD - grade calculator/Smoke-test pushed image]   ☁  git clone 'https://github.com/docker/login-action' # ref=v4
[S16 CD - grade calculator/Smoke-test pushed image] ⭐ Run Main Check out code
[S16 CD - grade calculator/Smoke-test pushed image]   ✅  Success - Main Check out code [1.631103875s]
[S16 CD - grade calculator/Smoke-test pushed image] ⭐ Run Main Pull by digest (not by tag)
[S16 CD - grade calculator/Smoke-test pushed image]   | localhost:5055/bypratyush/grade-calculator@sha256:7c6b8a95469c4c0e4ff470e2a28c2d3e6ba05da7d57baf9ec85a3b896a2413a8: Pulling from bypratyush/grade-calculator
[S16 CD - grade calculator/Smoke-test pushed image]   | Digest: sha256:7c6b8a95469c4c0e4ff470e2a28c2d3e6ba05da7d57baf9ec85a3b896a2413a8
[S16 CD - grade calculator/Smoke-test pushed image]   | Status: Downloaded newer image for localhost:5055/bypratyush/grade-calculator@sha256:7c6b8a95469c4c0e4ff470e2a28c2d3e6ba05da7d57baf9ec85a3b896a2413a8
[S16 CD - grade calculator/Smoke-test pushed image]   | localhost:5055/bypratyush/grade-calculator@sha256:7c6b8a95469c4c0e4ff470e2a28c2d3e6ba05da7d57baf9ec85a3b896a2413a8
[S16 CD - grade calculator/Smoke-test pushed image]   ✅  Success - Main Pull by digest (not by tag) [3.064461959s]
[S16 CD - grade calculator/Smoke-test pushed image] ⭐ Run Main Run and test
[S16 CD - grade calculator/Smoke-test pushed image]   | b37e13d164702de686f5f2bd5cfa2f174539cb0f67f84a1a7eae70998e59855f
[S16 CD - grade calculator/Smoke-test pushed image]   | --- waiting for the Docker HEALTHCHECK to report healthy
[S16 CD - grade calculator/Smoke-test pushed image]   | health status: healthy (after ~6s)
[S16 CD - grade calculator/Smoke-test pushed image]   | container s16-cd-smoke is at http://172.17.0.4:8080
[S16 CD - grade calculator/Smoke-test pushed image]   | --- endpoints
[S16 CD - grade calculator/Smoke-test pushed image]   |   GET /health                                  HTTP 200  {"status":"ok"}
[S16 CD - grade calculator/Smoke-test pushed image]   |   GET /version                                 HTTP 200  {"commit":"888cd817ad3fcef35caa73374366c0af95030157","version":"1.2.0"}
[S16 CD - grade calculator/Smoke-test pushed image]   |   image was built from the expected commit
[S16 CD - grade calculator/Smoke-test pushed image]   |   GET /api/grade?score=91                      HTTP 200  {"grade":"O","points":10,"score":91.0}
[S16 CD - grade calculator/Smoke-test pushed image]   |   GET /api/grade?score=abc (bad)               HTTP 400  {"error":"score must be a number"}
[S16 CD - grade calculator/Smoke-test pushed image]   |   POST /api/sgpa                               HTTP 200  {"courses":[{"credits":4,"grade":"O","name":"DevOps","points":10},{"credits":3,"grade":"A","name":"DBMS","poin
[S16 CD - grade calculator/Smoke-test pushed image]   | --- container hardening
[S16 CD - grade calculator/Smoke-test pushed image]   |   process runs as uid 10001
[S16 CD - grade calculator/Smoke-test pushed image]   | --- secret-protected endpoint
[S16 CD - grade calculator/Smoke-test pushed image]   |   ADMIN_API_KEY secret is present (30 chars)
[S16 CD - grade calculator/Smoke-test pushed image]   |   GET /api/admin/stats (no key)                HTTP 401  {"error":"invalid or missing X-API-Key"}
[S16 CD - grade calculator/Smoke-test pushed image]   |   GET /api/admin/stats (with key)              HTTP 200  {"pid":8,"requests_served":{"grade":1,"sgpa":0},"uptime_seconds":5.7}
[S16 CD - grade calculator/Smoke-test pushed image]   | smoke test passed
[S16 CD - grade calculator/Smoke-test pushed image]   ✅  Success - Main Run and test [6.7180605s]
[S16 CD - grade calculator/Smoke-test pushed image] ⭐ Run Main Remove the container
[S16 CD - grade calculator/Smoke-test pushed image]   | s16-cd-smoke
[S16 CD - grade calculator/Smoke-test pushed image]   ✅  Success - Main Remove the container [319.939667ms]
[S16 CD - grade calculator/Smoke-test pushed image] ⭐ Run Complete job
[S16 CD - grade calculator/Smoke-test pushed image] Cleaning up container for job Smoke-test pushed image
[S16 CD - grade calculator/Smoke-test pushed image]   ✅  Success - Complete job
[S16 CD - grade calculator/Smoke-test pushed image] 🏁  Job succeeded
[S16 CD - grade calculator/Deploy to production   ] ⭐ Run Set up job
[S16 CD - grade calculator/Deploy to production   ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S16 CD - grade calculator/Deploy to production   ]   ✅  Success - Set up job
[S16 CD - grade calculator/Deploy to production   ]   ☁  git clone 'https://github.com/docker/login-action' # ref=v4
[S16 CD - grade calculator/Deploy to production   ] ⭐ Run Main Check out code
[S16 CD - grade calculator/Deploy to production   ]   ✅  Success - Main Check out code [3.405853625s]
[S16 CD - grade calculator/Deploy to production   ] ⭐ Run Main Require the production secret
[S16 CD - grade calculator/Deploy to production   ]   | ADMIN_API_KEY present (30 chars)
[S16 CD - grade calculator/Deploy to production   ]   ✅  Success - Main Require the production secret [117.589125ms]
[S16 CD - grade calculator/Deploy to production   ] ⭐ Run Main Replace the running release
[S16 CD - grade calculator/Deploy to production   ]   | localhost:5055/bypratyush/grade-calculator@sha256:7c6b8a95469c4c0e4ff470e2a28c2d3e6ba05da7d57baf9ec85a3b896a2413a8
[S16 CD - grade calculator/Deploy to production   ]   | previous release: none
[S16 CD - grade calculator/Deploy to production   ]   | 101818dc39835fdf68400c131f2a5da7217f7264dd6b53edbb20aaf10469676a
[S16 CD - grade calculator/Deploy to production   ]   | new release:      localhost:5055/bypratyush/grade-calculator@sha256:7c6b8a95469c4c0e4ff470e2a28c2d3e6ba05da7d57baf9ec85a3b896a2413a8
[S16 CD - grade calculator/Deploy to production   ]   ✅  Success - Main Replace the running release [3.546359333s]
[S16 CD - grade calculator/Deploy to production   ] ⭐ Run Main Verify the deployment
[S16 CD - grade calculator/Deploy to production   ]   | --- waiting for the Docker HEALTHCHECK to report healthy
[S16 CD - grade calculator/Deploy to production   ]   | health status: healthy (after ~6s)
[S16 CD - grade calculator/Deploy to production   ]   | container grade-calculator-production is at http://172.17.0.4:8080
[S16 CD - grade calculator/Deploy to production   ]   | --- endpoints
[S16 CD - grade calculator/Deploy to production   ]   |   GET /health                                  HTTP 200  {"status":"ok"}
[S16 CD - grade calculator/Deploy to production   ]   |   GET /version                                 HTTP 200  {"commit":"888cd817ad3fcef35caa73374366c0af95030157","version":"1.2.0"}
[S16 CD - grade calculator/Deploy to production   ]   |   image was built from the expected commit
[S16 CD - grade calculator/Deploy to production   ]   |   GET /api/grade?score=91                      HTTP 200  {"grade":"O","points":10,"score":91.0}
[S16 CD - grade calculator/Deploy to production   ]   |   GET /api/grade?score=abc (bad)               HTTP 400  {"error":"score must be a number"}
[S16 CD - grade calculator/Deploy to production   ]   |   POST /api/sgpa                               HTTP 200  {"courses":[{"credits":4,"grade":"O","name":"DevOps","points":10},{"credits":3,"grade":"A","name":"DBMS","poin
[S16 CD - grade calculator/Deploy to production   ]   | --- container hardening
[S16 CD - grade calculator/Deploy to production   ]   |   process runs as uid 10001
[S16 CD - grade calculator/Deploy to production   ]   | --- secret-protected endpoint
[S16 CD - grade calculator/Deploy to production   ]   |   ADMIN_API_KEY secret is present (30 chars)
[S16 CD - grade calculator/Deploy to production   ]   |   GET /api/admin/stats (no key)                HTTP 401  {"error":"invalid or missing X-API-Key"}
[S16 CD - grade calculator/Deploy to production   ]   |   GET /api/admin/stats (with key)              HTTP 200  {"pid":8,"requests_served":{"grade":1,"sgpa":0},"uptime_seconds":5.8}
[S16 CD - grade calculator/Deploy to production   ]   | smoke test passed
[S16 CD - grade calculator/Deploy to production   ]   ✅  Success - Main Verify the deployment [6.639930916s]
[S16 CD - grade calculator/Deploy to production   ] ⭐ Run Main Deployment summary
[S16 CD - grade calculator/Deploy to production   ]   ✅  Success - Main Deployment summary [103.172666ms]
[S16 CD - grade calculator/Deploy to production   ]   ⚙  Summary - ### Deployed grade-calculator to production

| Item | Value |
|---|---|
| Image | `localhost:5055/bypratyush/grade-calculator` |
| Digest | `sha256:7c6b8a95469c4c0e4ff470e2a28c2d3e6ba05da7d57baf9ec85a3b896a2413a8` |
| Commit | `888cd817ad3fcef35caa73374366c0af95030157` |
| Container | `grade-calculator-production` - healthy |
| Triggered by | workflow_run |
[S16 CD - grade calculator/Deploy to production   ] ⭐ Run Complete job
[S16 CD - grade calculator/Deploy to production   ] Cleaning up container for job Deploy to production
[S16 CD - grade calculator/Deploy to production   ]   ✅  Success - Complete job
[S16 CD - grade calculator/Deploy to production   ] 🏁  Job succeeded

act exit code: 0

==============================================================
STEP 10 - What is in the registry now
==============================================================
{"repositories":["bypratyush/grade-calculator"]}

{"name":"bypratyush/grade-calculator","tags":["888cd81","latest"]}


==============================================================
STEP 11 - The deployed 'production' container, called from the Mac
==============================================================
NAMES                         IMAGE                                        STATUS                   PORTS
grade-calculator-production   localhost:5055/bypratyush/grade-calculator   Up 9 seconds (healthy)   127.0.0.1:18716->8080/tcp

$ curl localhost:18716/version
{"commit":"888cd817ad3fcef35caa73374366c0af95030157","version":"1.2.0"}

$ curl 'localhost:18716/api/grade?score=78'
{"grade":"A","points":8,"score":78.0}


==============================================================
CLEANUP - deployed container, local registry, images built by the runs
==============================================================
grade-calculator-production
s16-registry
left behind by act: 1 containers
```
