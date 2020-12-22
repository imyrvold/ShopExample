import * as cdk from '@aws-cdk/core';
import * as ecs from '@aws-cdk/aws-ecs';
import * as ecs_patterns from '@aws-cdk/aws-ecs-patterns';
import * as ecr from '@aws-cdk/aws-ecr';
import * as iam from '@aws-cdk/aws-iam';
import * as secretsManager from '@aws-cdk/aws-secretsmanager';
import { ShopStackProps } from './infra-cdk-stack';

export class UserServiceStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props: ShopStackProps) {
    super(scope, id, props);

    const secretMongoDB = secretsManager.Secret.fromSecretArn(this, 'prod/service/db/mongodb', 'arn:aws:secretsmanager:eu-west-1:515051544254:secret:prod/service/db/mongodb-B76py8');
    const secretSendgrid = secretsManager.Secret.fromSecretArn(this, 'prod/service/sendgrid', 'arn:aws:secretsmanager:eu-west-1:515051544254:secret:prod/service/sendgrid-oUZMO1');
    const secretJwksKeypair = secretsManager.Secret.fromSecretArn(this, 'prod/service/jwt/jwkskeypair', 'arn:aws:secretsmanager:eu-west-1:515051544254:secret:prod/service/jwt/jwkskeypair-567S6x');
    
    const taskRole = new iam.Role(this, 'BackendTaskRole', {
        roleName: 'BackendECSTaskRole',
        assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
        managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AmazonECSTaskExecutionRolePolicy')
        ]
    });
    secretMongoDB.grantRead(taskRole);
    secretSendgrid.grantRead(taskRole);
    secretJwksKeypair.grantRead(taskRole);

    
    const repository = ecr.Repository.fromRepositoryName(this, 'Repository', 'cdk-cicd/user-manager');
    const imageTag = process.env.CODEBUILD_RESOLVED_SOURCE_VERSION || 'local';

    const taskDefinition = new ecs.FargateTaskDefinition(this, 'DuneTaskDefinition', {
      cpu: 1024,
      memoryLimitMiB: 2048
    });
    
    const vaporApp = taskDefinition.addContainer('VaporApp', {
      image: ecs.ContainerImage.fromEcrRepository(repository, imageTag),
      logging: ecs.LogDriver.awsLogs({streamPrefix: 'user'}),
      memoryReservationMiB: 1024,
      secrets: {
        JWKS_KEYPAIR: ecs.Secret.fromSecretsManager(secretJwksKeypair),
        MONGODB: ecs.Secret.fromSecretsManager(secretMongoDB),
        SENDGRID_API_KEY: ecs.Secret.fromSecretsManager(secretSendgrid)
      }
    });
    
    vaporApp.addPortMappings({containerPort: 8080, hostPort: 8080});
    
    const mongo = taskDefinition.addContainer('MongoDB', {
      image: ecs.ContainerImage.fromRegistry('mongo:latest'),
      memoryReservationMiB: 1024
    });
    
    mongo.addPortMappings({containerPort: 27017, hostPort: 27017});
    
    const service = new ecs_patterns.ApplicationLoadBalancedFargateService(this, 'UserManagerFargateService', {
      serviceName: 'UserManagerService',
      cluster: props.cluster,
      cpu: 512,
      desiredCount: 1,
      taskDefinition: taskDefinition,
      publicLoadBalancer: true
    });
    
    service.targetGroup.configureHealthCheck({
      path: '/v1/users/health'
    });
  }
}
