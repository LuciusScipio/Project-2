## Project 2: **Containerized Flask App Deployment on AWS EC2 via Terraform (Infrastructure as Code)**

This project establishes a fully automated, scalable workflow to deploy a containerized Python Flask application onto an AWS EC2 instance using **Terraform** as the Infrastructure as Code (IaC) tool. The deployment is orchestrated entirely via a **`user_data`** bootstrapping script, ensuring a repeatable and immutable infrastructure setup.

-----

## 💡 The Problem & Solution

### **The Problem**

Th need for a simple, reliable, and quickly deployable web application (a note-taking app, based on `app.py`) that could be easily managed and updated without manual server configuration. Traditional VM-based deployments were slow, prone to configuration drift, and difficult to scale.

### **The Solution: Immutable Infrastructure & Containerization**

The solution leverages **Docker** to package the application and all its dependencies into an isolated container, guaranteeing consistency across all environments. **Terraform** is then used to automate the provisioning of the required AWS infrastructure (EC2, Security Groups) and a **`user_data`** script is used to on the EC2 instance automatically install the Docker engine, pull the application code from GitHub, build a Docker image with the app and its dependencies and run a Docker container, creating an **immutable deployment pipeline**.

-----

## 🏗️ Architecture Design

The architecture is designed for simplicity, rapid deployment, and public accessibility.


The core components are:

  * **AWS VPC:** Provides an isolated network for the infrastructure.
  * **EC2 Instance (t2.micro):** The virtual machine host for the application.
  * **Security Group (`web_sg`):** Acts as a virtual firewall, explicitly allowing inbound **HTTP (Port 80)** traffic for the web app and **SSH (Port 22)** for administrative access.
  * **Docker Container:** Runs the Flask app on internal port **5000**, which is mapped to the EC2 host's port **80**.

-----

## 🛠️ Tools & Services Used

| Category | Tool/Service | Purpose in Project |
| :--- | :--- | :--- |
| **Cloud Infrastructure** | **AWS EC2** | Hosting the container runtime (Docker Engine).
| | **AWS Security Group** | Network access control, allowing web (80) and SSH (22) traffic. |
| **Infrastructure as Code** | **Terraform (HCL)** | Programmatically provisioning all AWS resources. |
| **Containerization** | **Docker** | Packaging the Python Flask application for portability. |
| **Application** | **Python (Flask)** | The web framework used for the simple note-taking application. |
| **Automation/Deployment** | **Bash (`user_data`)** | EC2 bootstrapping script to install dependencies, clone the repo, and deploy the container. |
| **Version Control** | **Git/GitHub** | Source code management for the application and the deployment script. |

-----

## 📈 Value & Metrics

| Metric | Detail | Impact |
| :--- | :--- | :--- |
| **Deployment Time** | Reduced initial provisioning and deployment time to **\< 5 minutes**. | Enables **rapid iteration** and immediate recovery from failure (Disaster Recovery). |
| **Configuration Drift** | Eliminated by using a **GitHub-based `user_data` script** to build the image on boot. | Guarantees **immutable infrastructure**; every instance is configured identically from a single source. |
| **Cost Efficiency** | Utilized **`t2.micro`** (Free Tier eligible) and **public GitHub cloning** (zero registry cost). | Designed the solution to be **highly cost-effective** compared to using a dedicated Container Registry (ECR) for simple projects. |

-----

## 🚧 Challenges Overcome & Advanced Troubleshooting

The project required advanced shell and Docker troubleshooting upon remote login to perform an application update, demonstrating my ability to debug runtime environments.

### **1. Permission Denied for Docker Daemon**

  * **The Problem:** Upon SSHing into the running EC2 instance to manually update the application, I as the `ubuntu` user received a `permission denied` error when trying to run `docker images` & `docker ps` to enable me to get get the container and image id and remove them and could rebuild the image and run a new container after making changes to the app and deploying to Github.
  * **The Solution:** The `ubuntu` user was not part of the `docker` group, preventing it from interacting with the Docker daemon socket (`/var/run/docker.sock`). I used the command `sudo usermod -aG docker ubuntu` to add the user to the correct group, followed by restarting the session (`exit` and re-SSH) to apply the new group membership.

### **2. Git Dubious Ownership Error**

  * **The Problem:** After resolving the Docker permissions, attempting to run `git pull` in the `/app` directory resulted in a `fatal: detected dubious ownership in repository at '/app'` error. This is a recent Git security feature.
  * **The Solution:** The application files were initially cloned by the root user during the `user_data` script execution, leading to an ownership conflict with the logged-in `ubuntu` user.
    1.  I resolved the ownership using: `sudo chown -R ubuntu:ubuntu .`
    2.  I then performed the application update by executing a full lifecycle: `git pull`, `docker build -t flask-app .`, and finally `docker run -d -p 80:5000 flask-app` to deploy the new version without stopping the EC2 instance.

-----

## ⚙️ Deployment Instructions

These steps demonstrate how to provision the entire infrastructure stack.

### 1\. Prerequisites

1.  **Terraform:** Install and configure the Terraform CLI locally.
2.  **AWS CLI:** Configure the AWS CLI with credentials for the region specified in `main.tf` (`us-east-1`).
3. **SSH Key Pair**: A key pair named my-ec2-key (referenced in `main.tf`, correct as needed) must be created in the AWS Management Console for the us-east-1 region.

### 2\. Infrastructure Provisioning

1.  **Initialize:** Open your terminal in the project directory and run: `terraform init`

2.  **Review Plan:** Review the resources that Terraform plans to create: `terraform plan`. Generates an execution plan, showing exactly what resources will be created/modified in AWS

3.  **Apply:** Deploy the infrastructure (EC2 Instance & Security Group): `terraform apply --auto-approve`

4.  **Retrieve Endpoint:** After the stack is complete, retrieve the Public IP of the deployed application:

    ```bash
    terraform output public_ip
    ```

5.  **Test:** Wait 1-2 minutes for the `user_data` script to complete, then navigate to `http://<public_ip>` in your browser.

### 3\. Application Update (Simulated CI/CD)

To simulate an application update after the initial deployment:

1.  **Update Code:** Make a local change to `app.py`.

2.  **Commit Change:** Push the updated code to the GitHub repository used for cloning.

3.  **Remote Update:** SSH into the EC2 instance using your private key and the outputted Public IP.

4.  **Execute Update Lifecycle (using the permissions fixed in the Challenges section):**

    ```bash
    cd /app
    git pull                      # Pull the latest app.py changes
    docker build -t flask-app .   # Rebuild the Docker image with the new code
    docker stop $(docker ps -q)   # Stop the running container
    docker rm $(docker ps -a -q)  # Remove the stopped container
    docker run -d -p 80:5000 flask-app # Run the new container
    ```

5.  **Cleanup:** Once finished, if needed,  destroy the entire infrastructure to avoid charges: `terraform destroy --auto-approve`
