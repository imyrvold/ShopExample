#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from '@aws-cdk/core';
import { UserServiceCicdInfraStack } from '../lib/user-service-cicd-infra';

const app = new cdk.App();
new UserServiceCicdInfraStack(app, 'CicdInfraStack');

app.synth();