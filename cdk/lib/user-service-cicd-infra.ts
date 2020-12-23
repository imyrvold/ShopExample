import * as cdk from '@aws-cdk/core';
import * as codepipeline from '@aws-cdk/aws-codepipeline';
import * as codepipeline_actions from '@aws-cdk/aws-codepipeline-actions';
import * as codebuild from '@aws-cdk/aws-codebuild';
import * as ecr from '@aws-cdk/aws-ecr';
import * as iam from '@aws-cdk/aws-iam';
import * as pipelines from '@aws-cdk/pipelines';
import * as secretsmanager from '@aws-cdk/aws-secretsmanager';

import { LocalDeploymentStage } from './local-deployment';

export class UserServiceCicdInfraStack extends cdk.Stack {
	constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
		super(scope, id, props)
		
		const sourceArtifact = new codepipeline.Artifact();
		const cdkOutputArtifact = new codepipeline.Artifact();
		
		const pipeline = new pipelines.CdkPipeline(this, 'CdkPipeline', {
			crossAccountKeys: false,
			pipelineName: 'cdk-cdkpipeline',
			cloudAssemblyArtifact: cdkOutputArtifact,
			
			sourceAction: new codepipeline_actions.GitHubSourceAction({
				actionName: 'DownloadSources',
				owner: 'imyrvold',
				repo: 'ShopExample',
				branch: 'dev',
				oauthToken: cdk.SecretValue.secretsManager('github-token'),
				output: sourceArtifact
			}),
			
			synthAction: pipelines.SimpleSynthAction.standardNpmSynth({
				sourceArtifact: sourceArtifact,
				cloudAssemblyArtifact: cdkOutputArtifact,
				subdirectory: 'cdk'
			})
		});
		
		// Build and Publish application artifacts
		const repository = new ecr.Repository(this, 'Repository', { repositoryName: 'cdk-cicd/user-manager'});
		
		const buildRole = new iam.Role(this, 'DockerBuildRole', {
			assumedBy: new iam.ServicePrincipal('codebuild.amazonaws.com')
		});
		repository.grantPullPush(buildRole);
		
		const mongoSecret = new secretsmanager.Secret(this, 'mongodb');
		const sendgridSecret = new secretsmanager.Secret(this, 'sendgrid');
		const jwksSecret = new secretsmanager.Secret(this, 'jwkskeypair');
		
		const project = new codebuild.Project(this, 'DockerBuild', {
			role: buildRole,
			environment: {
				buildImage: codebuild.LinuxBuildImage.STANDARD_4_0,
				privileged: true,
				environmentVariables: {
					MONGODB: {
						value: mongoSecret.secretArn
					},
					SENDGRID_API_KEY: {
						value: sendgridSecret.secretArn
					},
					JWKS_KEYPAIR: {
						value: jwksSecret.secretArn
					}
				}
			},
			buildSpec: this.getDockerBuildSpec(repository.repositoryUri)
		});
				
		project.addToRolePolicy(
			new iam.PolicyStatement({
				effect: iam.Effect.ALLOW,
				actions: [
					'secretsmanager:GetRandomPassword',
					'secretsmanager:GetResourcePolicy',
					'secretsmanager:GetSecretValue',
					'secretsmanager:DescribeSecret',
					'secretsmanager:ListSecretVersionIds'
				],
				resources: [mongoSecret.secretArn]
			})
		)

		
		const buildStage = pipeline.addStage('AppBuild');
		buildStage.addActions(new codepipeline_actions.CodeBuildAction({
			actionName: 'DockerBuild',
			input: sourceArtifact,
			project: project
		}));
		
		// Deploy - Local
		const localStage = new LocalDeploymentStage(this, 'AppDeployLocal');
		pipeline.addApplicationStage(localStage);
	}
	
	getDockerBuildSpec(repositoryUri: string): codebuild.BuildSpec {
		return codebuild.BuildSpec.fromObject({
			version: '0.2',
			phases: {
				pre_build: {
					commands: [
						'echo Logging in to Amazon ECR...',
						'$(aws ecr get-login --no-include-email --region $AWS_DEFAULT_REGION)'
					]
				},
				build: {
					commands: [
						'echo Build started on `date`',
						'echo Building the Docker image...',
						`docker build -f Dockerfile_UserService -t ${repositoryUri}:$CODEBUILD_RESOLVED_SOURCE_VERSION UserService/`
					]
				},
				post_build: {
					commands: [
						'echo Build completed on `date`',
						'echo Pushing the Docker image...',
						`docker push ${repositoryUri}:$CODEBUILD_RESOLVED_SOURCE_VERSION`
					]
				}
			}
		});
	}
}