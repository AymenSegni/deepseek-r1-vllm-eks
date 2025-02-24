# deepseek-r1-vllm-eks
Deploy and test DeepSeek R1 to Kubernetes using Amazon EKS, vLLM, Terraform, and Helm 

## Introduction

This project provides a comprehensive guide to deploying the DeepSeek R1 large language model (LLM) on Amazon Elastic Kubernetes Service (EKS). By leveraging vLLM for efficient model serving, Terraform for infrastructure as code, and Helm for Kubernetes resource management, this repository offers a scalable and reproducible approach to hosting LLMs in a cloud environment.

## Assumptions and Prerequisites

Before proceeding, ensure you have the following:

- **AWS Account**: Active account with necessary permissions.
- **AWS CLI**: Installed and configured with appropriate credentials.
- **Terraform**: Installed on your local machine.
- **Kubectl**: Installed for Kubernetes cluster management.
- **Helm**: Installed for managing Kubernetes packages.
- **Karpenter**: Deployed in your EKS cluster for dynamic provisioning.
- **Sufficient AWS Service Quotas**: Ensure your account has the necessary quotas, especially for GPU instances. Refer to the [AWS EC2 Service Quotas](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-resource-limits.html) for more details.


## DeepSeek R1 Deployment on EKS: The Recipe


1. **Model**: DeepSeek-R1-Distill-Queen-7B, open-source model under the MIT license

2. **Compute**: AWS ~g6.xlarge instance on a spot basis, typically costing less than 25 cents per hour

3. **GPU**:  Nvidia L4 GPU with 24 GB of VRAM, can safely handle our model requirements 

4. **Network**: AWS VPC Networking

5. **Kubernetes**: EKS cluster with Karpenter on Fargate

6. **Scaling**: x2 Karpenter providers, one for GPUs and one for standard node

7. **Integrations**: Nvidia Driver Plugin to ensure GPUs are available for Kubernetes and Prometheus and Grafana for monitoring. 

8. **Automation**: All automated with Infra as Code: Terraform.

9. **Costs**: ~ 34–50 cents per hour: charges for the NAT gateway, EKS, EC2, and GPU-equipped nodes.


> If you’re using this demo, please ★ Star this repository to show your interest!


## Project Structure

The repository is organized as follows:
```bash
.
├── LICENSE
├── README.md
...
├── deepseek-vllm
│   ├── deploy # deepseek deployment with vLLM
│   │   ├── config_deepseek-r1.yaml
│   │   ├── deepseek-vllm.json
│   │   ├── main.tf
│   │   ├── terraform.tfstate
│   │   └── terraform.tfstate.backup
│   └── modules # Helm chart Terraform module for DeepSeeek R1 with vLLM deployment
│       ├── README.md
│       ├── helm
│       │   └── deepseek-r1
│       │       ├── Chart.yaml
│       │       ├── templates
│       │       │   ├── deployment.yaml
│       │       │   └── service.yaml
│       │       └── values.yaml
│       ├── main.tf
│       ├── providers.tf
│       ├── variables.tf
│       └── versions.tf
├── eks
│   ├── deploy # deploy th eks cluster with GPU enabled
│   │   └── clusters
│   │       └── dev
│   │           ├── config.yaml
│   │           ├── main.tf
│   │           ├── output.tf
│   │           ├── terraform.tfstate
│   │           ├── terraform.tfstate.backup
│   │           └── variables.tf
│   └── modules # eks terraform module
│       └── eks
│           ├── README.md
│           ├── addons.tf
│           ├── karpenter
│           │   ├── default-nodeclass.yaml
│           │   ├── default-nodepool.yaml
│           │   ├── gpu-nodeclass.yaml
│           │   └── gpu-nodepool.yaml
│           ├── karpenter.tf
│           ├── main.tf
│           ├── output.tf
│           ├── providers.tf
│           ├── variables.tf
│           └── versions.tf
├── genai-app
│   ├── app.py
│   └── requirements.txt
└── monitoring
    ├── grafana
    │   └── dashboards.json
    └── services
        ├── deepseek-32b.yaml
        └── deepseek-7b.yaml

19 directories, 45 files

```

