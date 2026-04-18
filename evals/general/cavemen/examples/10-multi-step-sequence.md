Full ECS Fargate deploy w/ ALB. Steps in clear English — sequence order matters here.

**Prerequisites:** AWS CLI configured, Docker installed, app has `Dockerfile`.

**Steps:**

1. Create an ECR repository to store your Docker images:
   ```bash
   aws ecr create-repository --repository-name my-app --region us-east-1
   ```

2. Authenticate Docker with ECR, then build and push your image:
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
   docker build -t my-app .
   docker tag my-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
   docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
   ```

3. Create an ECS cluster to group your services:
   ```bash
   aws ecs create-cluster --cluster-name my-app-cluster
   ```

4. Create an IAM execution role (`ecsTaskExecutionRole`) that grants ECS permission to pull images from ECR and write logs to CloudWatch. Attach the `AmazonECSTaskExecutionRolePolicy` managed policy to it.

5. Register a task definition that describes your container. Create `task-def.json`:
   ```json
   {
     "family": "my-app",
     "networkMode": "awsvpc",
     "requiresCompatibilities": ["FARGATE"],
     "cpu": "256",
     "memory": "512",
     "executionRoleArn": "arn:aws:iam::<account-id>:role/ecsTaskExecutionRole",
     "containerDefinitions": [
       {
         "name": "my-app",
         "image": "<account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest",
         "portMappings": [{ "containerPort": 3000, "protocol": "tcp" }],
         "logConfiguration": {
           "logDriver": "awslogs",
           "options": {
             "awslogs-group": "/ecs/my-app",
             "awslogs-region": "us-east-1",
             "awslogs-stream-prefix": "ecs"
           }
         }
       }
     ]
   }
   ```
   Then register it:
   ```bash
   aws ecs register-task-definition --cli-input-json file://task-def.json
   ```

6. Create an Application Load Balancer with a target group. The target group type must be `ip` (not `instance`) because Fargate uses awsvpc networking:
   ```bash
   aws elbv2 create-load-balancer --name my-app-alb --subnets subnet-aaa subnet-bbb --security-groups sg-xxx
   aws elbv2 create-target-group --name my-app-tg --protocol HTTP --port 3000 --vpc-id vpc-xxx --target-type ip --health-check-path /health
   aws elbv2 create-listener --load-balancer-arn <alb-arn> --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=<tg-arn>
   ```

7. Create the ECS service, linking it to the load balancer's target group. Assign public subnets and a security group that allows inbound traffic on port 3000:
   ```bash
   aws ecs create-service \
     --cluster my-app-cluster \
     --service-name my-app-service \
     --task-definition my-app \
     --desired-count 2 \
     --launch-type FARGATE \
     --network-configuration "awsvpcConfiguration={subnets=[subnet-aaa,subnet-bbb],securityGroups=[sg-yyy],assignPublicIp=ENABLED}" \
     --load-balancers "targetGroupArn=<tg-arn>,containerName=my-app,containerPort=3000"
   ```

8. Verify the service is running and tasks are healthy:
   ```bash
   aws ecs describe-services --cluster my-app-cluster --services my-app-service
   ```
   Check the ALB DNS name in your browser to confirm the app responds.

**Common gotchas:**

- Security group on ALB must allow inbound 80/443. Security group on tasks must allow inbound 3000 from ALB security group
- Forgot CloudWatch log group → tasks fail silently. Create `/ecs/my-app` log group before first deploy
- `assignPublicIp=ENABLED` needed if subnets lack NAT gateway — otherwise ECR pull fails
- Task memory/CPU values must match valid Fargate combos (256/.25vCPU, 512/.25vCPU, etc.)

For prod: add HTTPS listener w/ ACM cert, use private subnets + NAT gateway, set up auto-scaling on service, use Terraform or CDK instead of raw CLI.
