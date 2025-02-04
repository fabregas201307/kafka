pipeline {
    agent { label 'dc16nix2p16'}
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        timeout(time: 3, unit: 'HOURS')
    }
    
    environment {
        RELEASE_NAME = 'fiqr-kafka-cluster'
        DEV_VAULT = 'kv-fiquantit-dev-001'
        DEV_REGISTRY_NAME = 'acrfiquantitdev001'
        QA_REGISTRY_NAME = 'acrfiquantitqa001'
        PROD_REGISTRY_NAME = 'acrfiquantitprod001'
        
        // Azure credentials
        AZ_SPN_USERNAME_DEV = credentials('fi-az-spn-username-dev')
        AZ_SPN_PWD_DEV = credentials('fi-az-spn-password-dev')
        AZ_SPN_USERNAME_QA = credentials('fi-az-spn-username-qa')
        AZ_SPN_PWD_QA = credentials('fi-az-spn-password-qa')
        AZ_TENANT_ID = credentials('fi-az-tenant-id')
        AZ_SPN_USERNAME_PROD = credentials('fi-az-spn-username-prod')
        AZ_SPN_PWD_PROD = credentials('fi-az-spn-password-prod')
    }

    stages {
        stage('Validate Configurations') {
            when {
                anyOf {
                    branch 'main';
                    branch 'develop';
                }
            }
            steps {
                sh '''
                    # Validate Kafka configurations
                    test -f config/server.properties
                    test -f config/zookeeper.properties
                    test -f config/log4j.properties
                    
                    # Validate scripts are executable
                    test -x scripts/health-check.sh
                    test -x scripts/init-topics.sh
                    test -x scripts/backup.sh
                    test -x scripts/monitoring.sh
                    test -x scripts/cleanup.sh
                '''
            }
        }

        stage('Build Container') {
            when {
                anyOf {
                    branch 'main';
                    branch 'develop';
                }
            }
            steps {
                sh '''
                    source /etc/profile.d/proxy.sh
                    az account clear
                    az login --service-principal -username $AZ_SPN_USERNAME_PROD -password $AZ_SPN_PWD_PROD --tenant $AZ_TENANT_ID
                    az account set --subscription "f91f2bd7-c90a-4b12-93cb-289573253eed"
                    az acr login --name $PROD_REGISTRY_NAME --username $AZ_SPN_USERNAME_PROD --password $AZ_SPN_PWD_PROD
                    make build
                '''
            }
        }

        stage('Run Tests') {
            when {
                anyOf {
                    branch 'main';
                    branch 'develop';
                }
            }
            steps {
                sh '''
                    make test
                '''
            }
        }

        stage('Push Image to PROD ACR') {
            when {
                anyOf {
                    branch 'main';
                }
            }
            steps {
                sh '''
                    echo ${BUILD_NUMBER}
                    source /etc/profile.d/proxy.sh
                    az account clear
                    az login --service-principal -username $AZ_SPN_USERNAME_PROD -password $AZ_SPN_PWD_PROD --tenant $AZ_TENANT_ID
                    az account set --subscription "f91f2bd7-c90a-4b12-93cb-289573253eed"
                    az acr login --name $PROD_REGISTRY_NAME --username $AZ_SPN_USERNAME_PROD --password $AZ_SPN_PWD_PROD
                    make push
                '''
            }
        }

        stage('Deploy to AKS') {
            when {
                anyOf {
                    branch 'main';
                }
            }
            steps {
                sh '''
                    echo ${BUILD_NUMBER}
                    source /etc/profile.d/proxy.sh
                    az account clear
                    az login --service-principal -username $AZ_SPN_USERNAME_PROD -password $AZ_SPN_PWD_PROD --tenant $AZ_TENANT_ID
                    az account set --subscription "f91f2bd7-c90a-4b12-93cb-289573253eed"
                    az aks get-credentials --resource-group fiquantit-prod-rg --name fiquantit-prod-aks
                    make deploy_aks
                    
                    # Wait for deployment and verify health
                    sleep 60
                    kubectl exec -it ${RELEASE_NAME}-0 -- /usr/local/bin/health-check.sh
                '''
            }
        }

        stage('Post-Deployment Verification') {
            when {
                anyOf {
                    branch 'main';
                }
            }
            steps {
                sh '''
                    # Initialize default topics
                    kubectl exec -it ${RELEASE_NAME}-0 -- /usr/local/bin/init-topics.sh
                    
                    # Run monitoring check
                    kubectl exec -it ${RELEASE_NAME}-0 -- /usr/local/bin/monitoring.sh
                '''
            }
        }
    }

    post {
        always {
            emailext body: """
                Build Status: ${currentBuild.currentResult}
                Job: ${JOB_NAME}
                Build Number: ${BUILD_NUMBER}
                
                Check console output at: ${BUILD_URL}
                
                Build Log:
                ${currentBuild.rawBuild.getLog(100).join('\n')}
            """,
            subject: "Jenkins Build ${currentBuild.currentResult}: ${JOB_NAME} #${BUILD_NUMBER}",
            to: "your.email@example.com"
        }
        success {
            sh '''
                # Cleanup old backups on success
                kubectl exec -it ${RELEASE_NAME}-0 -- /usr/local/bin/cleanup.sh
            '''
        }
        failure {
            sh '''
                # Create backup on failure
                kubectl exec -it ${RELEASE_NAME}-0 -- /usr/local/bin/backup.sh
            '''
        }
    }
}