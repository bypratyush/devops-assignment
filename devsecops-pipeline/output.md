# DevSecOps Pipeline - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Produced by `./run.sh red`, then `./run.sh green` + `./run.sh cleanup`, on 2026-10-07/08 with act 0.2.89. Verbatim, except that the fake `ghp_` test token is redacted (the first red attempt ran before `run.sh` learned to redact it; the same `sed` was applied to that log afterwards - see README section 3).

Between the two runs the Dockerfile was changed to remove `pip` from the runtime image (the red run showed its vendored packages failing the image gate). The two `syntax error near unexpected token` lines near the end of the green run are from `run.sh` being edited (a `report` subcommand added) while that run was still executing; the pipeline itself had already finished with act exit code 0.

## 1. `./run.sh red`

```text

==============================================================
RED RUN - STEP 1: inject three problems into the code
==============================================================
--- strength.py
6a7
> import hashlib
108a110,114
> 
> 
> def fingerprint(password):
>     """Short id used to cache results."""
>     return hashlib.md5(password.encode()).hexdigest()[:12]
--- requirements.txt
6c6
< gunicorn==26.2.0
---
> gunicorn==21.2.0
--- new file config.py (token masked here)
# upstream API used for breach lookups
UPSTREAM_TOKEN = "ghp_<36 fake characters>"

==============================================================
RED RUN - STEP 2: run the pipeline
==============================================================
$ act push -W .github/workflows/devsecops.yml -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest --container-architecture linux/arm64 \
      --artifact-server-path .act/artifacts --artifact-server-port 34568 --rm

time="2026-10-07T23:58:22+05:30" level=info msg="Using docker host 'unix:///var/run/docker.sock', and daemon socket 'unix:///var/run/docker.sock'"
time="2026-10-07T23:58:22+05:30" level=info msg="Start server on http://100.128.166.254:34568"
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/1 Code] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/1 Code]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Main actions/checkout@v6 [1.161148375s]
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Main actions/setup-python@v6
[S17 DevSecOps - PassGuard/1 Code]   | Successfully set up CPython (3.13.16)
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Main actions/setup-python@v6 [756.976625ms]
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Main Commit under test
[S17 DevSecOps - PassGuard/1 Code]   | commit 888cd817ad3fcef35caa73374366c0af95030157 on refs/heads/main (event push)
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Main Commit under test [66.959417ms]
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Main Lint (ruff)
[S17 DevSecOps - PassGuard/1 Code]   | 6 files already formatted
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Main Lint (ruff) [367.2975ms]
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Post actions/setup-python@v6
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Post actions/setup-python@v6 [156.385ms]
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/1 Code] Cleaning up container for job 1 Code
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/1 Code] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/2 Build] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/2 Build]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S17 DevSecOps - PassGuard/2 Build]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Main actions/checkout@v6 [1.017826417s]
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Main actions/setup-python@v6
[S17 DevSecOps - PassGuard/2 Build]   | Successfully set up CPython (3.13.16)
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Main actions/setup-python@v6 [714.770667ms]
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Main Build the wheel
[S17 DevSecOps - PassGuard/2 Build]   | * Creating isolated environment: venv+pip...
[S17 DevSecOps - PassGuard/2 Build]   | * Installing packages in isolated environment:
[S17 DevSecOps - PassGuard/2 Build]   |   - setuptools>=80
[S17 DevSecOps - PassGuard/2 Build]   |   - wheel
[S17 DevSecOps - PassGuard/2 Build]   | * Getting build dependencies for wheel...
[S17 DevSecOps - PassGuard/2 Build]   | running egg_info
[S17 DevSecOps - PassGuard/2 Build]   | creating src/passguard.egg-info
[S17 DevSecOps - PassGuard/2 Build]   | writing src/passguard.egg-info/PKG-INFO
[S17 DevSecOps - PassGuard/2 Build]   | writing dependency_links to src/passguard.egg-info/dependency_links.txt
[S17 DevSecOps - PassGuard/2 Build]   | writing requirements to src/passguard.egg-info/requires.txt
[S17 DevSecOps - PassGuard/2 Build]   | writing top-level names to src/passguard.egg-info/top_level.txt
[S17 DevSecOps - PassGuard/2 Build]   | writing manifest file 'src/passguard.egg-info/SOURCES.txt'
[S17 DevSecOps - PassGuard/2 Build]   | reading manifest file 'src/passguard.egg-info/SOURCES.txt'
[S17 DevSecOps - PassGuard/2 Build]   | writing manifest file 'src/passguard.egg-info/SOURCES.txt'
[S17 DevSecOps - PassGuard/2 Build]   | * Installed build dependency versions:
[S17 DevSecOps - PassGuard/2 Build]   |   - setuptools==84.0.0
[S17 DevSecOps - PassGuard/2 Build]   |   - wheel==0.48.0
[S17 DevSecOps - PassGuard/2 Build]   | * Building wheel...
[S17 DevSecOps - PassGuard/2 Build]   | running bdist_wheel
[S17 DevSecOps - PassGuard/2 Build]   | running build
[S17 DevSecOps - PassGuard/2 Build]   | running build_py
[S17 DevSecOps - PassGuard/2 Build]   | creating build/lib/passguard
[S17 DevSecOps - PassGuard/2 Build]   | copying src/passguard/config.py -> build/lib/passguard
[S17 DevSecOps - PassGuard/2 Build]   | copying src/passguard/__init__.py -> build/lib/passguard
[S17 DevSecOps - PassGuard/2 Build]   | copying src/passguard/strength.py -> build/lib/passguard
[S17 DevSecOps - PassGuard/2 Build]   | running egg_info
[S17 DevSecOps - PassGuard/2 Build]   | writing src/passguard.egg-info/PKG-INFO
[S17 DevSecOps - PassGuard/2 Build]   | writing dependency_links to src/passguard.egg-info/dependency_links.txt
[S17 DevSecOps - PassGuard/2 Build]   | writing requirements to src/passguard.egg-info/requires.txt
[S17 DevSecOps - PassGuard/2 Build]   | writing top-level names to src/passguard.egg-info/top_level.txt
[S17 DevSecOps - PassGuard/2 Build]   | reading manifest file 'src/passguard.egg-info/SOURCES.txt'
[S17 DevSecOps - PassGuard/2 Build]   | writing manifest file 'src/passguard.egg-info/SOURCES.txt'
[S17 DevSecOps - PassGuard/2 Build]   | creating build/lib/passguard/templates
[S17 DevSecOps - PassGuard/2 Build]   | copying src/passguard/templates/index.html -> build/lib/passguard/templates
[S17 DevSecOps - PassGuard/2 Build]   | creating build/lib/passguard/static
[S17 DevSecOps - PassGuard/2 Build]   | copying src/passguard/static/style.css -> build/lib/passguard/static
[S17 DevSecOps - PassGuard/2 Build]   | copying src/passguard/static/app.js -> build/lib/passguard/static
[S17 DevSecOps - PassGuard/2 Build]   | installing to build/bdist.linux-aarch64/wheel
[S17 DevSecOps - PassGuard/2 Build]   | running install
[S17 DevSecOps - PassGuard/2 Build]   | running install_lib
[S17 DevSecOps - PassGuard/2 Build]   | creating build/bdist.linux-aarch64/wheel
[S17 DevSecOps - PassGuard/2 Build]   | creating build/bdist.linux-aarch64/wheel/passguard
[S17 DevSecOps - PassGuard/2 Build]   | copying build/lib/passguard/config.py -> build/bdist.linux-aarch64/wheel/./passguard
[S17 DevSecOps - PassGuard/2 Build]   | creating build/bdist.linux-aarch64/wheel/passguard/static
[S17 DevSecOps - PassGuard/2 Build]   | copying build/lib/passguard/static/style.css -> build/bdist.linux-aarch64/wheel/./passguard/static
[S17 DevSecOps - PassGuard/2 Build]   | copying build/lib/passguard/static/app.js -> build/bdist.linux-aarch64/wheel/./passguard/static
[S17 DevSecOps - PassGuard/2 Build]   | copying build/lib/passguard/__init__.py -> build/bdist.linux-aarch64/wheel/./passguard
[S17 DevSecOps - PassGuard/2 Build]   | copying build/lib/passguard/strength.py -> build/bdist.linux-aarch64/wheel/./passguard
[S17 DevSecOps - PassGuard/2 Build]   | creating build/bdist.linux-aarch64/wheel/passguard/templates
[S17 DevSecOps - PassGuard/2 Build]   | copying build/lib/passguard/templates/index.html -> build/bdist.linux-aarch64/wheel/./passguard/templates
[S17 DevSecOps - PassGuard/2 Build]   | running install_egg_info
[S17 DevSecOps - PassGuard/2 Build]   | Copying src/passguard.egg-info to build/bdist.linux-aarch64/wheel/./passguard-1.0.0-py3.13.egg-info
[S17 DevSecOps - PassGuard/2 Build]   | running install_scripts
[S17 DevSecOps - PassGuard/2 Build]   | creating build/bdist.linux-aarch64/wheel/passguard-1.0.0.dist-info/WHEEL
[S17 DevSecOps - PassGuard/2 Build]   | creating '/Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/dist/.tmp-4p0_rjvp/passguard-1.0.0-py3-none-any.whl' and adding 'build/bdist.linux-aarch64/wheel' to it
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard/__init__.py'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard/config.py'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard/strength.py'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard/static/app.js'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard/static/style.css'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard/templates/index.html'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard-1.0.0.dist-info/METADATA'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard-1.0.0.dist-info/WHEEL'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard-1.0.0.dist-info/top_level.txt'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard-1.0.0.dist-info/RECORD'
[S17 DevSecOps - PassGuard/2 Build]   | removing build/bdist.linux-aarch64/wheel
[S17 DevSecOps - PassGuard/2 Build]   | Successfully built passguard-1.0.0-py3-none-any.whl
[S17 DevSecOps - PassGuard/2 Build]   | total 8
[S17 DevSecOps - PassGuard/2 Build]   | -rw-r--r-- 1 root root 6351 Oct  7 18:28 passguard-1.0.0-py3-none-any.whl
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Main Build the wheel [3.349826208s]
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Main actions/upload-artifact@v5
[S17 DevSecOps - PassGuard/2 Build]   | With the provided path, there will be 1 file uploaded
[S17 DevSecOps - PassGuard/2 Build]   | Artifact name is valid!
[S17 DevSecOps - PassGuard/2 Build]   | Root directory input is valid!
[S17 DevSecOps - PassGuard/2 Build]   | Beginning upload of artifact content to blob storage
[S17 DevSecOps - PassGuard/2 Build]   | Uploaded bytes 5745
[S17 DevSecOps - PassGuard/2 Build]   | Finished uploading artifact content to blob storage!
[S17 DevSecOps - PassGuard/2 Build]   | SHA256 digest of uploaded artifact zip is d1a35b873ea88fedf487fd488cf835ad98edd9a112007d2dbdbfc835715643f1
[S17 DevSecOps - PassGuard/2 Build]   | Finalizing artifact upload
[S17 DevSecOps - PassGuard/2 Build]   | Artifact wheel.zip successfully finalized. Artifact ID 473058556
[S17 DevSecOps - PassGuard/2 Build]   | Artifact wheel has been successfully uploaded! Final size is 5745 bytes. Artifact ID is 473058556
[S17 DevSecOps - PassGuard/2 Build]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/473058556
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Main actions/upload-artifact@v5 [617.218625ms]
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Post actions/setup-python@v6
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Post actions/setup-python@v6 [141.510291ms]
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/2 Build] Cleaning up container for job 2 Build
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/2 Build] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/3 Unit Test] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/3 Unit Test]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S17 DevSecOps - PassGuard/3 Unit Test]   ☁  git clone 'https://github.com/actions/download-artifact' # ref=v7
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Main actions/checkout@v6 [1.533099916s]
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Main actions/setup-python@v6
[S17 DevSecOps - PassGuard/3 Unit Test]   | Successfully set up CPython (3.13.16)
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Main actions/setup-python@v6 [1.040451s]
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Main actions/download-artifact@v7
[S17 DevSecOps - PassGuard/3 Unit Test]   | Downloading single artifact
[S17 DevSecOps - PassGuard/3 Unit Test]   | Preparing to download the following artifacts:
[S17 DevSecOps - PassGuard/3 Unit Test]   | - wheel (ID: 473058556, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/3 Unit Test]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/3 Unit Test]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/dist
[S17 DevSecOps - PassGuard/3 Unit Test]   | SHA256 digest of downloaded artifact is d1a35b873ea88fedf487fd488cf835ad98edd9a112007d2dbdbfc835715643f1
[S17 DevSecOps - PassGuard/3 Unit Test]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/3 Unit Test]   | Total of 1 artifact(s) downloaded
[S17 DevSecOps - PassGuard/3 Unit Test]   | Download artifact has finished successfully
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Main actions/download-artifact@v7 [848.279916ms]
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Main Test the built wheel (not the source tree)
[S17 DevSecOps - PassGuard/3 Unit Test]   | ============================= test session starts ==============================
[S17 DevSecOps - PassGuard/3 Unit Test]   | platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0
[S17 DevSecOps - PassGuard/3 Unit Test]   | rootdir: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline
[S17 DevSecOps - PassGuard/3 Unit Test]   | configfile: pyproject.toml
[S17 DevSecOps - PassGuard/3 Unit Test]   | testpaths: tests
[S17 DevSecOps - PassGuard/3 Unit Test]   | plugins: cov-7.1.0
[S17 DevSecOps - PassGuard/3 Unit Test]   | collected 30 items
[S17 DevSecOps - PassGuard/3 Unit Test]   | 
[S17 DevSecOps - PassGuard/3 Unit Test]   | tests/test_api.py ............                                           [ 40%]
[S17 DevSecOps - PassGuard/3 Unit Test]   | tests/test_strength.py ..................                                [100%]
[S17 DevSecOps - PassGuard/3 Unit Test]   | 
[S17 DevSecOps - PassGuard/3 Unit Test]   | ================================ tests coverage ================================
[S17 DevSecOps - PassGuard/3 Unit Test]   | _______________ coverage: platform linux, python 3.13.16-final-0 _______________
[S17 DevSecOps - PassGuard/3 Unit Test]   | 
[S17 DevSecOps - PassGuard/3 Unit Test]   | Name                                                                                           Stmts   Miss  Cover
[S17 DevSecOps - PassGuard/3 Unit Test]   | ------------------------------------------------------------------------------------------------------------------
[S17 DevSecOps - PassGuard/3 Unit Test]   | /opt/hostedtoolcache/Python/3.13.16/arm64/lib/python3.13/site-packages/passguard/__init__.py      43      0   100%
[S17 DevSecOps - PassGuard/3 Unit Test]   | /opt/hostedtoolcache/Python/3.13.16/arm64/lib/python3.13/site-packages/passguard/config.py         1      1     0%
[S17 DevSecOps - PassGuard/3 Unit Test]   | /opt/hostedtoolcache/Python/3.13.16/arm64/lib/python3.13/site-packages/passguard/strength.py      62      1    98%
[S17 DevSecOps - PassGuard/3 Unit Test]   | ------------------------------------------------------------------------------------------------------------------
[S17 DevSecOps - PassGuard/3 Unit Test]   | TOTAL                                                                                            106      2    98%
[S17 DevSecOps - PassGuard/3 Unit Test]   | Required test coverage of 90% reached. Total coverage: 98.11%
[S17 DevSecOps - PassGuard/3 Unit Test]   | ============================== 30 passed in 0.24s ==============================
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Main Test the built wheel (not the source tree) [2.045286958s]
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Post actions/setup-python@v6
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Post actions/setup-python@v6 [171.439041ms]
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/3 Unit Test] Cleaning up container for job 3 Unit Test
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/3 Unit Test] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Main actions/checkout@v6 [1.52273975s]
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Main actions/setup-python@v6
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Successfully set up CPython (3.13.16)
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Main actions/setup-python@v6 [1.44460975s]
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Main Bandit
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	profile include tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	profile exclude tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	cli include tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	cli exclude tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [json]	INFO	JSON output written to file: reports/bandit.json
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	profile include tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	profile exclude tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	cli include tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	cli exclude tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	using config: pyproject.toml
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	running on Python 3.13.16
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Run started:2026-10-07 18:28:54.608659+00:00
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Test results:
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | >> Issue: [B105:hardcoded_password_string] Possible hardcoded password: 'ghp_<redacted by run.sh>'
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   |    Severity: Low   Confidence: Medium
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   |    CWE: CWE-259 (https://cwe.mitre.org/data/definitions/259.html)
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   |    More Info: https://bandit.readthedocs.io/en/1.9.4/plugins/b105_hardcoded_password_string.html
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   |    Location: src/passguard/config.py:2:17
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 1	# upstream API used for breach lookups
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 2	UPSTREAM_TOKEN = "ghp_<redacted by run.sh>"
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | --------------------------------------------------
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | >> Issue: [B324:hashlib] Use of weak MD5 hash for security. Consider usedforsecurity=False
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   |    Severity: High   Confidence: High
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   |    CWE: CWE-327 (https://cwe.mitre.org/data/definitions/327.html)
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   |    More Info: https://bandit.readthedocs.io/en/1.9.4/plugins/b324_hashlib.html
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   |    Location: src/passguard/strength.py:114:11
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 113	    """Short id used to cache results."""
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 114	    return hashlib.md5(password.encode()).hexdigest()[:12]
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | --------------------------------------------------
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Code scanned:
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 	Total lines of code: 142
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 	Total lines skipped (#nosec): 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 	Total potential issues skipped due to specifically being disabled (e.g., #nosec BXXX): 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Run metrics:
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 	Total issues (by severity):
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		Undefined: 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		Low: 1
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		Medium: 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		High: 1
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 	Total issues (by confidence):
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		Undefined: 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		Low: 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		Medium: 1
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		High: 1
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Files skipped (0):
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Main Bandit [3.53551s]
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Main actions/upload-artifact@v5
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | With the provided path, there will be 1 file uploaded
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Artifact name is valid!
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Root directory input is valid!
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Beginning upload of artifact content to blob storage
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Uploaded bytes 945
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Finished uploading artifact content to blob storage!
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | SHA256 digest of uploaded artifact zip is 9cc5621ee7afb2f7ed3f40d31bb62d1569e10ea7ebc231b9f916818d131f3cdd
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Finalizing artifact upload
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Artifact report-sast.zip successfully finalized. Artifact ID 862344689
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Artifact report-sast has been successfully uploaded! Final size is 945 bytes. Artifact ID is 862344689
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/862344689
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Main actions/upload-artifact@v5 [958.006542ms]
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Post actions/setup-python@v6
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Post actions/setup-python@v6 [176.786167ms]
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] Cleaning up container for job 4 SAST (Bandit)
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Main actions/checkout@v6 [1.330468458s]
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Main actions/setup-python@v6
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Successfully set up CPython (3.13.16)
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Main actions/setup-python@v6 [1.03490175s]
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Main pip-audit on the pinned requirements
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Found 4 known vulnerabilities in 1 package
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Found 4 known vulnerabilities in 1 package
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Name     Version ID              Fix Versions
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | -------- ------- --------------- ------------
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | gunicorn 21.2.0  PYSEC-2026-1434 22.0.0
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | gunicorn 21.2.0  PYSEC-2026-1433 22.0.0
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | gunicorn 21.2.0  PYSEC-2026-1434 22.0.0
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | gunicorn 21.2.0  PYSEC-2026-1433 22.0.0
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Main pip-audit on the pinned requirements [16.498507708s]
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Main actions/upload-artifact@v5
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | With the provided path, there will be 1 file uploaded
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Artifact name is valid!
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Root directory input is valid!
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Beginning upload of artifact content to blob storage
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Uploaded bytes 1049
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Finished uploading artifact content to blob storage!
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | SHA256 digest of uploaded artifact zip is 5625bd12a91c8c73dddee4ae07735660a527f2555e3eb4ea29dd05ac0483886d
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Finalizing artifact upload
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Artifact report-sca.zip successfully finalized. Artifact ID 2543950051
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Artifact report-sca has been successfully uploaded! Final size is 1049 bytes. Artifact ID is 2543950051
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/2543950051
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Main actions/upload-artifact@v5 [757.567459ms]
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Post actions/setup-python@v6
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Post actions/setup-python@v6 [155.021667ms]
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] Cleaning up container for job 5 SCA (pip-audit)
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ✅  Success - Main actions/checkout@v6 [1.526426959s]
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] ⭐ Run Main Install gitleaks (pinned, checksum verified)
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | installed gitleaks (arm64, sha256 verified) -> /root/.local/bin/gitleaks
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ✅  Success - Main Install gitleaks (pinned, checksum verified) [2.724494s]
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] ⭐ Run Main gitleaks
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Finding:     ...ardcoded password: 'REDACTED
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Secret:      REDACTED
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | RuleID:      github-pat
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Entropy:     4.265312
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | File:        logs/red.log
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Line:        302
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Fingerprint: logs/red.log:github-pat:302
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | 
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Finding:     ...2	UPSTREAM_TOKEN = "REDACTED
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Secret:      REDACTED
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | RuleID:      github-pat
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Entropy:     4.265312
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | File:        logs/red.log
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Line:        308
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Fingerprint: logs/red.log:github-pat:308
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | 
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Finding:     REDACTED
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Secret:      REDACTED
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | RuleID:      passguard-hardcoded-upstream-token
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Entropy:     4.882312
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | File:        src/passguard/config.py
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Line:        2
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Fingerprint: src/passguard/config.py:passguard-hardcoded-upstream-token:2
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | 
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Finding:     UPSTREAM_TOKEN = "REDACTED
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Secret:      REDACTED
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | RuleID:      github-pat
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Entropy:     4.265312
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | File:        src/passguard/config.py
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Line:        2
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Fingerprint: src/passguard/config.py:github-pat:2
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | 
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | 6:29PM INF scanned ~73854 bytes (73.85 KB) in 20.1ms
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | 6:29PM WRN leaks found: 4
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ✅  Success - Main gitleaks [393.275ms]
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] ⭐ Run Main actions/upload-artifact@v5
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | With the provided path, there will be 1 file uploaded
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Artifact name is valid!
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Root directory input is valid!
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Beginning upload of artifact content to blob storage
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Uploaded bytes 607
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Finished uploading artifact content to blob storage!
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | SHA256 digest of uploaded artifact zip is 0c093a9798927e9c294044fd23f4b0823020b918e7c8ce68fc0441d88b5d3259
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Finalizing artifact upload
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Artifact report-secrets.zip successfully finalized. Artifact ID 3564946595
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Artifact report-secrets has been successfully uploaded! Final size is 607 bytes. Artifact ID is 3564946595
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/3564946595
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ✅  Success - Main actions/upload-artifact@v5 [658.350459ms]
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] Cleaning up container for job 6 Secret Scan (gitleaks)
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/7 Docker Build          ] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/7 Docker Build          ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ☁  git clone 'https://github.com/actions/download-artifact' # ref=v7
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S17 DevSecOps - PassGuard/7 Docker Build          ] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ✅  Success - Main actions/checkout@v6 [1.487176917s]
[S17 DevSecOps - PassGuard/7 Docker Build          ] ⭐ Run Main actions/download-artifact@v7
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Downloading single artifact
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Preparing to download the following artifacts:
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | - wheel (ID: 473058556, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/dist
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | SHA256 digest of downloaded artifact is d1a35b873ea88fedf487fd488cf835ad98edd9a112007d2dbdbfc835715643f1
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Total of 1 artifact(s) downloaded
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Download artifact has finished successfully
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ✅  Success - Main actions/download-artifact@v7 [1.057112833s]
[S17 DevSecOps - PassGuard/7 Docker Build          ] ⭐ Run Main docker build (from the tested wheel)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #0 building with "default" instance using docker driver
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #1 [internal] load build definition from Dockerfile
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #1 transferring dockerfile: 1.41kB 0.0s done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #1 DONE 0.1s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #2 [internal] load metadata for docker.io/library/python:3.13-slim
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #2 DONE 0.0s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #3 [internal] load .dockerignore
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #3 transferring context: 150B 0.0s done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #3 DONE 0.1s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #4 [internal] load build context
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #4 DONE 0.0s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #5 [build 1/4] FROM docker.io/library/python:3.13-slim@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #5 resolve docker.io/library/python:3.13-slim@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c 0.1s done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #5 CACHED
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #4 [internal] load build context
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #4 transferring context: 6.78kB 0.0s done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #4 DONE 0.1s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #6 [build 2/4] COPY requirements.txt /tmp/requirements.txt
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #6 DONE 0.4s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #7 [stage-1 2/3] RUN groupadd --gid 10001 app && useradd --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #7 ...
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #8 [build 3/4] COPY dist/*.whl /tmp/
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #8 DONE 0.1s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 [build 4/4] RUN python -m venv /venv  && /venv/bin/pip install -r /tmp/requirements.txt  && /venv/bin/pip install --no-deps /tmp/*.whl
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 ...
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #7 [stage-1 2/3] RUN groupadd --gid 10001 app && useradd --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #7 DONE 1.1s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 [build 4/4] RUN python -m venv /venv  && /venv/bin/pip install -r /tmp/requirements.txt  && /venv/bin/pip install --no-deps /tmp/*.whl
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 5.771 Collecting blinker==1.9.0 (from -r /tmp/requirements.txt (line 3))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 5.967   Downloading blinker-1.9.0-py3-none-any.whl.metadata (1.6 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 6.041 Collecting click==8.5.0 (from -r /tmp/requirements.txt (line 4))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 6.062   Downloading click-8.5.0-py3-none-any.whl.metadata (2.6 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 6.178 Collecting flask==3.1.3 (from -r /tmp/requirements.txt (line 5))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 6.263   Downloading flask-3.1.3-py3-none-any.whl.metadata (3.2 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 6.373 Collecting gunicorn==21.2.0 (from -r /tmp/requirements.txt (line 6))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 6.701   Downloading gunicorn-21.2.0-py3-none-any.whl.metadata (4.1 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 6.770 Collecting itsdangerous==2.2.0 (from -r /tmp/requirements.txt (line 7))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 6.800   Downloading itsdangerous-2.2.0-py3-none-any.whl.metadata (1.9 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 6.863 Collecting jinja2==3.1.6 (from -r /tmp/requirements.txt (line 8))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 6.886   Downloading jinja2-3.1.6-py3-none-any.whl.metadata (2.9 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.120 Collecting markupsafe==3.0.4 (from -r /tmp/requirements.txt (line 9))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.265   Downloading markupsafe-3.0.4-cp313-cp313-manylinux2014_aarch64.manylinux_2_17_aarch64.manylinux_2_28_aarch64.whl.metadata (2.7 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.297 Collecting werkzeug==3.1.9 (from -r /tmp/requirements.txt (line 10))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.366   Downloading werkzeug-3.1.9-py3-none-any.whl.metadata (4.1 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.408 Collecting packaging (from gunicorn==21.2.0->-r /tmp/requirements.txt (line 6))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.470   Downloading packaging-26.3-py3-none-any.whl.metadata (3.5 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.495 Downloading blinker-1.9.0-py3-none-any.whl (8.5 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.573 Downloading click-8.5.0-py3-none-any.whl (125 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.676 Downloading flask-3.1.3-py3-none-any.whl (103 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.775 Downloading gunicorn-21.2.0-py3-none-any.whl (80 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.798 Downloading itsdangerous-2.2.0-py3-none-any.whl (16 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.824 Downloading jinja2-3.1.6-py3-none-any.whl (134 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.906 Downloading markupsafe-3.0.4-cp313-cp313-manylinux2014_aarch64.manylinux_2_17_aarch64.manylinux_2_28_aarch64.whl (24 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 7.981 Downloading werkzeug-3.1.9-py3-none-any.whl (228 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 8.013 Downloading packaging-26.3-py3-none-any.whl (129 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 8.095 Installing collected packages: packaging, markupsafe, itsdangerous, click, blinker, werkzeug, jinja2, gunicorn, flask
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 8.757 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 8.758 Successfully installed blinker-1.9.0 click-8.5.0 flask-3.1.3 gunicorn-21.2.0 itsdangerous-2.2.0 jinja2-3.1.6 markupsafe-3.0.4 packaging-26.3 werkzeug-3.1.9
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 9.373 Processing ./tmp/passguard-1.0.0-py3-none-any.whl
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 9.386 Installing collected packages: passguard
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 9.397 Successfully installed passguard-1.0.0
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 DONE 9.7s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #10 [stage-1 3/3] COPY --from=build /venv /venv
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #10 DONE 0.2s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 exporting to image
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 exporting layers
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 exporting layers 0.8s done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 exporting manifest sha256:e269e452c115936cb4eca8fd6c2469ccf4a4df2c04aabe7aa12199a08c9887a7 done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 exporting config sha256:d7ed22206330bb9a1a4d5d1c5fdd79eeaa4a18366171f788ca799970875ac04d 0.0s done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 naming to docker.io/library/passguard:888cd81 done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 unpacking to docker.io/library/passguard:888cd81
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 unpacking to docker.io/library/passguard:888cd81 0.2s done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 DONE 1.1s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | -rw------- 1 root root 47M Oct  7 18:29 dist/image.tar
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ✅  Success - Main docker build (from the tested wheel) [14.472054417s]
[S17 DevSecOps - PassGuard/7 Docker Build          ] ⭐ Run Main actions/upload-artifact@v5
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | With the provided path, there will be 1 file uploaded
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Artifact name is valid!
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Root directory input is valid!
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Beginning upload of artifact content to blob storage
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Uploaded bytes 8388608
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Uploaded bytes 16777216
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Uploaded bytes 25165824
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Uploaded bytes 33554432
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Uploaded bytes 41943040
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Uploaded bytes 48838270
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Finished uploading artifact content to blob storage!
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | SHA256 digest of uploaded artifact zip is 73fc860e20735dd4217c2c6c088f56f54d363eb5a2c8d793ca25e6a21b7bb72e
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Finalizing artifact upload
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Artifact image.zip successfully finalized. Artifact ID 3008443898
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Artifact image has been successfully uploaded! Final size is 48838270 bytes. Artifact ID is 3008443898
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/3008443898
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ✅  Success - Main actions/upload-artifact@v5 [2.98988475s]
[S17 DevSecOps - PassGuard/7 Docker Build          ] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/7 Docker Build          ] Cleaning up container for job 7 Docker Build
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/7 Docker Build          ] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ☁  git clone 'https://github.com/actions/download-artifact' # ref=v7
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Main actions/checkout@v6 [2.666954666s]
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Main actions/download-artifact@v7
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Downloading single artifact
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Preparing to download the following artifacts:
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | - image (ID: 3008443898, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/dist
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | SHA256 digest of downloaded artifact is 73fc860e20735dd4217c2c6c088f56f54d363eb5a2c8d793ca25e6a21b7bb72e
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Total of 1 artifact(s) downloaded
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Download artifact has finished successfully
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Main actions/download-artifact@v7 [1.84187925s]
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Main Install Trivy (pinned, checksum verified)
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | installed trivy (arm64, sha256 verified) -> /root/.local/bin/trivy
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Main Install Trivy (pinned, checksum verified) [9.504250125s]
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Main Trivy scan of the exact image tarball
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 2026-10-07T18:30:32Z	WARN	[report] No enabled scanners found. Summary table will not be displayed.
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 2026-10-07T18:30:32Z	INFO	Table result includes only package filenames. Use '--format json' option to get the full path to the package file.
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | For OSS Maintainers: VEX Notice
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | --------------------------------
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | If you're an OSS maintainer and Trivy has detected vulnerabilities in your project that you believe are not actually exploitable, consider issuing a VEX (Vulnerability Exploitability eXchange) statement.
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | VEX allows you to communicate the actual status of vulnerabilities in your project, improving security transparency and reducing false positives for your users.
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Learn more and start using VEX: https://trivy.dev/docs/v0.74/guide/supply-chain/vex/repo#publishing-vex-documents
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | To disable this notice, set the TRIVY_DISABLE_VEX_NOTICE environment variable.
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | dist/image.tar (debian 13.7)
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ============================
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Total: 44 (HIGH: 44, CRITICAL: 0)
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ┌───────────────┬────────────────┬──────────┬──────────────┬───────────────────────────────────┬───────────────┬─────────────────────────────────────────────────────────────┐
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │    Library    │ Vulnerability  │ Severity │    Status    │         Installed Version         │ Fixed Version │                            Title                            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┼──────────┼──────────────┼───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ bsdutils      │ CVE-2026-76642 │ HIGH     │ affected     │ 1:2.41.5-0+deb13u1                │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libacl1       │ CVE-2026-54369 │          │              │ 2.3.2-2+b1                        │               │ acl: Symlink traversal privilege escalation via libacl      │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ functions                                                   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-54369                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libblkid1     │ CVE-2026-76642 │          │              │ 2.41.5-0+deb13u1                  │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ liblastlog2-2 │ CVE-2026-76642 │          │              │                                   │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libmount1     │ CVE-2026-76642 │          │              │                                   │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libncursesw6  │ CVE-2025-69720 │          │              │ 6.5+20250216-2                    │               │ ncurses: ncurses: Buffer overflow vulnerability may lead to │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ arbitrary code execution.                                   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2025-69720                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libsmartcols1 │ CVE-2026-76642 │          │              │ 2.41.5-0+deb13u1                  │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libsystemd0   │ CVE-2026-16742 │          │              │ 257.13-1~deb13u1                  │               │ systemd: systemd-homed: Local privilege escalation via      │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ missing home-record signature verification                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-16742                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libtinfo6     │ CVE-2025-69720 │          │              │ 6.5+20250216-2                    │               │ ncurses: ncurses: Buffer overflow vulnerability may lead to │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ arbitrary code execution.                                   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2025-69720                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libudev1      │ CVE-2026-16742 │          │              │ 257.13-1~deb13u1                  │               │ systemd: systemd-homed: Local privilege escalation via      │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ missing home-record signature verification                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-16742                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libuuid1      │ CVE-2026-76642 │          │              │ 2.41.5-0+deb13u1                  │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ login         │ CVE-2026-76642 │          │              │ 1:4.16.0-2+really2.41.5-0+deb13u1 │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ mount         │ CVE-2026-76642 │          │              │ 2.41.5-0+deb13u1                  │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ ncurses-base  │ CVE-2025-69720 │          │              │ 6.5+20250216-2                    │               │ ncurses: ncurses: Buffer overflow vulnerability may lead to │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ arbitrary code execution.                                   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2025-69720                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┤                │          │              │                                   ├───────────────┤                                                             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ ncurses-bin   │                │          │              │                                   │               │                                                             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │                                                             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │                                                             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          ├──────────────┼───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ perl-base     │ CVE-2026-9538  │          │ fix_deferred │ 5.40.1-6+deb13u1                  │               │ perl-Archive-Tar: perl-Archive-Tar: Denial of Service via   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ crafted tar header with large entry...                      │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-9538                   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          ├──────────────┼───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ util-linux    │ CVE-2026-76642 │          │ affected     │ 2.41.5-0+deb13u1                  │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | └───────────────┴────────────────┴──────────┴──────────────┴───────────────────────────────────┴───────────────┴─────────────────────────────────────────────────────────────┘
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Python (python-pkg)
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ===================
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Total: 6 (HIGH: 6, CRITICAL: 0)
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ┌─────────────────────┬─────────────────────┬──────────┬────────┬───────────────────┬───────────────┬────────────────────────────────────────────────────────────┐
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │       Library       │    Vulnerability    │ Severity │ Status │ Installed Version │ Fixed Version │                           Title                            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├─────────────────────┼─────────────────────┼──────────┼────────┼───────────────────┼───────────────┼────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ gunicorn (METADATA) │ CVE-2024-1135       │ HIGH     │ fixed  │ 21.2.0            │ 22.0.0        │ python-gunicorn: HTTP Request Smuggling due to improper    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     │                     │          │        │                   │               │ validation of Transfer-Encoding headers                    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     │                     │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2024-1135                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     ├─────────────────────┤          │        │                   │               ├────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     │ CVE-2024-6827       │          │        │                   │               │ gunicorn: HTTP Request Smuggling in benoitc/gunicorn       │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     │                     │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2024-6827                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├─────────────────────┼─────────────────────┤          │        ├───────────────────┼───────────────┼────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ msgpack             │ GHSA-6v7p-g79w-8964 │          │        │ 1.1.2             │ 1.2.1         │ MessagePack for Python: Out-of-bounds read / crash on      │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     │                     │          │        │                   │               │ Unpacker reuse after a...                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     │                     │          │        │                   │               │ https://github.com/advisories/GHSA-6v7p-g79w-8964          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├─────────────────────┼─────────────────────┤          │        ├───────────────────┼───────────────┼────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ setuptools          │ CVE-2025-47273      │          │        │ 70.3.0            │ 78.1.1        │ setuptools: Path Traversal Vulnerability in setuptools     │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     │                     │          │        │                   │               │ PackageIndex                                               │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     │                     │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2025-47273                 │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├─────────────────────┼─────────────────────┤          │        ├───────────────────┼───────────────┼────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ urllib3             │ CVE-2026-97687      │          │        │ 2.7.0             │ 2.8.0         │ urllib3: urllib3: Traffic interception via HTTPS proxy TLS │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     │                     │          │        │                   │               │ configuration override                                     │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     │                     │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2026-97687                 │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     ├─────────────────────┤          │        │                   │               ├────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     │ CVE-2026-97689      │          │        │                   │               │ urllib3: urllib3: Denial of Service via unbounded memory   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     │                     │          │        │                   │               │ allocation in chunk parser...                              │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │                     │                     │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2026-97689                 │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | └─────────────────────┴─────────────────────┴──────────┴────────┴───────────────────┴───────────────┴────────────────────────────────────────────────────────────┘
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Main Trivy scan of the exact image tarball [25.501211417s]
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Main actions/upload-artifact@v5
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | With the provided path, there will be 1 file uploaded
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Artifact name is valid!
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Root directory input is valid!
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Beginning upload of artifact content to blob storage
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Uploaded bytes 107933
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Finished uploading artifact content to blob storage!
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | SHA256 digest of uploaded artifact zip is b1aefd71c08a6dd1bb1725e11877e6ea644519c7fba083ffabeecbfd012fd2b5
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Finalizing artifact upload
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Artifact report-image.zip successfully finalized. Artifact ID 1329040791
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Artifact report-image has been successfully uploaded! Final size is 107933 bytes. Artifact ID is 1329040791
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/1329040791
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Main actions/upload-artifact@v5 [2.390680083s]
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] Cleaning up container for job 8 Container Image Scan (Trivy)
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/9 Security Gate               ] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/9 Security Gate               ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ☁  git clone 'https://github.com/actions/download-artifact' # ref=v7
[S17 DevSecOps - PassGuard/9 Security Gate               ] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ✅  Success - Main actions/checkout@v6 [2.03982175s]
[S17 DevSecOps - PassGuard/9 Security Gate               ] ⭐ Run Main actions/setup-python@v6
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Successfully set up CPython (3.13.16)
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ✅  Success - Main actions/setup-python@v6 [1.277890666s]
[S17 DevSecOps - PassGuard/9 Security Gate               ] ⭐ Run Main actions/download-artifact@v7
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Found 6 artifact(s)
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Filtering artifacts by pattern 'report-*'
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Preparing to download the following artifacts:
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | - report-secrets (ID: 3564946595, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | - report-sca (ID: 2543950051, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | - report-image (ID: 1329040791, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | - report-sast (ID: 862344689, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/reports
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/reports
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/reports
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/reports
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SHA256 digest of downloaded artifact is 0c093a9798927e9c294044fd23f4b0823020b918e7c8ce68fc0441d88b5d3259
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SHA256 digest of downloaded artifact is 9cc5621ee7afb2f7ed3f40d31bb62d1569e10ea7ebc231b9f916818d131f3cdd
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SHA256 digest of downloaded artifact is 5625bd12a91c8c73dddee4ae07735660a527f2555e3eb4ea29dd05ac0483886d
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SHA256 digest of downloaded artifact is b1aefd71c08a6dd1bb1725e11877e6ea644519c7fba083ffabeecbfd012fd2b5
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Total of 4 artifact(s) downloaded
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Download artifact has finished successfully
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ✅  Success - Main actions/download-artifact@v7 [948.908ms]
[S17 DevSecOps - PassGuard/9 Security Gate               ] ⭐ Run Main Apply security/policy.toml
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | bandit.json
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | gitleaks.json
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | pip-audit.json
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | trivy-image.json
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | CONTROL  TOOL       FINDINGS BLOCKING  RESULT THRESHOLD
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SAST     bandit            2        1  FAIL   severity HIGH/MEDIUM, confidence >= MEDIUM
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SCA      pip-audit         4        4  FAIL   max 0 known vulns
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Secrets  gitleaks          4        4  FAIL   max 0 findings
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Image    trivy           173        6  FAIL   CRITICAL/HIGH with a fix
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [SAST] B324 HIGH/HIGH src/passguard/strength.py:114 Use of weak MD5 hash for security. Consider usedforsecurity=False
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [SCA] gunicorn==21.2.0 PYSEC-2026-1434 (GHSA-w3h3-4rj7-4ph4, CVE-2024-1135) fix: 22.0.0
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [SCA] gunicorn==21.2.0 PYSEC-2026-1433 (GHSA-hc5x-x2vx-497g, CVE-2024-6827) fix: 22.0.0
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [SCA] gunicorn==21.2.0 PYSEC-2026-1434 (GHSA-w3h3-4rj7-4ph4, CVE-2024-1135) fix: 22.0.0
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [SCA] gunicorn==21.2.0 PYSEC-2026-1433 (GHSA-hc5x-x2vx-497g, CVE-2024-6827) fix: 22.0.0
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [Secrets] github-pat logs/red.log:302 secret=REDACTED
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [Secrets] github-pat logs/red.log:308 secret=REDACTED
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [Secrets] passguard-hardcoded-upstream-token src/passguard/config.py:2 secret=REDACTED
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [Secrets] github-pat src/passguard/config.py:2 secret=REDACTED
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [Image] HIGH CVE-2024-1135 gunicorn 21.2.0 -> 22.0.0
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [Image] HIGH CVE-2024-6827 gunicorn 21.2.0 -> 22.0.0
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [Image] HIGH GHSA-6v7p-g79w-8964 msgpack 1.1.2 -> 1.2.1
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [Image] HIGH CVE-2025-47273 setuptools 70.3.0 -> 78.1.1
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [Image] HIGH CVE-2026-97687 urllib3 2.7.0 -> 2.8.0
[S17 DevSecOps - PassGuard/9 Security Gate               ]   |   [Image] HIGH CVE-2026-97689 urllib3 2.7.0 -> 2.8.0
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | 
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SECURITY GATE: BLOCKED by SAST, SCA, Secrets, Image
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ❌  Failure - Main Apply security/policy.toml [361.558875ms]
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ⚙  Summary - ### Security gate

| Control | Tool | Findings | Blocking | Result |
|---|---|---|---|---|
| SAST | bandit | 2 | 1 | FAIL |
| SCA | pip-audit | 4 | 4 | FAIL |
| Secrets | gitleaks | 4 | 4 | FAIL |
| Image | trivy | 173 | 6 | FAIL |

**BLOCKED by SAST, SCA, Secrets, Image**
[S17 DevSecOps - PassGuard/9 Security Gate               ] exitcode '1': failure
[S17 DevSecOps - PassGuard/9 Security Gate               ] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/9 Security Gate               ] Cleaning up container for job 9 Security Gate
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/9 Security Gate               ] 🏁  Job failed
Error: Job '9 Security Gate' failed

act exit code: 1
--- job results
  1 Code: succeeded
  2 Build: succeeded
  3 Unit Test: succeeded
  4 SAST (Bandit): succeeded
  5 SCA (pip-audit): succeeded
  6 Secret Scan (gitleaks): succeeded
  7 Docker Build: succeeded
  8 Container Image Scan (Trivy): succeeded
  9 Security Gate: failed
  10 Push Image: never started
  11 Deploy to Kubernetes: never started

==============================================================
RED RUN - STEP 3: restore the clean code
==============================================================
0
gunicorn==26.2.0
__init__.py
static
strength.py
templates
```

