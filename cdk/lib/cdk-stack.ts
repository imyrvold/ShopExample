import * as cdk from '@aws-cdk/core';
import * as ec2 from '@aws-cdk/aws-ec2';
import * as ecs from '@aws-cdk/aws-ecs';
import * as ecs_patterns from '@aws-cdk/aws-ecs-patterns';
import * as ecr from '@aws-cdk/aws-ecr';

export class CdkStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const vpc = new ec2.Vpc(this, 'DuneVpc', {
      maxAzs: 3
    });
    
    const cluster = new ecs.Cluster(this, 'DuneCluster', {
      vpc: vpc
    });
    
    const repository = new ecr.Repository(this, 'dune-repository', {
      repositoryName: 'cdk-cicd/app'
    });
    
    const taskDefinition = new ecs.FargateTaskDefinition(this, 'DuneTaskDefinition', {
      cpu: 1024,
      memoryLimitMiB: 2048
    });
    
    const vaporApp = taskDefinition.addContainer('VaporApp', {
      image: ecs.ContainerImage.fromEcrRepository(repository),
      logging: ecs.LogDriver.awsLogs({streamPrefix: 'dune'}),
      memoryReservationMiB: 1024
    });
    
    vaporApp.addPortMappings({containerPort: 8080, hostPort: 8080});
    
    const mongo = taskDefinition.addContainer('MongoDB', {
      image: ecs.ContainerImage.fromRegistry('mongo:latest'),
      memoryReservationMiB: 1024
    });
    
    mongo.addPortMappings({containerPort: 27017, hostPort: 27017});
    
    new ecs_patterns.ApplicationLoadBalancedFargateService(this, 'DuneFargateService', {
      serviceName: 'DuneService',
      cluster: cluster,
      cpu: 512,
      desiredCount: 1,
      taskDefinition: taskDefinition,
      publicLoadBalancer: true
    });
    
  }
}
