# field-report-delphi
Sample application demonstrating AWS SDK including S3, SNS, and SQS

## Overview
The Field Report sample demonstrates a workflow capturing data in a
"Field Report" app which is uploaded to an "inbound reports" bucket on Amazon
S3. The uploaded reports trigger a notification to an Amazon SNS topic which
will notify any subscribers. An Amazon SQS queue for "new reports" is subscribed
to the SNS topic. A "Review" application (or multiple of) can receive messages
from the SQS queue to "Review" and potentially take some action.

## Progress
The current apps have pretty basic/rough UIs that probably need a little polish
before presentation.

- [x] CloudFormation script to deploy resources on AWS.
  - [x] IAM Users and credentials for front-end applications.
- [ ] Field Report app.
  - [x] Take photo.
  - [x] Attach notes.
  - [x] Upload to S3.
  - [ ] Register for push notifications.
- [ ] Review app.
  - [x] Poll "new messages"  queue.
  - [x] Fetch photo from S3.
  - [x] Display photo.
  - [x] Provide countdown timer for message expiration.
  - [ ] Archive action?
  - [ ] Discard action?
- [ ] Push notifications to devices.

## Requirements
- AWS Account
- RAD Studio/Delphi
- Appercept AWS SDK for Delphi

## Setup
In order to run the sample apps, resources need to be deployed on AWS.

1. Sign in to the [AWS Console](https://console.aws.amazon.com/).
2. Navigate to the [AWS CloudFormation Console](https://console.aws.amazon.com/cloudformation/home).
3. Create a stack based on the `CloudFormation/FieldReport.yml` template.
   Specify a "Stack name" and accept all defaults.
4. Once the stack has successfully created, copy the values from the stack's
   Outputs tab into the relevant constants defined in each `Settings.pas` for
   each Delphi project.

## Costs
The resources used in this demo have costs but are minimal. Some services have a
"free tier" so this demonstration would not incur fees for some of the resources
used. For detailed explanation of potential costs refer to Amazon's pricing
guides for the relevant services:
- https://aws.amazon.com/s3/pricing/
- https://aws.amazon.com/sns/pricing/
- https://aws.amazon.com/sqs/pricing/
