# Welcome to Shop Backend CDK TypeScript project!

This project shows how to set up a CDK pipeline for a Vapor project.
The Shop Backend code is from the book `Hands-On Swift 5 Microservices Development`
by Ralph Kuepper, with some small changes. This example uses MongoDB instead of
MySQL, and the JWT is slightly different.

I have implemented the REST API for UserService, but haven't done anything yet
for OrderService and ProductService. That will come in a later commit.

The `cdk.json` file tells the CDK Toolkit how to execute your app.

## Useful commands

 * `npm run build`   compile typescript to js
 * `npm run watch`   watch for changes and compile
 * `npm run test`    perform the jest unit tests
 * `cdk deploy`      deploy this stack to your default AWS account/region
 * `cdk diff`        compare deployed stack with current state
 * `cdk synth`       emits the synthesized CloudFormation template