## 2. `./run.sh green && ./run.sh cleanup`

```text

==============================================================
GREEN RUN - STEP 1: start the local registry that stands in for ghcr.io
==============================================================
local registry: s17-registry registry:2 127.0.0.1:5056->5000/tcp

==============================================================
GREEN RUN - STEP 2: run the clean pipeline
==============================================================
$ act push -W .github/workflows/devsecops.yml -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest --container-architecture linux/arm64 \
      --artifact-server-path .act/artifacts --artifact-server-port 34568 --rm --action-offline-mode

time="2026-10-08T00:02:44+05:30" level=info msg="Using docker host 'unix:///var/run/docker.sock', and daemon socket 'unix:///var/run/docker.sock'"
time="2026-10-08T00:02:44+05:30" level=info msg="Start server on http://100.128.166.254:34568"
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/1 Code] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/1 Code]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Main actions/checkout@v6 [1.87420525s]
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Main actions/setup-python@v6
[S17 DevSecOps - PassGuard/1 Code]   | Successfully set up CPython (3.13.16)
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Main actions/setup-python@v6 [1.912935625s]
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Main Commit under test
[S17 DevSecOps - PassGuard/1 Code]   | commit 888cd817ad3fcef35caa73374366c0af95030157 on refs/heads/main (event push)
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Main Commit under test [142.430833ms]
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Main Lint (ruff)
[S17 DevSecOps - PassGuard/1 Code]   | 6 files already formatted
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Main Lint (ruff) [849.657ms]
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Post actions/setup-python@v6
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Post actions/setup-python@v6 [291.122292ms]
[S17 DevSecOps - PassGuard/1 Code] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/1 Code] Cleaning up container for job 1 Code
[S17 DevSecOps - PassGuard/1 Code]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/1 Code] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/2 Build] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/2 Build]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S17 DevSecOps - PassGuard/2 Build]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Main actions/checkout@v6 [1.59610875s]
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Main actions/setup-python@v6
[S17 DevSecOps - PassGuard/2 Build]   | Successfully set up CPython (3.13.16)
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Main actions/setup-python@v6 [1.159883792s]
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Main Build the wheel
[S17 DevSecOps - PassGuard/2 Build]   | * Creating isolated environment: venv+pip...
[S17 DevSecOps - PassGuard/2 Build]   | * Installing packages in isolated environment:
[S17 DevSecOps - PassGuard/2 Build]   |   - setuptools>=80
[S17 DevSecOps - PassGuard/2 Build]   |   - wheel
[S17 DevSecOps - PassGuard/2 Build]   | * Getting build dependencies for wheel...
[S17 DevSecOps - PassGuard/2 Build]   | running egg_info
[S17 DevSecOps - PassGuard/2 Build]   | creating src/passguard.egg-info
[S17 DevSecOps - PassGuard/2 Build]   | writing src/passguard.egg-info/PKG-INFO
[S17 DevSecOps - PassGuard/2 Build]   | writing dependency_links to src/passguard.egg-info/dependency_links.txt
[S17 DevSecOps - PassGuard/2 Build]   | writing requirements to src/passguard.egg-info/requires.txt
[S17 DevSecOps - PassGuard/2 Build]   | writing top-level names to src/passguard.egg-info/top_level.txt
[S17 DevSecOps - PassGuard/2 Build]   | writing manifest file 'src/passguard.egg-info/SOURCES.txt'
[S17 DevSecOps - PassGuard/2 Build]   | reading manifest file 'src/passguard.egg-info/SOURCES.txt'
[S17 DevSecOps - PassGuard/2 Build]   | writing manifest file 'src/passguard.egg-info/SOURCES.txt'
[S17 DevSecOps - PassGuard/2 Build]   | * Installed build dependency versions:
[S17 DevSecOps - PassGuard/2 Build]   |   - setuptools==84.0.0
[S17 DevSecOps - PassGuard/2 Build]   |   - wheel==0.48.0
[S17 DevSecOps - PassGuard/2 Build]   | * Building wheel...
[S17 DevSecOps - PassGuard/2 Build]   | running bdist_wheel
[S17 DevSecOps - PassGuard/2 Build]   | running build
[S17 DevSecOps - PassGuard/2 Build]   | running build_py
[S17 DevSecOps - PassGuard/2 Build]   | creating build/lib/passguard
[S17 DevSecOps - PassGuard/2 Build]   | copying src/passguard/__init__.py -> build/lib/passguard
[S17 DevSecOps - PassGuard/2 Build]   | copying src/passguard/strength.py -> build/lib/passguard
[S17 DevSecOps - PassGuard/2 Build]   | running egg_info
[S17 DevSecOps - PassGuard/2 Build]   | writing src/passguard.egg-info/PKG-INFO
[S17 DevSecOps - PassGuard/2 Build]   | writing dependency_links to src/passguard.egg-info/dependency_links.txt
[S17 DevSecOps - PassGuard/2 Build]   | writing requirements to src/passguard.egg-info/requires.txt
[S17 DevSecOps - PassGuard/2 Build]   | writing top-level names to src/passguard.egg-info/top_level.txt
[S17 DevSecOps - PassGuard/2 Build]   | reading manifest file 'src/passguard.egg-info/SOURCES.txt'
[S17 DevSecOps - PassGuard/2 Build]   | writing manifest file 'src/passguard.egg-info/SOURCES.txt'
[S17 DevSecOps - PassGuard/2 Build]   | creating build/lib/passguard/templates
[S17 DevSecOps - PassGuard/2 Build]   | copying src/passguard/templates/index.html -> build/lib/passguard/templates
[S17 DevSecOps - PassGuard/2 Build]   | creating build/lib/passguard/static
[S17 DevSecOps - PassGuard/2 Build]   | copying src/passguard/static/style.css -> build/lib/passguard/static
[S17 DevSecOps - PassGuard/2 Build]   | copying src/passguard/static/app.js -> build/lib/passguard/static
[S17 DevSecOps - PassGuard/2 Build]   | installing to build/bdist.linux-aarch64/wheel
[S17 DevSecOps - PassGuard/2 Build]   | running install
[S17 DevSecOps - PassGuard/2 Build]   | running install_lib
[S17 DevSecOps - PassGuard/2 Build]   | creating build/bdist.linux-aarch64/wheel
[S17 DevSecOps - PassGuard/2 Build]   | creating build/bdist.linux-aarch64/wheel/passguard
[S17 DevSecOps - PassGuard/2 Build]   | creating build/bdist.linux-aarch64/wheel/passguard/static
[S17 DevSecOps - PassGuard/2 Build]   | copying build/lib/passguard/static/style.css -> build/bdist.linux-aarch64/wheel/./passguard/static
[S17 DevSecOps - PassGuard/2 Build]   | copying build/lib/passguard/static/app.js -> build/bdist.linux-aarch64/wheel/./passguard/static
[S17 DevSecOps - PassGuard/2 Build]   | copying build/lib/passguard/__init__.py -> build/bdist.linux-aarch64/wheel/./passguard
[S17 DevSecOps - PassGuard/2 Build]   | copying build/lib/passguard/strength.py -> build/bdist.linux-aarch64/wheel/./passguard
[S17 DevSecOps - PassGuard/2 Build]   | creating build/bdist.linux-aarch64/wheel/passguard/templates
[S17 DevSecOps - PassGuard/2 Build]   | copying build/lib/passguard/templates/index.html -> build/bdist.linux-aarch64/wheel/./passguard/templates
[S17 DevSecOps - PassGuard/2 Build]   | running install_egg_info
[S17 DevSecOps - PassGuard/2 Build]   | Copying src/passguard.egg-info to build/bdist.linux-aarch64/wheel/./passguard-1.0.0-py3.13.egg-info
[S17 DevSecOps - PassGuard/2 Build]   | running install_scripts
[S17 DevSecOps - PassGuard/2 Build]   | creating build/bdist.linux-aarch64/wheel/passguard-1.0.0.dist-info/WHEEL
[S17 DevSecOps - PassGuard/2 Build]   | creating '/Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/dist/.tmp-yz2t73ka/passguard-1.0.0-py3-none-any.whl' and adding 'build/bdist.linux-aarch64/wheel' to it
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard/__init__.py'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard/strength.py'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard/static/app.js'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard/static/style.css'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard/templates/index.html'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard-1.0.0.dist-info/METADATA'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard-1.0.0.dist-info/WHEEL'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard-1.0.0.dist-info/top_level.txt'
[S17 DevSecOps - PassGuard/2 Build]   | adding 'passguard-1.0.0.dist-info/RECORD'
[S17 DevSecOps - PassGuard/2 Build]   | removing build/bdist.linux-aarch64/wheel
[S17 DevSecOps - PassGuard/2 Build]   | Successfully built passguard-1.0.0-py3-none-any.whl
[S17 DevSecOps - PassGuard/2 Build]   | total 8
[S17 DevSecOps - PassGuard/2 Build]   | -rw-r--r-- 1 root root 6023 Oct  7 18:32 passguard-1.0.0-py3-none-any.whl
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Main Build the wheel [2.905851291s]
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Main actions/upload-artifact@v5
[S17 DevSecOps - PassGuard/2 Build]   | With the provided path, there will be 1 file uploaded
[S17 DevSecOps - PassGuard/2 Build]   | Artifact name is valid!
[S17 DevSecOps - PassGuard/2 Build]   | Root directory input is valid!
[S17 DevSecOps - PassGuard/2 Build]   | Beginning upload of artifact content to blob storage
[S17 DevSecOps - PassGuard/2 Build]   | Uploaded bytes 5499
[S17 DevSecOps - PassGuard/2 Build]   | Finished uploading artifact content to blob storage!
[S17 DevSecOps - PassGuard/2 Build]   | SHA256 digest of uploaded artifact zip is e5ab6f0db944be6b62adbdbf2714fd62d80eb7b63cf2cebb5b487a6d8b134c9a
[S17 DevSecOps - PassGuard/2 Build]   | Finalizing artifact upload
[S17 DevSecOps - PassGuard/2 Build]   | Artifact wheel.zip successfully finalized. Artifact ID 473058556
[S17 DevSecOps - PassGuard/2 Build]   | Artifact wheel has been successfully uploaded! Final size is 5499 bytes. Artifact ID is 473058556
[S17 DevSecOps - PassGuard/2 Build]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/473058556
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Main actions/upload-artifact@v5 [960.913667ms]
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Post actions/setup-python@v6
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Post actions/setup-python@v6 [229.415709ms]
[S17 DevSecOps - PassGuard/2 Build] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/2 Build] Cleaning up container for job 2 Build
[S17 DevSecOps - PassGuard/2 Build]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/2 Build] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/3 Unit Test] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/3 Unit Test]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S17 DevSecOps - PassGuard/3 Unit Test]   ☁  git clone 'https://github.com/actions/download-artifact' # ref=v7
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Main actions/checkout@v6 [1.90874675s]
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Main actions/setup-python@v6
[S17 DevSecOps - PassGuard/3 Unit Test]   | Successfully set up CPython (3.13.16)
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Main actions/setup-python@v6 [1.259756167s]
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Main actions/download-artifact@v7
[S17 DevSecOps - PassGuard/3 Unit Test]   | Downloading single artifact
[S17 DevSecOps - PassGuard/3 Unit Test]   | Preparing to download the following artifacts:
[S17 DevSecOps - PassGuard/3 Unit Test]   | - wheel (ID: 473058556, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/3 Unit Test]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/3 Unit Test]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/dist
[S17 DevSecOps - PassGuard/3 Unit Test]   | SHA256 digest of downloaded artifact is e5ab6f0db944be6b62adbdbf2714fd62d80eb7b63cf2cebb5b487a6d8b134c9a
[S17 DevSecOps - PassGuard/3 Unit Test]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/3 Unit Test]   | Total of 1 artifact(s) downloaded
[S17 DevSecOps - PassGuard/3 Unit Test]   | Download artifact has finished successfully
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Main actions/download-artifact@v7 [735.986583ms]
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Main Test the built wheel (not the source tree)
[S17 DevSecOps - PassGuard/3 Unit Test]   | ============================= test session starts ==============================
[S17 DevSecOps - PassGuard/3 Unit Test]   | platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0
[S17 DevSecOps - PassGuard/3 Unit Test]   | rootdir: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline
[S17 DevSecOps - PassGuard/3 Unit Test]   | configfile: pyproject.toml
[S17 DevSecOps - PassGuard/3 Unit Test]   | testpaths: tests
[S17 DevSecOps - PassGuard/3 Unit Test]   | plugins: cov-7.1.0, platformdirs-4.12.3
[S17 DevSecOps - PassGuard/3 Unit Test]   | collected 30 items
[S17 DevSecOps - PassGuard/3 Unit Test]   | 
[S17 DevSecOps - PassGuard/3 Unit Test]   | tests/test_api.py ............                                           [ 40%]
[S17 DevSecOps - PassGuard/3 Unit Test]   | tests/test_strength.py ..................                                [100%]
[S17 DevSecOps - PassGuard/3 Unit Test]   | 
[S17 DevSecOps - PassGuard/3 Unit Test]   | ================================ tests coverage ================================
[S17 DevSecOps - PassGuard/3 Unit Test]   | _______________ coverage: platform linux, python 3.13.16-final-0 _______________
[S17 DevSecOps - PassGuard/3 Unit Test]   | 
[S17 DevSecOps - PassGuard/3 Unit Test]   | Name                                                                                           Stmts   Miss  Cover
[S17 DevSecOps - PassGuard/3 Unit Test]   | ------------------------------------------------------------------------------------------------------------------
[S17 DevSecOps - PassGuard/3 Unit Test]   | /opt/hostedtoolcache/Python/3.13.16/arm64/lib/python3.13/site-packages/passguard/__init__.py      43      0   100%
[S17 DevSecOps - PassGuard/3 Unit Test]   | /opt/hostedtoolcache/Python/3.13.16/arm64/lib/python3.13/site-packages/passguard/config.py         1      1     0%
[S17 DevSecOps - PassGuard/3 Unit Test]   | /opt/hostedtoolcache/Python/3.13.16/arm64/lib/python3.13/site-packages/passguard/strength.py      62      1    98%
[S17 DevSecOps - PassGuard/3 Unit Test]   | ------------------------------------------------------------------------------------------------------------------
[S17 DevSecOps - PassGuard/3 Unit Test]   | TOTAL                                                                                            106      2    98%
[S17 DevSecOps - PassGuard/3 Unit Test]   | Required test coverage of 90% reached. Total coverage: 98.11%
[S17 DevSecOps - PassGuard/3 Unit Test]   | ============================== 30 passed in 0.34s ==============================
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Main Test the built wheel (not the source tree) [1.449074291s]
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Post actions/setup-python@v6
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Post actions/setup-python@v6 [295.737208ms]
[S17 DevSecOps - PassGuard/3 Unit Test] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/3 Unit Test] Cleaning up container for job 3 Unit Test
[S17 DevSecOps - PassGuard/3 Unit Test]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/3 Unit Test] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Main actions/checkout@v6 [1.668625333s]
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Main actions/setup-python@v6
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Successfully set up CPython (3.13.16)
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Main actions/setup-python@v6 [1.7789335s]
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Main Bandit
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	profile include tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	profile exclude tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	cli include tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	cli exclude tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [json]	INFO	JSON output written to file: reports/bandit.json
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	profile include tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	profile exclude tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	cli include tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	cli exclude tests: None
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	using config: pyproject.toml
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | [main]	INFO	running on Python 3.13.16
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Run started:2026-10-07 18:33:11.958163+00:00
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Test results:
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 	No issues identified.
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Code scanned:
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 	Total lines of code: 137
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 	Total lines skipped (#nosec): 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 	Total potential issues skipped due to specifically being disabled (e.g., #nosec BXXX): 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Run metrics:
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 	Total issues (by severity):
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		Undefined: 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		Low: 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		Medium: 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		High: 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 	Total issues (by confidence):
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		Undefined: 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		Low: 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		Medium: 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | 		High: 0
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Files skipped (0):
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Main Bandit [951.227792ms]
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Main actions/upload-artifact@v5
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | With the provided path, there will be 1 file uploaded
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Artifact name is valid!
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Root directory input is valid!
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Beginning upload of artifact content to blob storage
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Uploaded bytes 382
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Finished uploading artifact content to blob storage!
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | SHA256 digest of uploaded artifact zip is 3c7436e74ef6aec51a19d5cd990cbcd475557531814fe86ebe6e007e4c9a1867
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Finalizing artifact upload
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Artifact report-sast.zip successfully finalized. Artifact ID 862344689
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Artifact report-sast has been successfully uploaded! Final size is 382 bytes. Artifact ID is 862344689
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/862344689
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Main actions/upload-artifact@v5 [1.06105975s]
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Post actions/setup-python@v6
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Post actions/setup-python@v6 [221.60225ms]
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] Cleaning up container for job 4 SAST (Bandit)
[S17 DevSecOps - PassGuard/4 SAST (Bandit)]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/4 SAST (Bandit)] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Main actions/checkout@v6 [1.943239792s]
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Main actions/setup-python@v6
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Successfully set up CPython (3.13.16)
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Main actions/setup-python@v6 [1.315545416s]
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Main pip-audit on the pinned requirements
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | No known vulnerabilities found
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | No known vulnerabilities found
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Main pip-audit on the pinned requirements [9.219883625s]
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Main actions/upload-artifact@v5
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | With the provided path, there will be 1 file uploaded
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Artifact name is valid!
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Root directory input is valid!
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Beginning upload of artifact content to blob storage
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Uploaded bytes 305
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Finished uploading artifact content to blob storage!
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | SHA256 digest of uploaded artifact zip is d812128f5b6082276857f4329e4778ff891bb9051094434bc7980629a43d41a0
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Finalizing artifact upload
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Artifact report-sca.zip successfully finalized. Artifact ID 2543950051
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Artifact report-sca has been successfully uploaded! Final size is 305 bytes. Artifact ID is 2543950051
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/2543950051
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Main actions/upload-artifact@v5 [1.013436291s]
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Post actions/setup-python@v6
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Post actions/setup-python@v6 [270.834792ms]
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] Cleaning up container for job 5 SCA (pip-audit)
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/5 SCA (pip-audit)] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ✅  Success - Main actions/checkout@v6 [2.199520417s]
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] ⭐ Run Main Install gitleaks (pinned, checksum verified)
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | installed gitleaks (arm64, sha256 verified) -> /root/.local/bin/gitleaks
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ✅  Success - Main Install gitleaks (pinned, checksum verified) [4.422709s]
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] ⭐ Run Main gitleaks
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | 6:33PM INF scanned ~238344 bytes (238.34 KB) in 31.5ms
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | 6:33PM INF no leaks found
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ✅  Success - Main gitleaks [421.088042ms]
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] ⭐ Run Main actions/upload-artifact@v5
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | With the provided path, there will be 1 file uploaded
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Artifact name is valid!
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Root directory input is valid!
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Beginning upload of artifact content to blob storage
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Uploaded bytes 145
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Finished uploading artifact content to blob storage!
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | SHA256 digest of uploaded artifact zip is 850bf48ea1fdcb42d3377c48373d4739c528bdebd8036442cb5785a146bc054e
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Finalizing artifact upload
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Artifact report-secrets.zip successfully finalized. Artifact ID 3564946595
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Artifact report-secrets has been successfully uploaded! Final size is 145 bytes. Artifact ID is 3564946595
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/3564946595
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ✅  Success - Main actions/upload-artifact@v5 [723.724625ms]
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] Cleaning up container for job 6 Secret Scan (gitleaks)
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/6 Secret Scan (gitleaks)] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/7 Docker Build          ] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/7 Docker Build          ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ☁  git clone 'https://github.com/actions/download-artifact' # ref=v7
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S17 DevSecOps - PassGuard/7 Docker Build          ] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ✅  Success - Main actions/checkout@v6 [1.807730875s]
[S17 DevSecOps - PassGuard/7 Docker Build          ] ⭐ Run Main actions/download-artifact@v7
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Downloading single artifact
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Preparing to download the following artifacts:
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | - wheel (ID: 473058556, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/dist
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | SHA256 digest of downloaded artifact is e5ab6f0db944be6b62adbdbf2714fd62d80eb7b63cf2cebb5b487a6d8b134c9a
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Total of 1 artifact(s) downloaded
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Download artifact has finished successfully
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ✅  Success - Main actions/download-artifact@v7 [896.293917ms]
[S17 DevSecOps - PassGuard/7 Docker Build          ] ⭐ Run Main docker build (from the tested wheel)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #0 building with "default" instance using docker driver
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #1 [internal] load build definition from Dockerfile
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #1 transferring dockerfile: 1.68kB done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #1 DONE 0.0s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #2 [internal] load metadata for docker.io/library/python:3.13-slim
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #2 DONE 0.0s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #3 [internal] load .dockerignore
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #3 transferring context: 150B done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #3 DONE 0.0s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #4 [build 1/4] FROM docker.io/library/python:3.13-slim@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #4 resolve docker.io/library/python:3.13-slim@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c 0.0s done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #4 CACHED
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #5 [internal] load build context
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #5 transferring context: 6.45kB done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #5 DONE 0.0s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #6 [build 2/4] COPY requirements.txt /tmp/requirements.txt
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #6 CACHED
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #7 [build 3/4] COPY dist/*.whl /tmp/
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #7 DONE 0.2s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #8 [stage-1 2/3] RUN python -m pip uninstall --yes --root-user-action=ignore pip  && groupadd --gid 10001 app && useradd --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #8 1.265 Found existing installation: pip 26.2.1
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #8 1.306 Uninstalling pip-26.2.1:
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #8 1.497   Successfully uninstalled pip-26.2.1
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #8 DONE 1.6s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 [build 4/4] RUN python -m venv /venv  && /venv/bin/pip install -r /tmp/requirements.txt  && /venv/bin/pip install --no-deps /tmp/*.whl  && /venv/bin/pip uninstall --yes pip
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 2.873 Collecting blinker==1.9.0 (from -r /tmp/requirements.txt (line 3))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.071   Downloading blinker-1.9.0-py3-none-any.whl.metadata (1.6 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.111 Collecting click==8.5.0 (from -r /tmp/requirements.txt (line 4))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.172   Downloading click-8.5.0-py3-none-any.whl.metadata (2.6 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.210 Collecting flask==3.1.3 (from -r /tmp/requirements.txt (line 5))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.273   Downloading flask-3.1.3-py3-none-any.whl.metadata (3.2 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.306 Collecting gunicorn==26.2.0 (from -r /tmp/requirements.txt (line 6))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.392   Downloading gunicorn-26.2.0-py3-none-any.whl.metadata (5.5 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.425 Collecting itsdangerous==2.2.0 (from -r /tmp/requirements.txt (line 7))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.482   Downloading itsdangerous-2.2.0-py3-none-any.whl.metadata (1.9 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.511 Collecting jinja2==3.1.6 (from -r /tmp/requirements.txt (line 8))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.545   Downloading jinja2-3.1.6-py3-none-any.whl.metadata (2.9 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.636 Collecting markupsafe==3.0.4 (from -r /tmp/requirements.txt (line 9))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.684   Downloading markupsafe-3.0.4-cp313-cp313-manylinux2014_aarch64.manylinux_2_17_aarch64.manylinux_2_28_aarch64.whl.metadata (2.7 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.712 Collecting werkzeug==3.1.9 (from -r /tmp/requirements.txt (line 10))
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.731   Downloading werkzeug-3.1.9-py3-none-any.whl.metadata (4.1 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.785 Downloading blinker-1.9.0-py3-none-any.whl (8.5 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.807 Downloading click-8.5.0-py3-none-any.whl (125 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 3.924 Downloading flask-3.1.3-py3-none-any.whl (103 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.015 Downloading gunicorn-26.2.0-py3-none-any.whl (228 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.092 Downloading itsdangerous-2.2.0-py3-none-any.whl (16 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.122 Downloading jinja2-3.1.6-py3-none-any.whl (134 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.198 Downloading markupsafe-3.0.4-cp313-cp313-manylinux2014_aarch64.manylinux_2_17_aarch64.manylinux_2_28_aarch64.whl (24 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.222 Downloading werkzeug-3.1.9-py3-none-any.whl (228 kB)
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.256 Installing collected packages: markupsafe, itsdangerous, gunicorn, click, blinker, werkzeug, jinja2, flask
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.500 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.501 Successfully installed blinker-1.9.0 click-8.5.0 flask-3.1.3 gunicorn-26.2.0 itsdangerous-2.2.0 jinja2-3.1.6 markupsafe-3.0.4 werkzeug-3.1.9
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.683 Processing ./tmp/passguard-1.0.0-py3-none-any.whl
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.690 Installing collected packages: passguard
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.695 Successfully installed passguard-1.0.0
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.835 Found existing installation: pip 26.2.1
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.847 Uninstalling pip-26.2.1:
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 4.849   Successfully uninstalled pip-26.2.1
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #9 DONE 4.9s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #10 [stage-1 3/3] COPY --from=build /venv /venv
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #10 DONE 0.1s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | 
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 exporting to image
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 exporting layers
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 exporting layers 0.2s done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 exporting manifest sha256:fba32e34992fd3feb000db6c7ce508303b6cfbc3cdb154415510d8647d8c213f done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 exporting config sha256:0048257bbc89af50a6dc0f02e07ffd94d618eee6966ad38a20b845c2926305c0 done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 naming to docker.io/library/passguard:888cd81 done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 unpacking to docker.io/library/passguard:888cd81 0.0s done
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | #11 DONE 0.3s
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | -rw------- 1 root root 44M Oct  7 18:33 dist/image.tar
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ✅  Success - Main docker build (from the tested wheel) [6.936905125s]
[S17 DevSecOps - PassGuard/7 Docker Build          ] ⭐ Run Main actions/upload-artifact@v5
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | With the provided path, there will be 1 file uploaded
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Artifact name is valid!
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Root directory input is valid!
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Beginning upload of artifact content to blob storage
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Uploaded bytes 8388608
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Uploaded bytes 16777216
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Uploaded bytes 25165824
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Uploaded bytes 33554432
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Uploaded bytes 41943040
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Uploaded bytes 45159900
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Finished uploading artifact content to blob storage!
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | SHA256 digest of uploaded artifact zip is 3288c2dda1c72d31d916478d568cc5ca6328f994ac360eb3525d6330ce961a83
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Finalizing artifact upload
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Artifact image.zip successfully finalized. Artifact ID 3008443898
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Artifact image has been successfully uploaded! Final size is 45159900 bytes. Artifact ID is 3008443898
[S17 DevSecOps - PassGuard/7 Docker Build          ]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/3008443898
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ✅  Success - Main actions/upload-artifact@v5 [2.235724333s]
[S17 DevSecOps - PassGuard/7 Docker Build          ] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/7 Docker Build          ] Cleaning up container for job 7 Docker Build
[S17 DevSecOps - PassGuard/7 Docker Build          ]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/7 Docker Build          ] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ☁  git clone 'https://github.com/actions/download-artifact' # ref=v7
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ☁  git clone 'https://github.com/actions/upload-artifact' # ref=v5
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Main actions/checkout@v6 [1.634838666s]
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Main actions/download-artifact@v7
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Downloading single artifact
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Preparing to download the following artifacts:
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | - image (ID: 3008443898, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/dist
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | SHA256 digest of downloaded artifact is 3288c2dda1c72d31d916478d568cc5ca6328f994ac360eb3525d6330ce961a83
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Total of 1 artifact(s) downloaded
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Download artifact has finished successfully
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Main actions/download-artifact@v7 [1.184689708s]
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Main Install Trivy (pinned, checksum verified)
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | installed trivy (arm64, sha256 verified) -> /root/.local/bin/trivy
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Main Install Trivy (pinned, checksum verified) [7.40129325s]
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Main Trivy scan of the exact image tarball
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 2026-10-07T18:34:26Z	WARN	[report] No enabled scanners found. Summary table will not be displayed.
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | For OSS Maintainers: VEX Notice
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | --------------------------------
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | If you're an OSS maintainer and Trivy has detected vulnerabilities in your project that you believe are not actually exploitable, consider issuing a VEX (Vulnerability Exploitability eXchange) statement.
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | VEX allows you to communicate the actual status of vulnerabilities in your project, improving security transparency and reducing false positives for your users.
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Learn more and start using VEX: https://trivy.dev/docs/v0.74/guide/supply-chain/vex/repo#publishing-vex-documents
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | To disable this notice, set the TRIVY_DISABLE_VEX_NOTICE environment variable.
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | dist/image.tar (debian 13.7)
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ============================
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Total: 44 (HIGH: 44, CRITICAL: 0)
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | 
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ┌───────────────┬────────────────┬──────────┬──────────────┬───────────────────────────────────┬───────────────┬─────────────────────────────────────────────────────────────┐
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │    Library    │ Vulnerability  │ Severity │    Status    │         Installed Version         │ Fixed Version │                            Title                            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┼──────────┼──────────────┼───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ bsdutils      │ CVE-2026-76642 │ HIGH     │ affected     │ 1:2.41.5-0+deb13u1                │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libacl1       │ CVE-2026-54369 │          │              │ 2.3.2-2+b1                        │               │ acl: Symlink traversal privilege escalation via libacl      │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ functions                                                   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-54369                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libblkid1     │ CVE-2026-76642 │          │              │ 2.41.5-0+deb13u1                  │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ liblastlog2-2 │ CVE-2026-76642 │          │              │                                   │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libmount1     │ CVE-2026-76642 │          │              │                                   │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libncursesw6  │ CVE-2025-69720 │          │              │ 6.5+20250216-2                    │               │ ncurses: ncurses: Buffer overflow vulnerability may lead to │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ arbitrary code execution.                                   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2025-69720                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libsmartcols1 │ CVE-2026-76642 │          │              │ 2.41.5-0+deb13u1                  │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libsystemd0   │ CVE-2026-16742 │          │              │ 257.13-1~deb13u1                  │               │ systemd: systemd-homed: Local privilege escalation via      │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ missing home-record signature verification                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-16742                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libtinfo6     │ CVE-2025-69720 │          │              │ 6.5+20250216-2                    │               │ ncurses: ncurses: Buffer overflow vulnerability may lead to │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ arbitrary code execution.                                   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2025-69720                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libudev1      │ CVE-2026-16742 │          │              │ 257.13-1~deb13u1                  │               │ systemd: systemd-homed: Local privilege escalation via      │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ missing home-record signature verification                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-16742                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ libuuid1      │ CVE-2026-76642 │          │              │ 2.41.5-0+deb13u1                  │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ login         │ CVE-2026-76642 │          │              │ 1:4.16.0-2+really2.41.5-0+deb13u1 │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ mount         │ CVE-2026-76642 │          │              │ 2.41.5-0+deb13u1                  │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          │              ├───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ ncurses-base  │ CVE-2025-69720 │          │              │ 6.5+20250216-2                    │               │ ncurses: ncurses: Buffer overflow vulnerability may lead to │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ arbitrary code execution.                                   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2025-69720                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┤                │          │              │                                   ├───────────────┤                                                             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ ncurses-bin   │                │          │              │                                   │               │                                                             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │                                                             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │                                                             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          ├──────────────┼───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ perl-base     │ CVE-2026-9538  │          │ fix_deferred │ 5.40.1-6+deb13u1                  │               │ perl-Archive-Tar: perl-Archive-Tar: Denial of Service via   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ crafted tar header with large entry...                      │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-9538                   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | ├───────────────┼────────────────┤          ├──────────────┼───────────────────────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │ util-linux    │ CVE-2026-76642 │          │ affected     │ 2.41.5-0+deb13u1                  │               │ util-linux: util-linux: failed external mount helper still  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ runs privileged X-mount post-hooks                          │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-76642                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78408 │          │              │                                   │               │ util-linux: util-linux: nsenter --join-cgroup leaks root    │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ cgroup migration authority                                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78408                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78409 │          │              │                                   │               │ util-linux: util-linux: X-mount.subdir detached-tree        │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ resolution can escape via intermediate symlinks             │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78409                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               ├────────────────┤          │              │                                   ├───────────────┼─────────────────────────────────────────────────────────────┤
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │ CVE-2026-78410 │          │              │                                   │               │ util-linux: util-linux: restricted bind mounts do not pin   │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ the source, allowing X-mount.owner/group/mode...            │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | │               │                │          │              │                                   │               │ https://avd.aquasec.com/nvd/cve-2026-78410                  │
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | └───────────────┴────────────────┴──────────┴──────────────┴───────────────────────────────────┴───────────────┴─────────────────────────────────────────────────────────────┘
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Main Trivy scan of the exact image tarball [23.629909875s]
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Main actions/upload-artifact@v5
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | With the provided path, there will be 1 file uploaded
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Artifact name is valid!
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Root directory input is valid!
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Beginning upload of artifact content to blob storage
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Uploaded bytes 101292
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Finished uploading artifact content to blob storage!
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | SHA256 digest of uploaded artifact zip is 333817c39db0aec51213f4ab6e2cdc67e1952fdf14f598f976888c3a4a6811d4
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Finalizing artifact upload
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Artifact report-image.zip successfully finalized. Artifact ID 1329040791
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Artifact report-image has been successfully uploaded! Final size is 101292 bytes. Artifact ID is 1329040791
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   | Artifact download URL: https://github.com/bypratyush/devops-assignment/actions/runs/1/artifacts/1329040791
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Main actions/upload-artifact@v5 [633.365084ms]
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] Cleaning up container for job 8 Container Image Scan (Trivy)
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/8 Container Image Scan (Trivy)] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/9 Security Gate               ] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/9 Security Gate               ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ☁  git clone 'https://github.com/actions/setup-python' # ref=v6
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ☁  git clone 'https://github.com/actions/download-artifact' # ref=v7
[S17 DevSecOps - PassGuard/9 Security Gate               ] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ✅  Success - Main actions/checkout@v6 [1.2780755s]
[S17 DevSecOps - PassGuard/9 Security Gate               ] ⭐ Run Main actions/setup-python@v6
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Successfully set up CPython (3.13.16)
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ✅  Success - Main actions/setup-python@v6 [796.177ms]
[S17 DevSecOps - PassGuard/9 Security Gate               ] ⭐ Run Main actions/download-artifact@v7
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Found 6 artifact(s)
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Filtering artifacts by pattern 'report-*'
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Preparing to download the following artifacts:
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | - report-secrets (ID: 3564946595, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | - report-sca (ID: 2543950051, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | - report-image (ID: 1329040791, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | - report-sast (ID: 862344689, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/reports
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/reports
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/reports
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/reports
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SHA256 digest of downloaded artifact is 850bf48ea1fdcb42d3377c48373d4739c528bdebd8036442cb5785a146bc054e
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SHA256 digest of downloaded artifact is 3c7436e74ef6aec51a19d5cd990cbcd475557531814fe86ebe6e007e4c9a1867
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SHA256 digest of downloaded artifact is d812128f5b6082276857f4329e4778ff891bb9051094434bc7980629a43d41a0
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SHA256 digest of downloaded artifact is 333817c39db0aec51213f4ab6e2cdc67e1952fdf14f598f976888c3a4a6811d4
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Total of 4 artifact(s) downloaded
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Download artifact has finished successfully
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ✅  Success - Main actions/download-artifact@v7 [500.811875ms]
[S17 DevSecOps - PassGuard/9 Security Gate               ] ⭐ Run Main Apply security/policy.toml
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | bandit.json
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | gitleaks.json
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | pip-audit.json
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | trivy-image.json
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | CONTROL  TOOL       FINDINGS BLOCKING  RESULT THRESHOLD
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SAST     bandit            0        0  PASS   severity HIGH/MEDIUM, confidence >= MEDIUM
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SCA      pip-audit         0        0  PASS   max 0 known vulns
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Secrets  gitleaks          0        0  PASS   max 0 findings
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | Image    trivy           165        0  PASS   CRITICAL/HIGH with a fix
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | 
[S17 DevSecOps - PassGuard/9 Security Gate               ]   | SECURITY GATE: PASSED - image may be pushed
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ✅  Success - Main Apply security/policy.toml [106.682042ms]
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ⚙  Summary - ### Security gate

| Control | Tool | Findings | Blocking | Result |
|---|---|---|---|---|
| SAST | bandit | 0 | 0 | PASS |
| SCA | pip-audit | 0 | 0 | PASS |
| Secrets | gitleaks | 0 | 0 | PASS |
| Image | trivy | 165 | 0 | PASS |

**PASSED - image may be pushed**
[S17 DevSecOps - PassGuard/9 Security Gate               ] ⭐ Run Post actions/setup-python@v6
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ✅  Success - Post actions/setup-python@v6 [129.438875ms]
[S17 DevSecOps - PassGuard/9 Security Gate               ] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/9 Security Gate               ] Cleaning up container for job 9 Security Gate
[S17 DevSecOps - PassGuard/9 Security Gate               ]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/9 Security Gate               ] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/10 Push Image                 ] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/10 Push Image                 ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/10 Push Image                 ]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/10 Push Image                 ]   ☁  git clone 'https://github.com/actions/download-artifact' # ref=v7
[S17 DevSecOps - PassGuard/10 Push Image                 ]   ☁  git clone 'https://github.com/docker/login-action' # ref=v4
[S17 DevSecOps - PassGuard/10 Push Image                 ] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/10 Push Image                 ]   ✅  Success - Main actions/checkout@v6 [1.091352167s]
[S17 DevSecOps - PassGuard/10 Push Image                 ] ⭐ Run Main actions/download-artifact@v7
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | Downloading single artifact
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | Preparing to download the following artifacts:
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | - image (ID: 3008443898, Size: 96, Expected Digest: undefined)
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | Redirecting to blob download url: http://100.128.166.254:34568/twirp/github.actions.results.api.v1.ArtifactService/DownloadArtifact
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | Starting download of artifact to: /Users/pratyushmohanty/Devops-assignment/devsecops-pipeline/dist
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | SHA256 digest of downloaded artifact is 3288c2dda1c72d31d916478d568cc5ca6328f994ac360eb3525d6330ce961a83
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | Artifact download completed successfully.
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | Total of 1 artifact(s) downloaded
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | Download artifact has finished successfully
[S17 DevSecOps - PassGuard/10 Push Image                 ]   ✅  Success - Main actions/download-artifact@v7 [994.892291ms]
[S17 DevSecOps - PassGuard/10 Push Image                 ] ⭐ Run Main Push the scanned image
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | Loaded image: passguard:888cd81
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | The push refers to repository [localhost:5056/bypratyush/passguard]
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | bbeda6b4abb7: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | a2c5ac708d8b: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | e41644b4b81a: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 1400433f1bd4: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 74202e18a58b: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 488f54626717: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | bbeda6b4abb7: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | a2c5ac708d8b: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | e41644b4b81a: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 1400433f1bd4: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 74202e18a58b: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 488f54626717: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | bbeda6b4abb7: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | a2c5ac708d8b: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | e41644b4b81a: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 1400433f1bd4: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 74202e18a58b: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 488f54626717: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | a2c5ac708d8b: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | e41644b4b81a: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 1400433f1bd4: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 74202e18a58b: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 488f54626717: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | bbeda6b4abb7: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | a2c5ac708d8b: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | e41644b4b81a: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 1400433f1bd4: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 74202e18a58b: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 488f54626717: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | bbeda6b4abb7: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | bbeda6b4abb7: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | a2c5ac708d8b: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | e41644b4b81a: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 1400433f1bd4: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 74202e18a58b: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 488f54626717: Waiting
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 1400433f1bd4: Pushed
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 74202e18a58b: Pushed
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 488f54626717: Pushed
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | a2c5ac708d8b: Pushed
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | e41644b4b81a: Pushed
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | bbeda6b4abb7: Pushed
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | 888cd81: digest: sha256:fba32e34992fd3feb000db6c7ce508303b6cfbc3cdb154415510d8647d8c213f size: 1436
[S17 DevSecOps - PassGuard/10 Push Image                 ]   | pushed localhost:5056/bypratyush/passguard@sha256:fba32e34992fd3feb000db6c7ce508303b6cfbc3cdb154415510d8647d8c213f
[S17 DevSecOps - PassGuard/10 Push Image                 ]   ✅  Success - Main Push the scanned image [1.60348375s]
[S17 DevSecOps - PassGuard/10 Push Image                 ] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/10 Push Image                 ] Cleaning up container for job 10 Push Image
[S17 DevSecOps - PassGuard/10 Push Image                 ]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/10 Push Image                 ] 🏁  Job succeeded
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] ⭐ Run Set up job
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] 🚀  Start image=ghcr.io/catthehacker/ubuntu:act-latest
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   ✅  Success - Set up job
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   ☁  git clone 'https://github.com/docker/login-action' # ref=v4
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] ⭐ Run Main actions/checkout@v6
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   ✅  Success - Main actions/checkout@v6 [1.631739708s]
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] ⭐ Run Main Install kind and kubectl (pinned, checksum verified)
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | installed kind (arm64, sha256 verified) -> /root/.local/bin/kind
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | installed kubectl (arm64, sha256 verified) -> /root/.local/bin/kubectl
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   ✅  Success - Main Install kind and kubectl (pinned, checksum verified) [11.8636225s]
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] ⭐ Run Main Pull the pushed image by digest
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | localhost:5056/bypratyush/passguard@sha256:fba32e34992fd3feb000db6c7ce508303b6cfbc3cdb154415510d8647d8c213f: Pulling from bypratyush/passguard
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Digest: sha256:fba32e34992fd3feb000db6c7ce508303b6cfbc3cdb154415510d8647d8c213f
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Status: Image is up to date for localhost:5056/bypratyush/passguard@sha256:fba32e34992fd3feb000db6c7ce508303b6cfbc3cdb154415510d8647d8c213f
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | localhost:5056/bypratyush/passguard@sha256:fba32e34992fd3feb000db6c7ce508303b6cfbc3cdb154415510d8647d8c213f
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   ✅  Success - Main Pull the pushed image by digest [847.270167ms]
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] ⭐ Run Main Create an ephemeral kind cluster
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Creating cluster "devsecops-ci" ...
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  • Ensuring node image (kindest/node:v1.37.0) 🖼️  ...
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  ✓ Ensuring node image (kindest/node:v1.37.0) 🖼️
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  • Preparing nodes 📦   ...
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  ✓ Preparing nodes 📦 
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  • Writing configuration 📜  ...
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  ✓ Writing configuration 📜
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  • Starting control-plane 🕹️  ...
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  ✓ Starting control-plane 🕹️
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  • Installing CNI 🔌  ...
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  ✓ Installing CNI 🔌
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  • Installing StorageClass 💾  ...
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  ✓ Installing StorageClass 💾
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  • Waiting ≤ 2m0s for control-plane = Ready ⏳  ...
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  ✓ Waiting ≤ 2m0s for control-plane = Ready ⏳
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   |  • Ready after 18s 💚
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Set kubectl context to "kind-devsecops-ci"
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | You can now use your cluster with:
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | 
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | kubectl cluster-info --context kind-devsecops-ci
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | 
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Not sure what to do next? 😅  Check out https://kind.sigs.k8s.io/docs/user/quick-start/
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   ✅  Success - Main Create an ephemeral kind cluster [28.9031095s]
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] ⭐ Run Main Load the image into the cluster nodes
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Image: "passguard:deploy-888cd81" with ID "sha256:fba32e34992fd3feb000db6c7ce508303b6cfbc3cdb154415510d8647d8c213f" not yet present on node "devsecops-ci-control-plane", loading...
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   ✅  Success - Main Load the image into the cluster nodes [6.397652917s]
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] ⭐ Run Main kubectl apply
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Client Version: v1.37.1
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Kustomize Version: v5.8.1
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Server Version: v1.37.0
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | namespace/passguard created
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | service/passguard created
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | deployment.apps/passguard created
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Waiting for deployment "passguard" rollout to finish: 0 of 2 updated replicas are available...
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Waiting for deployment "passguard" rollout to finish: 1 of 2 updated replicas are available...
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | deployment "passguard" successfully rolled out
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | NAME                        READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                     SELECTOR
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | deployment.apps/passguard   2/2     2            2           3s    passguard    passguard:deploy-888cd81   app=passguard
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | 
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | NAME                             READY   STATUS    RESTARTS   AGE   IP           NODE                         NOMINATED NODE   READINESS GATES
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | pod/passguard-54df84ffd9-glw9t   1/1     Running   0          3s    10.244.0.5   devsecops-ci-control-plane   <none>           <none>
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | pod/passguard-54df84ffd9-v28rs   1/1     Running   0          3s    10.244.0.6   devsecops-ci-control-plane   <none>           <none>
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | 
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | NAME                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE   SELECTOR
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | service/passguard   ClusterIP   10.96.88.238   <none>        80/TCP    3s    app=passguard
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   ✅  Success - Main kubectl apply [3.8248355s]
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] ⭐ Run Main Smoke test through the Service
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | {"commit":"888cd817ad3fcef35caa73374366c0af95030157","version":"1.0.0"}
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | 
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | {"entropy_bits":164.7,"feedback":["Mix upper case, lower case, digits and symbols."],"label":"very strong","length":28,"score":4}
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | 
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | GET / -> HTTP 200
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   ✅  Success - Main Smoke test through the Service [1.190278958s]
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] ⭐ Run Main Prove the namespace refuses an insecure pod
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | rejected as expected:
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Error from server (Forbidden): pods "root-shell" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "root-shell" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "root-shell" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "root-shell" must set securityContext.runAsNonRoot=true), runAsUser=0 (pod must not set runAsUser=0), seccompProfile (pod or container "root-shell" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   ✅  Success - Main Prove the namespace refuses an insecure pod [160.033291ms]
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] ⭐ Run Main Delete the cluster
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Deleting cluster "devsecops-ci" ...
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   | Deleted nodes: ["devsecops-ci-control-plane"]
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   ✅  Success - Main Delete the cluster [1.569201416s]
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] ⭐ Run Complete job
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] Cleaning up container for job 11 Deploy to Kubernetes
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ]   ✅  Success - Complete job
[S17 DevSecOps - PassGuard/11 Deploy to Kubernetes       ] 🏁  Job succeeded

act exit code: 0
--- job results
  1 Code: succeeded
  2 Build: succeeded
  3 Unit Test: succeeded
  4 SAST (Bandit): succeeded
  5 SCA (pip-audit): succeeded
  6 Secret Scan (gitleaks): succeeded
  7 Docker Build: succeeded
  8 Container Image Scan (Trivy): succeeded
  9 Security Gate: succeeded
  10 Push Image: succeeded
  11 Deploy to Kubernetes: succeeded

==============================================================
GREEN RUN - STEP 3: registry contents and leftovers
==============================================================
{"repositories":["bypratyush/passguard"]}

{"name":"bypratyush/passguard","tags":["888cd81"]}

kind clusters still present: 0
./run.sh: line 125: syntax error near unexpected token `created'
./run.sh: line 125: `.apps/passguard (created|successfully)|passguard-[a-z0-9]+-[a-z0-9]+ +1/1|"commit"|"label"|GET / ->|violates PodSecurity|Deleting cluster' "$LOGS/$1.log" \'

==============================================================
CLEANUP
==============================================================
s17-registry
act containers left: 0
kind clusters: devops-hw 
```
