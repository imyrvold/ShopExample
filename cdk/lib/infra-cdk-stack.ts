import * as cdk from '@aws-cdk/core';
import * as ec2 from '@aws-cdk/aws-ec2';
import * as ecs from '@aws-cdk/aws-ecs';

export class InfraCdkStack extends cdk.Stack {
	readonly vpc: ec2.IVpc;
	readonly cluster: ecs.ICluster;
	
	constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
		super(scope, id, props)
		
		this.vpc = new ec2.Vpc(this, 'ShopVpc', {
			maxAzs: 3
		});
		this.cluster = new ecs.Cluster(this, 'ShopCluster', {
			vpc: this.vpc
		});
	}
}

export interface ShopStackProps extends cdk.StackProps {
	vpc: ec2.IVpc;
	cluster: ecs.ICluster;
}