- **eks/**: Terraform deployment and modules to provision the EKS cluster, VPC networking, Cluster Addons, EKS NodePool with GPU support using Karpenter.
- **deepseek-vllm/**: Terraform Helm deployment and modules for deploying the DeepSeek R1 model with vLLM.
- **genai-app/**: Sample chatbot application to interact with the deployed model.
- **monitoring/**: Configuration files for Prometheus and Grafana to monitor model performance.

## Provisioning AWS EKS Cluster with GPU Support Using Karpenter and Terraform

Navigate to the `eks/deploy/clusters/dev` directory and follow these steps:

1. **Initialize Terraform**:

   ```bash
   terraform init
   ```

2. **Review and Edit Variables**: Update `config.yaml` with your desired configurations, such as region, cluster name, account ID, etc.

3. **Apply Terraform Configuration**:

   ```bash
   terraform plan --out eks-dev.json # optional, you can plan before apply, also you can save your plan output to a json file 
   ```

   ```bash
   terraform apply "eks-dev.json" # apply withusing the saved plan

   This command provisions an EKS cluster with GPU-enabled nodes managed by Karpenter.

4. Example of the expected outputs 

[EKS Plan](./assets/eks-apply.png)

[EKS Cluser On AWS Console](./assets/eks-cluster-deploy.png)


5. Set up Kubectl to interact with your newly created EKS cluster

Set up your local AWS environment, you can use the interactive AWS Configure CLI (doc:
```bash
aws configure # add your AWS Access Key as explained in: https://docs.aws.amazon.com/cli/v1/userguide/cli-authentication-user.html
``` 
Install the `kubectl` local config

```bash
aws eks update-kubeconfig --region <your region> \
    --name <your-cluster-name>
```

6. Check that your nodes, pods and all resources are up and running 

```bash
kubectl get node -o wide
```

```bash
  kubectl get pods --all-namespaces # Make sure that Karpenter and CoreDNS are running
```
[Karpenter and Coredns Checks](./assets/check-karpenter-coredns.png)

7. Karpenter providers check:

```bash
kubectl get ec2nodeclasses.karpenter.k8s.aws
```
[Karpnetr on the EKS Cluster](./assets/cluster-karpenter.png)


## Deploying the DeepSeek R1 Model to EKS Using vLLM, Terraform, and Helm

After provisioning the EKS cluster:

1. **Navigate to the `deepseek-vllm/` Directory**:

   ```bash
   cd ../deepseek-vllm/deploy
   ```

2. **Update Model Config Values**: 

Modify `config_deepseek-r1.yaml` to set parameters like `model_size`, and resource limits based on your requirements.
If necessary, modify the engine arguments to suit your specific requirements better.

>For the 32B version, change the model_size to 32b and update the resources and teh volumes to suit a 32b model. Note that this version runs on a ~g6.12xlarge instance, which costs approximately $1.5 per hour as a spot instance.

3. **Deploy the Helm Chart using Terraform**:

   ```bash
   terraform init
   ```
  
   ```bash
   terraform plan --out deepseek-r1-7b.json # optional, you can plan before apply, also you can save your plan output to a json file 
   ```

   ```bash
   terraform apply "deepseek-r1-7b.json" # apply with the saved json plan
   This command deploys the DeepSeek R1 model using vLLM on your EKS cluster.



> **Note**: If your DeepSeek pod remains in a "pending" state for several minutes:

- **Check Node Provisioning**:

  ```bash
  kubectl get nodepool
  ```

Ensure the `nvidia-gpu` nodepool has active nodes.

- **Verify AWS Service Quotas**: Confirm that your AWS account has sufficient quotas for GPU instances. AWS enforces quotas on vCPU allocations for different instance families. For GPU instances, ensure you have adequate vCPU limits. Refer to the [Amazon EC2 Service Quotas](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-resource-limits.html) for detailed information.

  > **Note**: Quotas are based on vCPUs, not the number of instances. Ensure you request increases accordingly.


4. Explore the Model Deployment 

#### Verify the Deployment**

After deploying DeepSeek with vLLM, it typically takes ~ 5 minutes to download and load the model into the GPU. 
You can check the logs directly to monitor what’s happening during this initialization phase.

```bash
kubectl get po -n deepseek-r1-7b
```
Check the logs with the following:

```bash
kubectl logs po/<grap the pod id from the previous command> -n deepseek-r1-7b
```

When the model is loaded and ready, you should expect to see the following logs:

[DeepSeek R1 Logs](./assets/deepseek-r1-logs.webp)

#### Explore the Model locally with a proxy

Open a new terminal and set up port forwarding to interact with the OpenAI-compatible API endpoint on port 8000:

```bash
kubectl port-forward svc/deepseek-r1-7b 8000:8000
```

Now that everything is up & running, test your R1 Model by sending a query via a standard OpenAI curl command. Here’s an example:
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
-H "Content-Type: application/json" \
-d '{
      "model": "deepseek-ai/DeepSeek-R1-Distill-Qwen-7B",
      "messages": [{"role": "user", "content": "What is Kubernetes?"}]
    }'
```

## Deploying the Testing Chatbot Application

To interact with the deployed model:

1. **Navigate to the `genai-app/` Directory**:

   ```bash
   cd ../genai-app/
   ```
Set up the Python Application

```bash
python3 -m venv .venv
source .venv/bin/activate   # On Linux or MacOS
.venv\Scripts\activate      # On Windows
pip install -r requirements.txt
```
This will isnatll packages includes the OpenAI Python client for API requests and Gradio for web interface creation.

Start the app:

```bash
python chat.py
```
Open a web browser and go to http://localhost:7860/

[ChatBot UI](./assets/chatbot-ui.webp)

## Monitoring Model Performance Using Grafana and Prometheus

### DeepSeek R1 Deployment on EKS:  Monitoring and Key metrics

- **Time for First Token (TFFT)**: 
The time from submitting a request to the model until the first token of the response is generated.
It’s a critical indicator of the initial responsiveness of the model, so important in customer-facing apps as response time impacts user experience.

- **Time for Output Token (TFOT)**: Similar to TFFT,  tracks the time to generate each subsequent token after the first. 
The model’s efficiency is indicated by its ability to process and generate content continuously, providing  insights into its throughput performance.

- **Prompt/Generation Tokens per Second**: Measures the number of tokens the model processes or generates per second. 
Key metric for evaluating the model’s throughput capacity. Higher rates signify a more efficient model that can process more input or generate more content in less time.

 
### Monitor the deployed model:

##### Deploy Prometheus and Grafana**: Apply the provided configuration files to set up monitoring.


   ```bash
   cd ../monitoring/
   kubectl apply -f serviceMonitor-deepseek-7b.yaml
   ```

##### Setting up a Grafana dashboard to monitor LLM metrics

To access the Grafana dashboard through your browser, you first need to port-forward the Grafana pod. From your terminal, enter the following command:

```bash 
kubectl port-forward -n kube-prometheus-stack \
  service/kube-prometheus-stack-grafana 8080:80
```
1. Open a web browser and navigate to http://localhost:8080. The login page should appear. Log in with the username adminand the default password prom-operator

2. Once logged in, Click on the “+” icon on the top right bar and select “Import dashboard.”

3. Upload the JSON file named grafana-dashboard.json from the `monitoring/grafana` folder of the GitHub repository and click “Import.”

4. A dropdown filter at the top left of the dashboard allows you to select the specific model you want to monitor

## Destroy 

Nativigate to the `deepseek-vllm/deploy` then execute:

```bash
terraform destroy
```
Once it's done, repeat the same with the `eks/deploy/clusters/dev`


## Conclusion

By following this guide, you can successfully deploy and manage the DeepSeek R1 LLM on AWS EKS, ensuring efficient performance and scalability. 
With Terraform handling infrastructure provisioning, Helm managing Kubernetes resources, and vLLM optimizing model serving, this deployment strategy provides a robust foundation for hosting large language models in production environments. Future enhancements may include integrating auto-scaling strategies, optimizing GPU utilization, and incorporating additional security best practices to improve the resilience and efficiency of the deployment.
