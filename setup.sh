#!/bin/bash
set -e

clear
echo "------------------------------------------------------------------------------------------"
echo ""
echo "  _____    _    _                    ___           _                         ____ ____    "
echo " |_   _|__| | _| |_ ___  _ __       ( _ )         / \   _ __ __ _  ___      / ___|  _ \   "
echo "   | |/ _ \ |/ / __/ _ \| '_ \      / _ \/\      / _ \ | '__/ _  |/ _ \    | |   | | | |  "
echo "   | |  __/   <| || (_) | | | |    | (_>  <     / ___ \| | | (_| | (_) |   | |___| |_| |  "
echo "   |_|\___|_|\_\\__\___/|_| |_|     \___/\/    /_/   \_\_|  \__, |\___/     \____|____/   "
echo "                                                            |___/ "
echo ""
echo "------------------------------------------------------------------------------------------"

initK8SResources() {
  # Setup Tekton
  kubectl create namespace tekton-pipelines | true
  kubectl apply -f tekton/operator/install.yaml
  kubectl apply -f tekton/operator/config.yaml
  kubectl apply -f k8s -n tekton-pipelines
  kubectl apply -f tekton/dashboard

  # Setup Argocd
  kubectl create namespace argocd | true
  kubectl apply -f argocd/argocd-install.yaml -n argocd
  kubectl apply -f secret/argocd-secret.yaml
  kubectl apply -f argocd/argocd-cm.yaml -n argocd
  kubectl apply -f argocd/argocd-rbac-cm.yaml -n argocd
  kubectl patch secret -n argocd argocd-secret -p '{"stringData": { "admin.password": "'$(htpasswd -bnBC 10 "" opZEIlzV0m | tr -d ':\n')'"}}'

  echo '-------------------------------------------------'
  echo 'Be patient while the pods are ready for you  '
  echo '-------------------------------------------------'

}

installPoCResources() {
  echo ""
  echo "Deploying configmaps, tasks, pipelines and ArgoCD application"
  kubectl apply -f secret/tekton-secret.yaml -n tekton-pipelines
  kubectl apply -f tekton/trigger -n tekton-pipelines
  kubectl apply -f tekton/pipelines -n tekton-pipelines
  kubectl apply -f tekton/operator/git-token-role.yaml
  kubectl apply -f tekton/operator/rbac.yaml
  kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/github-app-token/0.2/github-app-token.yaml -n tekton-pipelines
  kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/master/task/git-clone/0.4/git-clone.yaml -n tekton-pipelines
  kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/master/task/buildah/0.2/buildah.yaml -n tekton-pipelines
  kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/aws-ecr-login/0.1/aws-ecr-login.yaml -n tekton-pipelines
  kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/github-set-status/0.2/github-set-status.yaml -n tekton-pipelines
  kubectl apply -f tekton/tasks -n tekton-pipelines
  kubectl apply -f argocd/project
  sh ingress/cert-manager.sh
}

main() {
  initK8SResources
  installPoCResources
}

main
