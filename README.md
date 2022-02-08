# static-website
A simple static website to explore how an [AWS CodePipeline](https://docs.aws.amazon.com/codepipeline/index.html) can be used to automatically deploy updates when commits are made to a GitHub repo. The intent was to produce a generic piece of infrastructure code that could be added to a static website repo without a lot of effort.

To use this code, run `infra/bootstrap.sh` once and the pipeline should be configured and ready to go. It will perform the following steps:

1. Launch the bootstrap.yml [CloudFormation](https://aws.amazon.com/cloudformation/) template:
    1. Create a KMS key with alias `alias/${ProjectName}-${BranchName}-kmskey` to encrypt the code artifacts stored in an S3 bucket
    1. Create S3 bucket `${ProjectName}-${BranchName}-code-artifact` required by CodePipeline to store the code artifacts produced and consumed throughout the pipepline.
    1. Create an IAM role for the codepipeline to assume when running
    1. Create an IAM role for the webite pipeline to assume when deploying the artifacts to S3
    1. Create a CodePipeline to build the infrastructure needed:
        1. `Source` stage - pull the code from GitHub repo and store in the artifact S3 bucket
        1. `Deploy-Bucket` stage - use CloudFormation template `bucket.yml` to create the S3 static website bucket, configured to serve the HTML site
        1. `Deploy-Pipeline` stage - use CloudFormation template `pipeline.yml` to create the pipeline for updating website bucket with the latest code

* The bulk of this logic came from James Turner's [From GitHub to Continuous Deployment in 5 Minutes](https://aws.plainenglish.io/from-github-to-continuous-deployment-in-5-minutes-7f9c1c7702b1). Per his article, I also followed the steps in [Connecting Github to AWS Codepipeline](https://james-turner.medium.com/connecting-github-to-aws-codepipeline-ce19a4a2f213) which produces an *AWS GitHub (v2) connector* credentials-arn used in bootstrap.sh.
* The index page and background I based on Isabel Castillo's [Our Site Has Moved HTML Responsive Template](https://isabelcastillo.com/our-site-has-moved-html-responsive-template)
* The 404 page I based on the Bootstrap snippet [Simple & Clean 404 Error Page Design](https://bootsnipp.com/snippets/qr73D)
