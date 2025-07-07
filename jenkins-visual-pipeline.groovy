pipeline {
    agent any
    
    stages {
        stage('🎯 Checkout') {
            steps {
                echo '📥 Checking out source code...'
                script {
                    // Simulate git checkout
                    sleep(time: 2, unit: 'SECONDS')
                    echo '✅ Source code checked out successfully'
                }
            }
        }
        
        stage('🧪 Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        echo '🔬 Running unit tests...'
                        script {
                            sleep(time: 3, unit: 'SECONDS')
                            echo '✅ Unit tests passed: 45/45'
                        }
                    }
                }
                stage('Integration Tests') {
                    steps {
                        echo '🔗 Running integration tests...'
                        script {
                            sleep(time: 4, unit: 'SECONDS')
                            echo '✅ Integration tests passed: 12/12'
                        }
                    }
                }
            }
        }
        
        stage('🏗️ Build') {
            steps {
                echo '🔨 Building application...'
                script {
                    sleep(time: 5, unit: 'SECONDS')
                    echo '✅ Build completed successfully'
                    echo '📦 Docker image: microservice-demo:latest'
                }
            }
        }
        
        stage('��️ Security Scan') {
            steps {
                echo '🔍 Running security scans...'
                script {
                    sleep(time: 3, unit: 'SECONDS')
                    echo '✅ No vulnerabilities found'
                }
            }
        }
        
        stage('🚀 Deploy') {
            steps {
                echo '📡 Deploying to development...'
                script {
                    sleep(time: 4, unit: 'SECONDS')
                    echo '✅ Deployed successfully'
                    echo '🌐 Available at: http://localhost:8080'
                }
            }
        }
    }
    
    post {
        always {
            echo '📊 Pipeline completed!'
            script {
                def duration = currentBuild.duration / 1000
                echo "⏱️ Total duration: ${duration} seconds"
            }
        }
        success {
            echo '🎉 Pipeline succeeded!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}
