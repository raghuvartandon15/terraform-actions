output "bucket_name"{
    value= aws_s3_bucket.model_bucket.bucket
}

output "repository_url"{
    value=aws_ecr_repository.image_repo.repository_url
}