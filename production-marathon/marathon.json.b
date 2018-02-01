{
    "id": "jobservice",
    "apps": [{
            "id": "job-service",
            "cpus": 0.5,
            "mem": 1024,
            "instances": 1,
            "container": {
                "docker": {
                    "image": "jobservice/job-service:2.4.0",
                    "network": "BRIDGE",
                    "portMappings": [{
                        "containerPort": 8080,
                        "hostPort": 0,
                        "protocol": "tcp",
                        "servicePort": ${JOB_SERVICE_8080_SERVICE_PORT}
                    }],
                    "forcePullImage": true
                },
                "type": "DOCKER"
            },
            "env": {
                "_JAVA_OPTIONS": "-Xms512m -Xmx512m",
                "CAF_DATABASE_URL": "jdbc:postgresql://${JOB_SERVICE_DB_HOSTNAME}:${JOB_SERVICE_DB_PORT}/jobservice",
                "CAF_DATABASE_USERNAME": "${JOB_SERVICE_DB_USER}",
                "CAF_DATABASE_PASSWORD": "${JOB_SERVICE_DB_PASSWORD}",
                "CAF_TRACKING_PIPE": "jobtracking-in",
                "CAF_STATUS_CHECK_TIME": "5",
                "CAF_WEBSERVICE_URL": "http://${JOB_SERVICE_HOST}:${JOB_SERVICE_8080_SERVICE_PORT}/job-service/v1",
                "CAF_RABBITMQ_HOST": "${CAF_RABBITMQ_HOST}",
                "CAF_RABBITMQ_PORT": "${CAF_RABBITMQ_PORT}",
                "CAF_RABBITMQ_USERNAME": "${CAF_RABBITMQ_USERNAME}",
                "CAF_RABBITMQ_PASSWORD": "${CAF_RABBITMQ_PASSWORD}"
            },
            "healthChecks": [{
                "protocol": "HTTP",
                "gracePeriodSeconds": 300,
                "intervalSeconds": 120,
                "maxConsecutiveFailures": 5,
                "path": "/",
                "timeoutSeconds": 20
            }]
        },
        {
            "id": "jobtracking",
            "cpus": 0.5,
            "mem": 1024,
            "instances": 1,
            "container": {
                "type": "DOCKER",
                "docker": {
                    "image": "jobservice/worker-jobtracking:2.4.0",
                    "network": "BRIDGE",
                    "forcePullImage": true,
                    "portMappings": [{
                            "containerPort": 8080,
                            "hostPort": 0,
                            "protocol": "tcp",
                            "servicePort": ${JOB_TRACKING_8080_SERVICE_PORT}
                        },
                        {
                            "containerPort": 8081,
                            "hostPort": 0,
                            "protocol": "tcp",
                            "servicePort": ${JOB_TRACKING_8081_SERVICE_PORT}
                        }
                    ]
                }
            },
            "env": {
                "_JAVA_OPTIONS": "-Xms512m -Xmx512m",
                "CAF_WORKER_INPUT_QUEUE": "jobtracking-in",
                "CAF_WORKER_OUTPUT_QUEUE": "jobtracking-out",
                "JOB_DATABASE_URL": "jdbc:postgresql://${JOB_SERVICE_DB_HOSTNAME}:${JOB_SERVICE_DB_PORT}/jobservice",
                "JOB_DATABASE_USERNAME": "${JOB_SERVICE_DB_USER}",
                "JOB_DATABASE_PASSWORD": "${JOB_SERVICE_DB_PASSWORD}",
                "CAF_WEBSERVICE_URL": "http://${JOB_SERVICE_HOST}:${JOB_SERVICE_8080_SERVICE_PORT}/job-service/v1",
                "CAF_RABBITMQ_HOST": "${CAF_RABBITMQ_HOST}",
                "CAF_RABBITMQ_PORT": "${CAF_RABBITMQ_PORT}",
                "CAF_RABBITMQ_USERNAME": "${CAF_RABBITMQ_USERNAME}",
                "CAF_RABBITMQ_PASSWORD": "${CAF_RABBITMQ_PASSWORD}"
            },
            "healthChecks": [{
                "path": "/healthcheck",
                "protocol": "HTTP",
                "portIndex": 1,
                "gracePeriodSeconds": 300,
                "intervalSeconds": 120,
                "maxConsecutiveFailures": 5,
                "timeoutSeconds": 20
            }],
            "labels": {
                "autoscale.metric": "rabbitmq",
                "autoscale.scalingtarget": "jobtracking-in",
                "autoscale.scalingprofile": "default",
                "autoscale.maxinstances": "4",
                "autoscale.mininstances": "0",
                "autoscale.interval": "30",
                "autoscale.backoff": "10"
            }
        },
        {
            "id": "job-service-scheduled-executor",
            "cpus": 0.25,
            "mem": 512,
            "instances": 1,
            "container": {
                "type": "DOCKER",
                "docker": {
                    "image": "jobservice/job-service-scheduled-executor:2.4.0",
                    "network": "BRIDGE",
                    "forcePullImage": true,
                    "portMappings": [{
                            "containerPort": 8081,
                            "hostPort": 0,
                            "servicePort": 0,
                            "protocol": "tcp"
                    }]
                }
            },
            "env": {
                "_JAVA_OPTIONS": "-Xms512m -Xmx512m",
                "CAF_WORKER_INPUT_QUEUE": "jobservicescheduler-in",
                "CAF_DATABASE_URL": "jdbc:postgresql://${JOB_SERVICE_DB_HOSTNAME}:${JOB_SERVICE_DB_PORT}/jobservice",
                "CAF_DATABASE_USERNAME": "${JOB_SERVICE_DB_USER}",
                "CAF_DATABASE_PASSWORD": "${JOB_SERVICE_DB_PASSWORD}",
                "CAF_TRACKING_PIPE": "jobtracking-in",
                "CAF_STATUS_CHECK_TIME": "5",
                "CAF_WEBSERVICE_URL": "http://${JOB_SERVICE_HOST}:${JOB_SERVICE_8080_SERVICE_PORT}/job-service/v1",
                "CAF_RABBITMQ_HOST": "${CAF_RABBITMQ_HOST}",
                "CAF_RABBITMQ_PORT": "${CAF_RABBITMQ_PORT}",
                "CAF_RABBITMQ_USERNAME": "${CAF_RABBITMQ_USERNAME}",
                "CAF_RABBITMQ_PASSWORD": "${CAF_RABBITMQ_PASSWORD}",
                "CAF_SCHEDULED_EXECUTOR_PERIOD": "10"
            },
            "healthChecks": [{
                "path": "/healthcheck",
                "portIndex": 0,
                "protocol": "HTTP",
                "gracePeriodSeconds": 300,
                "intervalSeconds": 120,
                "maxConsecutiveFailures": 5,
                "timeoutSeconds": 20
            }],
            "labels": {
                "MARATHON_SINGLE_INSTANCE_APP": "true"
            },
            "upgradeStrategy": {
                "minimumHealthCapacity": 0,
                "maximumOverCapacity": 0
            }
        }]
}