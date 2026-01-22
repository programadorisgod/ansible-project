#  **DevOps Infrastructure Automation Platform**
## *End-to-End Kubernetes Deployment with Ansible, MicroK8s & GitOps*


### Playbook and Role Execution Order
This project uses Ansible to automate the construction of a complete infrastructure, from creating a custom ISO to deploying services in Kubernetes.
The following details the recommended execution order of playbooks and roles, following numbering to facilitate the flow and understanding of the process.

---

## 00. Installation of common dependencies on local host
- **Playbook:** `00_setup_common_host_dependencies.yml`
- **Roles:**
  1. `common_host`

## 01. Custom Debian ISO construction
- **Playbook:** `01_build_custom_debian_iso.yml`
- **Roles:**
  1. `iso/prepare_debian_iso_environment`
  2. `iso/customize_debian_iso`
  3. `iso/build_debian_iso`

## 02. Virtual machine creation
- **Playbook:** `02_create_virtual_machines_from_iso.yml`
- **Roles:**
  1. `common_host`
  2. `vm_box/prepare_vm_environment`
  3. `vm_box/build_virtual_machines`
  4. `vm_box/initialize_vm_networking`

## 03. VM configuration (hostname, timezone, services)
- **Playbook:** `03_configure_vm_hostname_timezone_and_services.yml`
- **Roles:**
  1. `configure_vm_hostname_and_timezone`

## 06. Docker and Azure DevOps agent installation
- **Playbook:** `06_setup_docker_and_azure_agent.yml`
- **Roles:**
  1. `install_and_configure_docker`
  2. `azure_devops/login_docker_hub`
  3. `azure_devops/build_image`
  4. `azure_devops/push_image`
  5. `azure_devops/run_agent`

## 07. MicroK8s installation
- **Playbook:** `07_install_microk8s_cluster.yml`
- **Roles:**
  1. `mikr8s`



## 08. MicroK8s cluster configuration
- **Playbook:** `10_configure_microk8s_cluster.yml`
- **Roles:**
  1. `microk8s-config/master`
  2. `microk8s-config/worker`

## 09. ArgoCD installation and configuration
- **Playbook:** `11_install_and_configure_argocd.yml`
- **Roles:**
  1. `argocd/install`
  2. `argocd/configure`

---

## Roles

| Name                               | Brief Description                                    |
| ---------------------------------- | ---------------------------------------------------- |
| iso/prepare_debian_iso_environment | Prepares environment and dependencies to build the ISO |
| iso/customize_debian_iso           | Customizes files and ISO configurations             |
| iso/build_debian_iso               | Generates the custom ISO                             |
| vm_box/prepare_vm_environment      | Prepares environment for VM creation                |
| vm_box/build_virtual_machines      | Creates the virtual machines                         |
| vm_box/initialize_vm_networking    | Initializes network/DHCP on VMs                     |
| common_host                        | Installs common packages on the host                |
| configure_vm_hostname_and_timezone | Configures hostname and timezone on VMs             |
| install_and_configure_docker       | Installs and configures Docker                      |
| mikr8s                             | Installs MicroK8s                                   |
| microk8s-config/master             | Configures the MicroK8s master node                 |
| microk8s-config/worker             | Adds and connects worker nodes to the MicroK8s cluster |
| argocd/install                     | Installs ArgoCD on MicroK8s                         |
| argocd/configure                   | Configures Ingress and ArgoCD parameters            |
| azure_devops/login_docker_hub      | Docker Hub login for Azure DevOps                   |
| azure_devops/build_agent_image     | Builds Azure DevOps agent image                     |
| azure_devops/push_agent_image      | Publishes the agent image to Docker Hub             |
| azure_devops/run_agent_container   | Runs the Azure DevOps agent container               |

> **Note:**
> The names of roles and playbooks have been chosen to be as descriptive as possible, and the numbering helps maintain the logical execution order.
> If you add new roles or playbooks, follow this scheme to maintain the clarity and maintainability of the project.

## Execution
1.
```bash
ansible-playbook playbooks/00_setup_common_host_dependencies.yml
```
> Note: We must be in the directory and execute the command, we don't specify the -i or anything else,
since we are using ansible.cfg which contains everything necessary for ansible to have a clear context of the .hosts file, the roles path and the file that contains the password for our Ansible vault.
2. If we have already executed the playbook and something failed, but we don't want to recreate the virtual machines, we can pass a variable that indicates we want to skip the playbook responsible for virtual machine management
```bash
ansible-playbook playbooks/00_setup_common_host_dependencies.yml --extra-vars "skip_build_vm=true"
```
or recommended
```bash 
ansible-playbook playbooks/00_setup_common_host_dependencies.yml \
  --extra-vars '{"skip_process_image": true, "skip_build_vm": true}'
```


## Variables
In ansible we can use vars, which are known as magic variables, these are useful to make our script very versatile and adaptable, there are hierarchy levels in which we can store these variables
- group_vars/  --> Group vars allows us to store variables by machine groups, to identify them each folder must have the name that identifies them in the .host which is found in [ ].
- host_vars/ --> Allows us to store variables at the host level, to be able to identify it, the file must have the name used in the Playbook or failing that the one from the .host file since if in the .hosts we have something like:
> [local]
> localhost ....
 ansible will look for the file named localhost.yml or .yaml

- vars/ --> It is very ambiguous and not scalable since we would have everything loose without knowing who it belongs to in the future.
- roles/rol/vars/  --> Strong role defaults, that is, it is more specific.
- roles/rol/defaults/ Weak role defaults, can be overwritten by the previous one, host_vars or group_vars


## Necessary configurations
1. Ansible vault.
We have variables that we don't want to be exposed and in case our repository is leaked we remain so exposed, therefore we will use ansible-vault which allows us to store variables in an encrypted manner. All data in this repository is for example purposes for educational purposes.
### Create encrypted variables

```bash
ansible-vault create /home/user/folder/ansible-project/group_vars/group/your_file.yml
```
if within your ansible.cfg you add the vault_password_file instruction it will simply open vi or vim, so you can enter your variables and it will automatically encrypt with the established password, otherwise, it will ask what password you will use.

### View variables in plain text (if we have the ansible password file)
```bash
ansible-vault view /home/user/folder/ansible-project/group_vars/group/your_file.yml
```
otherwise

```bash
ansible-playbook path-to-file --ask-vault-pass
```

### edit variables
```bash
ansible-vault edit /home/user/folder/ansible-project/group_vars/group/your_file.yml
```

### Example ansible.cfg
[defaults]
roles_path = ./roles
inventory   = ./.hosts
host_key_checking = False
vault_password_file = ~/.vault_pass
