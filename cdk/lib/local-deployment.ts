import * as cdk from '@aws-cdk/core';
import { CdkStack } from './cdk-stack';

export class LocalDeploymentStage extends cdk.Stage {
	constructor(scope: cdk.Construct, id: string, props?: cdk.StageProps) {
		super(scope, id, props);
		
		const shopExample = new CdkStack(this, 'ShopExample');
	}
}