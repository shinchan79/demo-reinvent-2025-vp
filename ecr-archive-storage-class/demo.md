```
$ ./demo.sh 
==============================================
 Amazon ECR Archive Storage Class Demo
 Repo   : signed-demo-app
 Tag    : signed
 Region : ap-southeast-1
==============================================

1. Resolve image digest...
✓ Image digest: sha256:4dc0d9e74f067910df8a982c21afa9ce7aeb2c135bc306a74869cb17074c6b0f

2. Archive image (storage class -> ARCHIVE)...
{
    "registryId": "830427153490",
    "repositoryName": "signed-demo-app",
    "imageId": {
        "imageDigest": "sha256:4dc0d9e74f067910df8a982c21afa9ce7aeb2c135bc306a74869cb17074c6b0f"
    },
    "imageStatus": "ARCHIVED"
}
✓ Image archived

3. Verify image status...
ARCHIVED

4. Demo pull failure (EXPECTED)...
Error response from daemon: unknown: The requested image is in an inaccessible state. Please restore if needed

=================================================
 EXPECTED RESULT:
 - docker pull FAILS (404)
 - Image status = ARCHIVED

 To restore:
 aws ecr update-image-storage-class \
   --repository-name signed-demo-app \
   --image-id imageDigest=sha256:4dc0d9e74f067910df8a982c21afa9ce7aeb2c135bc306a74869cb17074c6b0f \
   --target-storage-class STANDARD
=================================================
```