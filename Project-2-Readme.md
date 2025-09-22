## Project 2: Containerize a Flask App with Docker on AWS EC2 and deploy using Terraform ##

### Steps I used ###
1. Create python flask App
2. Write a Dockerfile to package the app into a container. Set the working directory, copy the files from location to the working directory, install dependencies, expose port and run app. 
3. Create a terraform file written in _hcl_ to:
    - Create an EC2 instance, Specify provider and AMI for _EC2_ instance and choose Key pair for SSH access
    - Configure the security group to allow HTTP and SSH traffic from any ip address (ssh authenticated by key) and allow all outbound traffic.
    - A script that runs when the instance is launched to: 
        - update the system and install docker and git, 
        - start and enable docker, 
        - clone a GitHub repository to a directory, 
        - navigate to the directory, 
        - build a docker image using the files in the directory and 
        - run a container from the image built.
    - Output the public IP of the EC2 instance 
4. Stage and push app files, dockerfile and terraform file to github
5. Deploy the docker container on EC2 using Terraform.  Validate with `terraform validate`, deploy with `terraform apply --auto-approve`.


__NOTES__

- Created an IAM user having programmatic CLI access, set up Multifactor Authentication for the user and created a group having least privilege for the job added the user to it.
- Learned to troubleshoot problems building the docker images
- Learned to troubleshoot problems working with Terraform files and deploying EC2 instances
- Learned to update parts of the app by rebuilding the image locally, uploading it to a registry and configuring the user data to pull image from the registry, stop and delete the running containers and run a new container from the image pulled in a CI/CD way from an updated terraform file and deploying that.
- Learned to update parts of the app by updating it locally, logging in remotely, stopping the container, rebuilding the image and redeploying a container.

### Example ###

- There was a bug noticed in the flask app after deploying, so I worked on the app locally to resolve the problem.

- I reinitialized git with `git init`, staged the file with `git add`, committed the change with `git commit` and pushed the commit with `git push -u origin master` 

- I logged in to the EC2 instance remotely via SSH using Putty and my private key

- I tried listing the images with: `docker images` But I got the error 


```
permission denied while trying to connect to the Docker daemon socket at 
unix:///var/run/docker.sock: Head "http://%2Fvar%2Frun%2Fdocker.sock/_ping": 
dial unix /var/run/docker.sock: connect: permission denied 
```

- I used  `sudo usermod -aG docker ubuntu` To append the user ubuntu  to the docker group 

- I had to restart the session
`exit`

- Now listing the images worked
docker images

- But first I wanted to stop the containers:<br>
`docker ps` <br>
`docker stop "containerid"`

- I had to remove the containers because I was getting the error that the image was still being used by a stopped container when I tried removing the image. So I ran   
`docker rm "containerid"`

- To remove the docker image I wanted the image id, so I ran
`docker images`

- To remove the image, I ran
`docker rmi "imageid"`


- Changed directory to the app directory `cd/app`

- I used git pull to update the directory
`Git pull .` 

- But I got the error :
```
fatal: detected dubious ownership in repository at '/app'
To add an exception for this directory, call:
        git config --global --add safe.directory /app
```

- So, I ran:
`git config --global --add safe.directory /app`

- Still an error
```
error: cannot open '.git/FETCH_HEAD': Permission denied
```

- I had to change ownership of all files and subdirectories of the app directory to user and group ubuntu<br>
`sudo chown -R ubuntu:ubuntu .`

- Then I could update the app directory without problem to update the changes to the _app.py_ file from github<br>
`Git pull`

- Then I rebuilt the docker image remotely
`docker build -t flask-app .`

- And then I ran the container again without having to stop the EC2 instance. <br>
`docker run -d -p 80:5000 flask-app`