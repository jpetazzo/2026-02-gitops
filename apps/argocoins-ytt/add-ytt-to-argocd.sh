#!/bin/sh

kubectl apply -f- <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: cmp-ytt
data:
  plugin.yaml: |
    apiVersion: argoproj.io/v1alpha1
    kind: ConfigManagementPlugin
    metadata:
      name: ytt
    spec:
      version: v1.0
      init:
        command: [sh, -c, 'echo "Initializing..."']
      generate:
        command: [ytt, -f, .]
      #discover:
      #  fileName: "./subdir/s*.yaml"
YAML

kubectl patch deployment argocd-repo-server --patch "
spec:
  template:
    spec:
      volumes:
      - name: tools
      - name: cmp-ytt
        configMap:
          name: cmp-ytt
      initContainers:
      - name: download-ytt
        image: jpetazzo/shpod
        command:
        - cp
        - /usr/local/bin/ytt
        - /tools/ytt
        volumeMounts:
        - name: tools
          mountPath: /tools
      containers:
      - name: cmp-ytt
        image: quay.io/argoproj/argocd:v3.3.0
        command: [ argocd-cmp-server ]
        securityContext:
          runAsNonRoot: true
          runAsUser: 999
        volumeMounts:
        - mountPath: /usr/local/bin/ytt
          name: tools
          subPath: ytt
        - mountPath: /var/run/argocd
          name: var-files
        - mountPath: /home/argocd/cmp-server/plugins
          name: plugins
        - mountPath: /home/argocd/cmp-server/config/plugin.yaml
          subPath: plugin.yaml
          name: cmp-ytt
"
