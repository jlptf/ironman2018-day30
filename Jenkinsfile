//#####################################
//# 2018 ithome ironman
//# Author: James Lu
//# Topic: k8s 不自賞 - Day 30 鐵人達成
//# Url: https://ithelp.ithome.com.tw/articles/10197352
//# Licence: MIT
//#####################################

node{
    def project = 'stately-magpie-188902'
    def appName = 'ithome'
    def tag = "v_${env.BUILD_NUMBER}"
    def img = "gcr.io/${project}/${appName}-${env.BRANCH_NAME}"
    def imgWithTag = "${img}:${tag}"

    def devNamespace = 'develop'
    def proNamespace = 'production'

    checkout scm

    stage '建立映像檔'
    sh("docker build -t ${imgWithTag} .")

    stage '放置映像檔'
    sh("gcloud docker -- push ${imgWithTag} ")

    stage '部署'
    // replace as new image
    sh("sed -i.bak 's#gcr.io/ithome-image#${imgWithTag}#' ./k8s/deploy.yaml")
    switch (env.BRANCH_NAME) {
      case "pro": 
        // replace namespace settings
        sh("sed -i.bak 's#env: current#env: ${proNamespace}#' ./k8s/service.yaml")
        sh("sed -i.bak 's#env: current#env: ${proNamespace}#' ./k8s/deploy.yaml")
        sh("kubectl --namespace=${proNamespace} apply -f ./k8s/service.yaml")
        sh("kubectl --namespace=${proNamespace} apply -f ./k8s/deploy.yaml")
        break
      case "master":
        // replace namespace settings
        sh("sed -i.bak 's#env: current#env: ${devNamespace}#' ./k8s/service.yaml")
        sh("sed -i.bak 's#env: current#env: ${devNamespace}#' ./k8s/deploy.yaml")
        sh("kubectl --namespace=${devNamespace} apply -f ./k8s/service.yaml")
        sh("kubectl --namespace=${devNamespace} apply -f ./k8s/deploy.yaml")
        sh("kubectl --namespace=${devNamespace} apply -f ./k8s/mongodb.yaml")
        break
    }
}
