# Orden de Ejecución de Playbooks y Roles

Este proyecto utiliza Ansible para automatizar la construcción de una infraestructura completa, desde la creación de una ISO personalizada hasta el despliegue de servicios en Kubernetes.
A continuación se detalla el orden recomendado de ejecución de los playbooks y roles, siguiendo la numeración para facilitar el flujo y la comprensión del proceso.

---

## 00. Instalación de dependencias comunes en el host local
- **Playbook:** `00_setup_common_host_dependencies.yml`
- **Roles:**
  1. `common_host`

## 01. Construcción de ISO Debian personalizada
- **Playbook:** `01_build_custom_debian_iso.yml`
- **Roles:**
  1. `iso/prepare_debian_iso_environment`
  2. `iso/customize_debian_iso`
  3. `iso/build_debian_iso`

## 02. Creación de máquinas virtuales
- **Playbook:** `02_create_virtual_machines_from_iso.yml`
- **Roles:**
  1. `common_host`
  2. `vm_box/prepare_vm_environment`
  3. `vm_box/build_virtual_machines`
  4. `vm_box/initialize_vm_networking`

## 03. Configuración de VMs (hostname, timezone, servicios)
- **Playbook:** `03_configure_vm_hostname_timezone_and_services.yml`
- **Roles:**
  1. `configure_vm_hostname_and_timezone`

## 06. Instalación de Docker y agente Azure DevOps
- **Playbook:** `06_setup_docker_and_azure_agent.yml`
- **Roles:**
  1. `install_and_configure_docker`
  2. `azure_devops/login_docker_hub`
  3. `azure_devops/build_image`
  4. `azure_devops/push_image`
  5. `azure_devops/run_agent`

## 07. Instalación de MicroK8s
- **Playbook:** `07_install_microk8s_cluster.yml`
- **Roles:**
  1. `mikr8s`



## 08. Configuración del cluster MicroK8s
- **Playbook:** `10_configure_microk8s_cluster.yml`
- **Roles:**
  1. `microk8s-config/master`
  2. `microk8s-config/worker`

## 09. Instalación y configuración de ArgoCD
- **Playbook:** `11_install_and_configure_argocd.yml`
- **Roles:**
  1. `argocd/install`
  2. `argocd/configure`

---

## Roles

| Nombre                             | Descripción Breve                                    |
| ---------------------------------- | ---------------------------------------------------- |
| iso/prepare_debian_iso_environment | Prepara entorno y dependencias para construir la ISO |
| iso/customize_debian_iso           | Personaliza archivos y configuraciones de la ISO     |
| iso/build_debian_iso               | Genera la ISO personalizada                          |
| vm_box/prepare_vm_environment      | Prepara entorno para creación de VMs                 |
| vm_box/build_virtual_machines      | Crea las máquinas virtuales                          |
| vm_box/initialize_vm_networking    | Inicializa red/DHCP en las VMs                       |
| common_host                        | Instala paquetes comunes en el host                  |
| configure_vm_hostname_and_timezone | Configura hostname y timezone en VMs                 |
| install_and_configure_docker       | Instala y configura Docker                           |
| mikr8s                             | Instala MicroK8s                                     |
| microk8s-config/master             | Configura el nodo master de MicroK8s                 |
| microk8s-config/worker             | Añade y conecta nodos worker al cluster MicroK8s     |
| argocd/install                     | Instala ArgoCD en MicroK8s                           |
| argocd/configure                   | Configura Ingress y parámetros de ArgoCD             |
| azure_devops/login_docker_hub      | Login en Docker Hub para Azure DevOps                |
| azure_devops/build_agent_image     | Construye imagen del agente de Azure DevOps          |
| azure_devops/push_agent_image      | Publica la imagen del agente en Docker Hub           |
| azure_devops/run_agent_container   | Corre el contenedor del agente de Azure DevOps       |

> **Nota:**
> Los nombres de los roles y playbooks han sido elegidos para ser lo más descriptivos posible, y la numeración ayuda a mantener el orden lógico de ejecución.
> Si agregas nuevos roles o playbooks, sigue este esquema para mantener la claridad y la mantenibilidad del proyecto.

## Ejecución
1.
```bash
ansible-playbook playbooks/00_setup_common_host_dependencies.yml
```
> Nota: Debemos estar en el directorio y ejecutamos el comando, no le especificamos el -i ni nada más,
ya que estamos usando ansible.cfg que contiene todo lo necesario para que ansible tenga un contexto claro del archivo .hosts, la ruta de los roles y el archivo que contiene la contraseña de nuestro vault de Ansible.
2. Si ya hemos ejecutado el playbook y algo falló, pero no queremos volver a crear las maquinas virtuales, podemos pasar una variable que indique que queremos saltarno el playbook encargado de la gestión de las maquinas virtual
```bash
ansible-playbook playbooks/00_setup_common_host_dependencies.yml --extra-vars "skip_build_vm=true"
```


## Variables
En ansible podemos usar las vars, que son conocidas como variables magicas, estas son utiles para volver nuestro script muy versatil y adaptable, existen niveles de jerarquía en los cuales nosotros podemos guardar estas variables
- group_vars/  --> Group vars permite que guardemos variables por grupos de maquintas, para identificarlos cada carpeta debe llevar el nombre que los identifica en el .host el cual se encuentra en [ ].
- host_vars/ --> Permite que guardemos variables a nivel de host, para poder identificarlo, el archivo debe llevar el nombre que utiliza en el Playbook o en su defecto el del archivo .host ya que si en el .hots tenemos algo como:
> [local]
> localhost ....
 ansible buscará el archivo llamado localhost.yml o .yaml

- vars/ --> Es muy ambiguo y poco escalable ya que tendriamos todo suelto sin saber de quien a futuro.
- roles/rol/vars/  --> Defaults fuertes del rol, es decir es más especifico.
- roles/rol/defaults/ Defaults debiles del rol, se pueden sobreescribir por el anterior, host_vars o group_vars


## Configuraciones necesarias
1. Ansible vault.
Tenemos varaibles que no queremos que estén expuestas y que en caso tal se filtre nuestro repositorio quedemos tan expuesto, por lo tanto usaremos ansible-vault que nos permite guardar variables de manera cifrada. Todos los datos de este repositorio son de ejemplo para fines educativos.
### Crear las variables cifradas

```bash
ansible-vault create /home/user/folder/ansible-project/group_vars/group/your_file.yml
```
si dentro de tu ansible.cfg añades la instrucción vault_password_file simplemente te abrirá vi o vim, para que ingreses tus variables y automaticamente se cifrará con la contraseña establecida, sino, te preguntará que contraseña usarás.

### Ver variables en texto plano (si tenemos el ansible password file)
```bash
ansible-vault view /home/user/folder/ansible-project/group_vars/group/your_file.yml
```
sino

```bash
ansible-playbook path-to-file --ask-vault-pass
```

### editar variables
```bash
ansible-vault edit /home/user/folder/ansible-project/group_vars/group/your_file.yml
```

### Ejemplo ansible.cfg
[defaults]
roles_path = ./roles
inventory   = ./.hosts
host_key_checking = False
vault_password_file = ~/.vault_pass
