"""
CloudMart architecture diagram generator.

Requires:
    brew install graphviz
    pip install diagrams

Run:
    python architecture.py
Outputs: cloudmart_architecture.png
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.custom import Custom

from diagrams.aws.compute import EKS, Lambda, ECR
from diagrams.aws.network import VPC, PrivateSubnet, ElbApplicationLoadBalancer
from diagrams.aws.devtools import Codepipeline, Codebuild
from diagrams.aws.database import Dynamodb, DynamodbStreams
from diagrams.aws.storage import S3
from diagrams.aws.ml import Bedrock  # needs diagrams >= 0.23; see README notes

from diagrams.k8s.compute import Pod
from diagrams.k8s.network import Service, Ingress

from diagrams.gcp.analytics import BigQuery
from diagrams.azure.ml import CognitiveServices

from diagrams.onprem.vcs import Github
from diagrams.onprem.iac import Terraform

graph_attr = {
    "fontsize": "16",
    "bgcolor": "white",
    "splines": "ortho",
    "pad": "0.5",
    "nodesep": "0.6",
    "ranksep": "0.9",
}

with Diagram(
    "CloudMart Architecture",
    filename="cloudmart_architecture",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
):
    # External services
    github = Github("GitHub")
    terraform = Terraform("Terraform")
    openai = Custom("OpenAI", "openai.png")  # local icon, converted from openai.svg

    with Cluster("AWS Region"):
        with Cluster("Amazon VPC"):
            with Cluster("Private subnet"):
                with Cluster("Amazon EKS Cluster"):
                    with Cluster("cloudmart-cluster"):
                        with Cluster("cloudmart-frontend"):
                            svc_fe = Service("service-frontend")
                            pod_fe = Pod("pods-frontend")
                            svc_fe >> pod_fe
                        with Cluster("cloudmart-backend"):
                            svc_be = Service("service-backend")
                            pod_be = Pod("pods-backend")
                            svc_be >> pod_be

                alb = ElbApplicationLoadBalancer("Application\nLoad Balancer")
                ingress = Ingress("Kubernetes\nIngress")

            # CI/CD pipeline (inside VPC box in the reference image)
            with Cluster("CI/CD"):
                pipeline = Codepipeline("AWS CodePipeline")
                build = Codebuild("AWS CodeBuild")
                ecr = ECR("Amazon ECR")
                pipeline >> build >> ecr

        # Data + event-driven services (AWS Region, outside VPC)
        dynamo = Dynamodb("Amazon DynamoDB")
        stream = DynamodbStreams("Stream")
        s3 = S3("Amazon S3")
        bedrock = Bedrock("Amazon Bedrock")

        with Cluster("Event-driven microservice"):
            lam = Lambda("Amazon Lambda")

    # Third-party analytics / AI
    with Cluster("Google Cloud"):
        bigquery = BigQuery("Real-time Analytics\n(BigQuery)")
    with Cluster("Microsoft Azure"):
        sentiment = CognitiveServices("Sentiment Analysis\n(Azure AI Language)")

    # --- Flows ---
    terraform >> Edge(label="provisions") >> alb
    github >> Edge(label="push") >> pipeline
    ecr >> Edge(label="deploy") >> pod_be

    alb >> ingress
    ingress >> svc_fe
    ingress >> svc_be
    pod_be >> Edge(label="AI calls") >> openai

    dynamo >> stream >> lam
    lam >> bigquery
    lam >> sentiment
