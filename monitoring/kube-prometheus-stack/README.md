### kube-prometheus-stack  

- add helm repo
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```  

- install helm  
```  
kubectl create ns monitoring
helm install prometheus prometheus-community/kube-prometheus-stack  -n  monitoring -f values.yaml
```  


- uinstall
```  
helm uninstall prometheus -n monitoring
kubectl delete crd --all -n monitoring
kubectl delete ns monitoring

# CRDs created by this chart are not removed by default and should be manually cleaned up:
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com -n monitoring
kubectl delete crd alertmanagers.monitoring.coreos.com -n monitoring
kubectl delete crd podmonitors.monitoring.coreos.com -n monitoring
kubectl delete crd probes.monitoring.coreos.com -n monitoring
kubectl delete crd prometheuses.monitoring.coreos.com -n monitoring
kubectl delete crd prometheusrules.monitoring.coreos.com -n monitoring
kubectl delete crd servicemonitors.monitoring.coreos.com -n monitoring
kubectl delete crd thanosrulers.monitoring.coreos.com -n monitoring
```   

