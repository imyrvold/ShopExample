import * as cdk from '@aws-cdk/core';
import { UserServiceStack } from './user-service-stack';
import { InfraCdkStack } from './infra-cdk-stack';

export class LocalDeploymentStage extends cdk.Stage {
	constructor(scope: cdk.Construct, id: string, props?: cdk.StageProps) {
		super(scope, id, props);
		
		const infraStack = new InfraCdkStack(this, 'InfraCdkStack');
		
		const userManager = new UserServiceStack(this, 'UserManager', {
			vpc: infraStack.vpc,
			cluster: infraStack.cluster
		});
	}
}