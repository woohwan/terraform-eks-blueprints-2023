### for ECR
- user jenkinsecr  (persmission: ECR power user) 생성 후, credential  생성
- ECR push를 위한 secret 생성
```
$ echo << EOF > credentials
[default]
aws_access_key_id = jenkinsecr_access_key
aws_secret_access_key = jenkinsecr_secret_key
EOF

$ kubectl create secret generic ecr-cred --from-file=credentials -n jenkins
```

### for Docker Hub
- Docker Regeistry login을 위한 secret 생성
```
kubectl create secret docker-registry dockercred \
--docker-server=https://index.docker.io/v1/ \
--docker-username=whpark70 \
--docker-password=password \
--docker-email=whpark70@example.com -n jenkins
```