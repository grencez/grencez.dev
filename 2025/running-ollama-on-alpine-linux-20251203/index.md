---
layout: default
title: Running Ollama on Alpine Linux
date: 2025-12-03
last_modified_at: 2025-12-03
canonical_url: /2025/running-ollama-on-alpine-linux-20251203/
description: A guide to setting up Ollama on Alpine Linux using Ansible, running as a delegated user with OpenRC.
---

Running large language models locally is becoming increasingly accessible, and Ollama is a fantastic tool for managing and running these models.
While Ollama is often easy to set up on mainstream Linux distributions, setting it up on Alpine Linux requires a bit more configuration, especially if you want to run it as a dedicated non-root user service via OpenRC.

This article walks through an Ansible playbook snippet that automates the deployment of Ollama on Alpine Linux.
The configuration emphasizes security by running the service as a specific user (`ollama-delegate`) and flexibility by customizing the OpenRC service definition.

### The Ansible Playbook

Below is the relevant part of the Ansible playbook in [SxPB](../../2025/sxpb-anonymous-discriminated-string-20251201/index.md) format.
It handles user creation, package installation, service configuration, and model retrieval.

```sxpb
(())
(()
 (name "Setup Ollama on Alpine Linux")
 (hosts all)

 (tasks (())
  (()
   (ansible.builtin.user
    (name ollama-delegate)
    (group users)
  ))

  (()
   (name "1.1 Install Ollama package")
   (ansible.builtin.apk
    (name ollama)
    (state present)
   )
  )

  (()
   (name "1.2 Create OpenRC conf for delegated-ollama")
   (ansible.builtin.copy
    (dest /etc/conf.d/delegated-ollama)
    (owner root) (group root) (mode a=r,u+w)
    (content """\
export OLLAMA_DEBUG=1
export OLLAMA_CONTEXT_LENGTH=32768
export OLLAMA_MODELS="/mnt/fastdata/aimodel/ollama"

export OLLAMA_NUM_PARALLEL=1
export OLLAMA_KEEP_ALIVE=20m
""")))

  (()
   (name "1.2 Create OpenRC init script for delegated-ollama")
   (ansible.builtin.copy
    (dest /etc/init.d/delegated-ollama)
    (owner root) (group root) (mode a=rx,u+w)
    (content """\
#!/sbin/openrc-run

name="delegated-ollama"
description="Ollama server run by ollama-delegate user"
command="/usr/bin/ollama"
command_args="serve"
command_user="ollama-delegate"
pid_filepath="/run/${name}.pid"
log_filepath="/var/log/${name}.log"

depend() {
  start net
}

start_pre() {
  touch "${log_filepath}" || return 1
  chown "${command_user}:root" "${log_filepath}" || return 1
  chmod a=,g+r,u+wr "${log_filepath}" || return 1
}

start_stop_daemon_args="\
--background \
--make-pidfile --pidfile ${pid_filepath} \
--stdout ${log_filepath} \
--stderr ${log_filepath} \
"
""")))

  (()
   (name "1.3 Ensure delegated-ollama service is running and enabled")
   (ansible.builtin.service
    (name delegated-ollama)
    (state started)
    (enabled +true)
   )
  )

  (()
   (ansible.builtin.wait_for
    (port 11434)
    (timeout 60)
    (delay 5)
  ))

  (()
   (name "1.4 Pull the gpt-oss:20b model")
   (become +true)
   (become_user ollama-delegate)
   (become_method doas)
   (ansible.builtin.command
    (cmd ollama pull gpt-oss:20b)
  ))
))
```

### Breakdown of the Configuration

#### 1. Dedicated User
The playbook starts by ensuring a `ollama-delegate` user exists.
Running network services as a dedicated user is a security best practice, limiting the potential blast radius if the service is compromised.

#### 2. OpenRC Configuration
Alpine Linux uses OpenRC as its init system.
The default Ollama package might not provide a service script tailored for running as a specific user with custom environment variables easily.
We create a custom service named `delegated-ollama`.

*   **`/etc/conf.d/delegated-ollama`**: This file sets environment variables for the service.
    *   `OLLAMA_MODELS`: redirects where models are stored. Here it points to a mount point `/mnt/fastdata`, likely an SSD or fast storage for better performance.
    *   `OLLAMA_CONTEXT_LENGTH`: Increases the context window.
    *   `OLLAMA_KEEP_ALIVE`: Keeps the model loaded in memory for 20 minutes, reducing latency for subsequent requests.

*   **`/etc/init.d/delegated-ollama`**: This is the actual init script.
    *   `command_user`: Instructions OpenRC to run the process as `ollama-delegate`.
    *   `start_stop_daemon_args`: Configures background execution, PID file management, and logging to `/var/log/delegated-ollama.log`.
    *   `start_pre()`: Ensures the log file exists and has the correct permissions before the service starts.

#### 3. Service Management
The playbook ensures the `delegated-ollama` service is started and enabled to launch on boot.
It then waits for port 11434 to become available, confirming the server is up and listening.

#### 4. Model Management
Finally, the playbook pulls a specific model (`gpt-oss:20b` in this example).
Crucially, it uses `become_user: ollama-delegate`, ensuring the model files are owned by the correct user and stored in the custom directory defined in the environment variables.
