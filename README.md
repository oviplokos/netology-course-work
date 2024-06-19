<img width="454" alt="prometeus_curl" src="https://github.com/oviplokos/netology-course-work/assets/81755488/474ef702-d5c4-43b1-a035-ceda0fb8ce74">
#  Курсовая работа на профессии "DevOps-инженер с нуля"

---------
## Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/).


## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible. 

Параметры виртуальной машины (ВМ) подбирайте по потребностям сервисов, которые будут на ней работать. 

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Prometheus. На каждую ВМ из веб-серверов установите Node Exporter и [Nginx Log Exporter](https://github.com/martin-helmich/prometheus-nginxlog-exporter). Настройте Prometheus на сбор метрик с этих exporter.

Создайте ВМ, установите туда Grafana. Настройте её на взаимодействие с ранее развернутым Prometheus. Настройте дешборды с отображением метрик, минимальный набор — Utilization, Saturation, Errors для CPU, RAM, диски, сеть, http_response_count_total, http_response_size_bytes. Добавьте необходимые [tresholds](https://grafana.com/docs/grafana/latest/panels/thresholds/) на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Prometheus, Elasticsearch поместите в приватные подсети. Сервера Grafana, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh. Настройте все security groups на разрешение входящего ssh из этой security group. Эта вм будет реализовывать концепцию bastion host. Потом можно будет подключаться по ssh ко всем хостам через этот хост.

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.


## Решение
С помощью терраформ и ансибл были созданы необходимые виртуальные машины,а так же настроено все необходимое ПО
Так же были созданы группы безопасности, балансировщик, две ДНС зоны с доменными именнами для внешних и внутренних сервисов.
Созданы снапшоты дисков и расписание копирования.
Скриншоты работы
![VM](https://github.com/oviplokos/netology-course-work/blob/main/images/1-1.png)
![bg](https://github.com/oviplokos/netology-course-work/blob/main/images/bg.png)
![instance_group](https://github.com/oviplokos/netology-course-work/blob/main/images/instance_group.png)
![lb](https://github.com/oviplokos/netology-course-work/blob/main/images/lb.png)
![lb_web](https://github.com/oviplokos/netology-course-work/blob/main/images/lb_web.png)
![nginx1](https://github.com/oviplokos/netology-course-work/blob/main/images/nginx1.png)
![nginx2](https://github.com/oviplokos/netology-course-work/blob/main/images/nginx2.png)
![prometeus](https://github.com/oviplokos/netology-course-work/blob/main/images/prometeus.png)
![prometeus_curl](https://github.com/oviplokos/netology-course-work/blob/main/images/prometeus_curl.png)
![pub_ip](https://github.com/oviplokos/netology-course-work/blob/main/images/pub_ip.png)
![public_dns_zone](https://github.com/oviplokos/netology-course-work/blob/main/images/public_dns_zone.png)
![sg](https://github.com/oviplokos/netology-course-work/blob/main/images/sg.png)
![snapshedule](https://github.com/oviplokos/netology-course-work/blob/main/images/snapshedule.png)
![snapshots](https://github.com/oviplokos/netology-course-work/blob/main/images/snapshots.png)
![tg](https://github.com/oviplokos/netology-course-work/blob/main/images/tg.png)
![dns_zones](https://github.com/oviplokos/netology-course-work/blob/main/images/dns_zones.png)
![elc](https://github.com/oviplokos/netology-course-work/blob/main/images/elc.png)
![grafana](https://github.com/oviplokos/netology-course-work/blob/main/images/grafana.png)
![http-router](https://github.com/oviplokos/netology-course-work/blob/main/images/http-router.png)
![kibana_index](https://github.com/oviplokos/netology-course-work/blob/main/images/kibana_index.png)
![kibana_logs](https://github.com/oviplokos/netology-course-work/blob/main/images/kibana_logs.png)





## Критерии сдачи
1. Инфраструктура отвечает минимальным требованиям, описанным в [Задаче](#Задача).
2. Предоставлен доступ ко всем ресурсам, у которых предполагается веб-страница (сайт, Kibana, Grafanа).
3. Для ресурсов, к которым предоставить доступ проблематично, предоставлены скриншоты, команды, stdout, stderr, подтверждающие работу ресурса.
4. Работа оформлена в отдельном репозитории в GitHub или в [Google Docs](https://docs.google.com/), разрешён доступ по ссылке. 
5. Код размещён в репозитории в GitHub.
6. Работа оформлена так, чтобы были понятны ваши решения и компромиссы. 
7. Если использованы дополнительные репозитории, доступ к ним открыт. 
