### argoCD  
helm chart: https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd  
```  
helm repo add argo https://argoproj.github.io/argo-helm

```  

- admin password 설정  
```
apt install apache2-utils  
htpasswd -nbBC 10 "" $ARGO_PWD | tr -d ':\n' | sed 's/$2y/$2a/' 
```

- install  /w ingress, passwd
```
kubectl create ns argocd
helm install argocd argo/argo-cd -n argocd -f values.yaml 
```  

- uninstall with CRD  
```
kubectl delete -k "https://github.com/argoproj/argo-cd/manifests/crds"
'''
