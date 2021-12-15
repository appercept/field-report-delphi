# field-report-delphi
Sample application demonstrating AWS SDK including S3, SNS, and SQS.

## Overview
The Field Report sample demonstrates a workflow capturing data in a
"Field Report" app which is uploaded to an "inbound reports" bucket on Amazon
S3. The uploaded reports trigger a notification to an Amazon SNS topic which
will notify any subscribers. An Amazon SQS queue for "new reports" is subscribed
to the SNS topic. A "Review" application (or multiple of) can receive messages
from the SQS queue to "Review" and choose an action to take, either "Archive" or
"Discard". Choosing to "Archive" a report queues a message on another queue for
"archive reports". The "Archive" service is a command line service that listens
to the "archive reports" queue copying the report to an "archive bucket" for
each message received.

## Features/Progress
- [x] CloudFormation script to deploy resources on AWS.
  - [x] IAM Users and credentials for front-end applications.
- [x] Field Report app.
  - [x] Take photo.
  - [x] Attach notes.
  - [x] Upload to S3.
- [x] Review app.
  - [x] Poll "new reports" queue.
  - [x] Fetch photo from S3.
  - [x] Display photo.
  - [x] Provide countdown timer for message expiration.
  - [x] Archive action.
  - [x] Discard action.
- [x] Archive service.
  - [x] Poll "archive reports" queue.
  - [x] Copy objects to archive bucket on request.

## Requirements
- [AWS Account](https://aws.amazon.com)
- Embarcadero [RAD Studio](https://www.embarcadero.com/products/rad-studio) /
  [Delphi](https://www.embarcadero.com/products/delphi)
- [Appercept AWS SDK for Delphi](https://getitnow.embarcadero.com/aws-sdk-for-delphi-preview/)

## Setup
In order to run the sample apps, resources need to be deployed on AWS.

1. Sign in to the [AWS Console](https://console.aws.amazon.com/).
2. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/home).
3. Create a stack based on the `CloudFormation/FieldReport.yml` template.
   Specify a "Stack name" and accept all defaults.

## Compiling and running the apps
Once you have followed the setup to deploy the AWS resources, you can compile
and run the demo applications.
1. Open the `AWS SDK.groupproj`.
2. In each project within the group, there is a `Settings.pas`. The constants
   defined in the `Settings.pas` files marry up to the outputs published from
   the CloudFormation stack. Copy and paste the values from the CloudFormation
   console.
3. Build and run each project. The applications work independently so the order
   running them doesn't matter but each project needs to be running to see the
   demo as a whole.

You can experiment running multiple instances (even across different platforms)
of each program to see how the solution will scale with ease thanks to Amazon's
cloud architecture.

## Costs
The resources used in this demo have costs but are minimal. Some services have a
"free tier" so this demonstration would not incur fees for some of the resources
used. For detailed explanation of potential costs refer to Amazon's pricing
guides for the relevant services:
- https://aws.amazon.com/s3/pricing/
- https://aws.amazon.com/sns/pricing/
- https://aws.amazon.com/sqs/pricing/

## Cleaning up
After running the demo you will want to clean up the resources created to save
any potential ongoing costs. Follow these steps:
1. Navigate to the [Amazon S3 console](https://s3.console.aws.amazon.com).
2. Empty the buckets created as a part of the CloudFormation stack. If you're
   unsure of the buckets created, refer to the "Resources" tab on the
   CloudFormation stack details.
3. Delete the CloudFormation stack.
