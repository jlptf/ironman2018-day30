## Day 30 - 鐵人達成：厚臉皮自己講

### 本日共賞
* 邁向 DevOps 之路 (3)
* 進階延伸
* 賽後心得

### 希望你知道

* DevOps
* CI/CD
* [邁向 DevOps 之路 (2)](https://ithelp.ithome.com.tw/articles/10196286)


#### 邁向 DevOps 之路 (3)

[邁向 DevOps 之路 (2)](https://ithelp.ithome.com.tw/articles/10196286) 已經把所有的環節都打通，最後一個部分是如何部署不同的環境。k8s 可以利用命名空間來部署不同的環境，我們只要在 Jenkins 告訴 k8s 需要部署到哪個環境即可。就像昨天的 `master` 分支，我們把它當成 `develop` 內運作的程式，同樣的，如果要部署到 `production`，我們可以再開啟一個分支 `pro`，然後修改 `Jenkinsfile` 的內容即可達成。

由於 Ingress 不需要太常變動，因此我們可以直接部署 Ingress 物件到 `production` 中

```
# ingress.pro.yaml

---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ithome-ingress
  namespace: production   <=== 差別只有這個
spec:
  backend:
    serviceName: ithome
    servicePort: 80
```

部署 Ingress 到 `production`

```bash
$ kubectl apply -f ./k8s/ingress.pro.yaml
ingress "ithome-ingress" created

$ kubectl get ingress -n production
NAME             HOSTS     ADDRESS        PORTS     AGE
ithome-ingress   *         35.227.193.1   80        58s
```

同樣的，稍等一下就可以看到 Ingress 配置的 IP，接下來，修改一下 `Jenkinsfile` 的內容

```
# Jenkinsfile

... <=== 以上內容不變
switch (env.BRANCH_NAME) {
  case "pro":  <=== 新增加處理 pro 分支, proNamespace 即 production
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
    break
}
```

聰明的你，看到 `Jenkinsfile` 的內容應該能猜到接下來就是要開 git 分支了吧！

```bash
$ git checkout -b pro   <=== 這個分支名稱要跟 Jenkinsfile case 裡的一樣
Switched to a new branch 'pro'

<=== 請修改 Jenkinsfile 內容後再上傳
$ git add .
$ git commit -m 'modify Jenkinsfile for production'
[pro 6114044] modify Jenkinsfile for production
 1 file changed, 6 insertions(+), 1 deletion(-)
$ git push origin pro
Counting objects: 3, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 386 bytes | 0 bytes/s, done.
Total 3 (delta 1), reused 0 (delta 0)
remote: Resolving deltas: 100% (1/1), completed with 1 local object.
To git@github.com:jlptf/ironman2018-cicd.git
   45f32bb..6114044  pro -> pro
```

然後到 Jenkins 你就會發現開始工作了！

![https://ithelp.ithome.com.tw/upload/images/20180116/2010706271ddYoVLWM.png](https://ithelp.ithome.com.tw/upload/images/20180116/2010706271ddYoVLWM.png)


查看一下 `production` 的內容

```bash
$ kubectl get pods -n production
NAME                      READY     STATUS    RESTARTS   AGE
ithome-66d86467c5-mw6mx   1/1       Running   0          32s

$ kubectl get service -n production
NAME      TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
ithome    NodePort   10.59.255.160   <none>        80:31615/TCP   48s
```

接下來當然是透過 Ingress 的 IP 去看看我們的應用程式  

![https://ithelp.ithome.com.tw/upload/images/20180116/20107062IuqEljxt94.png](https://ithelp.ithome.com.tw/upload/images/20180116/20107062IuqEljxt94.png)

恭喜你！又離 DevOps 更進一步了！覺不覺得老是只看到 Nginx 的畫面很無趣，我們接下來嘗試部署 [Day 26 - 部署多階層應用：簡易通訊錄 SAB](https://ithelp.ithome.com.tw/articles/10195946) 提到的 `SAB`。你可以先[下載原始碼](https://github.com/jlptf/ironman2018-day26)，把檔案放到 `master` 分支底下。

先切換到 `master`

> 你也可以先合併分支再更新原始碼，不過這邊就直接切換分支不合併了

```bash
$ git checkout master
Switched to branch 'master'
Your branch is up-to-date with 'origin/master'.
```

接下來修正後的目錄結構應該會是這樣

![https://ithelp.ithome.com.tw/upload/images/20180116/20107062Vr9PDwx5JW.png](https://ithelp.ithome.com.tw/upload/images/20180116/20107062Vr9PDwx5JW.png)

* `go`：請把整個 `/SAB/go` 的資料夾複製過來
* `Dockerfile`：請修正為 `/SAB/Dockerfile` 的內容

然後上傳到 git

```bash
$ git add .
$ git commit -m 'deploy SAB'
[master 756dc53] deploy SAB
 4 files changed, 309 insertions(+), 1 deletion(-)
 create mode 100644 go/app.go
 create mode 100644 go/pages/err.html
 create mode 100644 go/pages/home.html
$ git push
Counting objects: 8, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (8/8), done.
Writing objects: 100% (8/8), 3.05 KiB | 0 bytes/s, done.
Total 8 (delta 0), reused 0 (delta 0)
To git@github.com:jlptf/ironman2018-cicd.git
   45f32bb..756dc53  master -> master
```

這時候，你就會看到 Jenkins 開始工作了！

![https://ithelp.ithome.com.tw/upload/images/20180116/20107062pRcBw8KgxK.png](https://ithelp.ithome.com.tw/upload/images/20180116/20107062pRcBw8KgxK.png)

忘記 `develop` 的 Ingress IP 了對吧？

```bash
$ kubectl get ingress --namespace develop
NAME             HOSTS     ADDRESS          PORTS     AGE
ithome-ingress   *         35.201.123.133   80        2d
```

開瀏覽器一看，你會發現你看不到東西？原來我們忘記一個重要的東西，`SAB` 裡面還需要用到 mongo 資料庫啊！沒關係，再修改一下 `Jenkinsfile`

```
...
case "master":
    // replace namespace settings
    sh("sed -i.bak 's#env: current#env: ${devNamespace}#' ./k8s/service.yaml")
    sh("sed -i.bak 's#env: current#env: ${devNamespace}#' ./k8s/deploy.yaml")
    sh("kubectl --namespace=${devNamespace} apply -f ./k8s/service.yaml")
    sh("kubectl --namespace=${devNamespace} apply -f ./k8s/deploy.yaml")
    <=== 多增加一個部署 mongodb，要記得放到 k8s 資料夾裡喔！
    sh("kubectl --namespace=${devNamespace} apply -f ./k8s/mongodb.yaml")
    break
```

另外別忘了修改 `deploy.yaml` 裡關於 mongodb env 的設定

```
# deploy.yaml

...
containers:
  - name: ithome
    image: gcr.io/ithome-image
    resources:
      limits:
        memory: 0
        cpu: 0
    imagePullPolicy: Always
    env:       <=== 環境變數是給 go 參考用的，別忘了！
    - name: SERVER_PORT
      value: "80"
    - name: DB_SERVER
      value: "mongodb-svc"
    ports:
    - containerPort: 80
      protocol: TCP
  restartPolicy: Always
```

都完成以後就可以上傳到 git 了

```bash
$ git add .
$ git commit -m 'add mongodb'
$ git push
```

過一下子就可以發現，應用程式已完成部署

```bash
$ kubectl get pods --namespace develop
NAME                      READY     STATUS        RESTARTS   AGE
ithome-5c799d4f7b-brdhs   1/1       Running       0          6m
mongodb                   1/1       Running       0          6m

$ kubectl get service --namespace develop
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
ithome        NodePort    10.59.253.12    <none>        80:30561/TCP   2d
mongodb-svc   ClusterIP   10.59.245.229   <none>        27017/TCP      5m
```

最後打開瀏覽器

![https://ithelp.ithome.com.tw/upload/images/20180116/20107062rSnmluzKRq.png](https://ithelp.ithome.com.tw/upload/images/20180116/20107062rSnmluzKRq.png)


> 這邊是故意忘東忘西的！這是要順便提醒大家，就算是有經驗的老手，有時候也會因為一個不注意就失誤。大家千萬不要因為一點挫折就放棄喔！

#### 進階延伸

這次分享的文章比較偏初階入門，一方面是想把 k8s 這個有趣的東西與大家分享，另外一方面是感覺關於 k8s 中文入門的文章有點稀少對於新手來說 (嚴格來說我也算是個新手...) 有一定的門檻，再來是這些內容也算是給自己提個醒 (有時候突然忘記可以有東西參考一下)。

在熟悉 k8s 基本的概念與操作後，你可以了解更多關於

* [Job](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/)：運行一個或多個 Pod 來執行工作，例如：檢查資料庫某些狀態或者擷取網站某些資訊等等。
* [CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)：類似例行性排程工作 (crontab)，你可以用它來定期部署一個 `Job` 並執行相關工作。
* [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)：當你的應用程式需要以 `有狀態系統` 設計時，可以參考使用。例如：部署需要依循一定的順序等等。
* [Third Party Resources](https://kubernetes.io/docs/tasks/access-kubernetes-api/extend-api-third-party-resource/)：k8s 提供的物件大多能滿足需求，但是如果你想要建立自己的客製物件，可以參考使用。
* [Kubernetes Federation](https://kubernetes.io/docs/concepts/cluster-administration/federation/)：如果你需要透過單一個介面管理多個 k8s 叢集時可以參考使用
* [Heapster](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)：可以用來監看 k8s 狀態與事件
* [Prometheus](https://prometheus.io/)：另外一個事件監控工具
* [fluentd](https://www.fluentd.org/)：用來收集 Log 資料以便進行分析
* 還有好多...，可以參考 [官方網站](https://kubernetes.io/)


#### 手動安裝

如果對手動安裝 k8s 有興趣的朋友可以參考 [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)，該文章會一步一步帶著你在 GCP 上手動安裝 k8s。

#### 其他資訊

* [Kubernetes Taiwan User Group](https://zh-tw.facebook.com/groups/k8s.tw/)：FB kubernetes 社團，是很活躍的一個社團，常常有關於 k8s 資訊的分享，也會有人提問與解答，個人覺得挺不錯的。
* [kubernetesio](https://www.facebook.com/kubernetesio/)：FB kubernetes 官方社團，k8s 的消息都會在這裡看得到。
* [DevOps Taiwan](https://www.facebook.com/groups/DevOpsTaiwan/)：FB DevOps 社團，這也是一個相當活躍的社團，主題不限於 k8s，而是與 DevOps 所有相關的議題，也很推薦給大家參考。
* [kubernetes 中文社區](https://www.kubernetes.org.cn/)：k8s 中文社區簡體版，如果習慣看簡體版的朋友，這邊也有不錯的文章可以參考。
* [Certified Kubernetes Administrator](https://www.cncf.io/certification/expert/)：如果你對 k8s 的證照有興趣可以參考。
* [官方網站](https://kubernetes.io/)：不用解釋，詳細的資料都會在這裡。


#### 賽後心得

不知不覺就這樣過了三十天...才沒有好嗎！本來以為三十天很快就過去了，應該不會太困難，但真實的狀況是每天都嘔心瀝血啊！一下子詞窮，一下子發現操作有問題，還好都一一克服了。完賽之後，除了對曾經完賽過的鐵人們感到佩服之外，也深深感受到這是一件很有壓力的事情。透過這三十天的經驗，發現要寫一篇讓人喜愛的文章真是不容易啊！另外，除了發表鐵人文章，還要上班解 bugs！可能是 bugs 知道我要參加鐵人賽，紛紛出來跟我打招呼。不過，總算是完賽了！給我自己鼓勵一下！！

最後，感謝 [ithome](https://ithelp.ithome.com.tw/) 舉辦這樣有趣的活動，希望 IT 人都至少來參加一次，不只是挑戰自己更多的是發現自己對於主題了解程度與不足之處！

> 題外話：bugs 再解不掉我就死定了！
