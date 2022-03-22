About
=====

Sidecar container providing a PKCS#11 RPC for [Securosys Primus hardware security modules](https://www.securosys.com/en/products/primus-hardware-security-modules-hsm).

Compatible with the EJBCA Enterprise container from PrimeKey. See [Keyfactor/ejbca-containers](https://github.com/Keyfactor/ejbca-containers) for more information.

Preparation
===========

Configure the HSM according to the *PKCS#11 Provider User Guide For Primus HSM or Clouds HSM* provided by Securosys.

Obtain a copy of the file ``PrimusAPI_PKCS11-X-1.7.36-rhel8-x86_64.tar.gz`` from Securosys. This file is needed when building the container.

You also need access to PrimeKey's registry to pull the proprietary EJBCA Enterprise container as well as the PKCS#11 proxy base layer for the sidecar. [Contact PrimeKey Sales](https://www.primekey.com/products/ejbca-enterprise/#Contact) for access.

Build
=====

1. Put the file ``PrimusAPI_PKCS11-X-1.7.36-rhel8-x86_64.tar.gz`` in the same folder as the Dockerfile.

2. Run the following command to build the container:
```
docker build -t realiserad/primus-pkcs11-sidecar .
```

Run
===

When the container starts it will read the file ``configuration.json`` stored in the folder called ``configuration``. 

The ``configuration`` folder should be made available to the container using a volume mount. The volume is also used to store the PKCS#11 configuration file (``primus.cfg``) and the permanent PIN (``.secrets.cfg``) created when the container starts.

1. Edit the configuration file ``configuration/configuration.json`` and specify the partition and HSMs to use.

2. Edit ``docker-compose.yml`` and type in the credentials you received from Securosys. For example:
```
hsm-driver:
    environment:
        - SETUP_PASSWORD=XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
        - HSM_USER=PRIMUS123
        - PKCS11_PASSWORD=PRIMUS
```

3. Run the container with EJBCA Enterprise using Docker Compose:
```
docker-compose up
```

Test
====

Run the following command inside the EJBCA container::
```
/opt/primekey/bin/p11ng-cli.sh showinfo --lib-file /opt/primekey/p11proxy-client/p11proxy-client.so
```

Limitations
===========

The container can only connect to a single partition at a time and it assumes that the partition is available on all HSMs specified in the configuration file.

Start multiple containers to connect to more than one partition at the same time.

Integration with HashiCorp Vault
================================

The container can read secrets (PKCS#11 password and HSM setup password) from HashiCorp Vault using [Vault Agent Sidecar Injector](https://github.com/hashicorp/vault-k8s).

This is achieved by sourcing the environment variables ``PKCS11_PASSWORD`` and ``SETUP_PASSWORD`` from ``/vault/secrets`` at container boot.

Here is a sample configuration:
```
spec:
    template:
        metadata:
            annotations:
                vault.hashicorp.com/agent-inject: "true"
                vault.hashicorp.com/agent-init-first: "true"
                vault.hashicorp.com/role: "hsm"
                vault.hashicorp.com/agent-inject-secret-pkcs11-password: "hsm/data/pkcs11-password"
                vault.hashicorp.com/agent-inject-template-pkcs11-password: |
                    {{- with secret "hsm/data/pkcs11-password" -}}
                    export PKCS11_PASSWORD="{{ .Data.data.pkcs11_password }}"
                    {{- end }}
                vault.hashicorp.com/agent-inject-secret-setup-password: "hsm/data/setup-password"
                vault.hashicorp.com/agent-inject-template-setup-password: |
                    {{- with secret "hsm/data/setup-password" -}}
                    export SETUP_PASSWORD="{{ .Data.data.setup-password }}"
                    {{- end }}
```
