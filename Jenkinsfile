
// we need a node with docker available
node('docker') {

    // set unique image name ... including BUILD_NUMBER to support parallel builds
    def basename = 'hub.bccvl.org.au/bccvl/visualiser'
    def imgversion = env.BUILD_NUMBER
    // variable to hold docker image object
    def img = null
    // variable to hold visualiser version
    def version = null

    def pip_pre = "True"
    def PYPI_INDEX_CRED = 'pypi_index_url_dev'
    if (params.stage == 'prod') {
        // no pre releases allowed for prod build
        pip_pre = "False"
        PYPI_INDEX_CRED = 'pypi_index_url_prod'
    }

    try {
        // fetch source
        stage('Checkout') {

            checkout scm

        }

        // build image
        stage('Build') {

            // getRequirements from last BCCVL Visualiser 'release' branch build
            if (params.stage == 'prod') {
                getRequirements('BCCVL_Visualiser_tags')
            } else {
                getRequirements('BCCVL_Visualiser/master')
            }

            withCredentials([string(credentialsId: PYPI_INDEX_CRED, variable: 'PYPI_INDEX_URL')]) {
                docker.withRegistry('https://hub.bccvl.org.au', 'hub.bccvl.org.au') {
                    img = docker.build("${basename}:${imgversion}",
                                       "--rm --pull --no-cache --build-arg PIP_INDEX_URL=${PYPI_INDEX_URL} --build-arg PIP_PRE=${pip_pre} . ")
                }
            }

            // get version:
            img.inside() {
                version = sh(script: 'python -c  \'import pkg_resources; print pkg_resources.get_distribution("BCCVL_Visualiser").version\'',
                             returnStdout: true).trim()
            }
            // now we know the version ... re-tag and delete old tag
            imgversion = version.replaceAll('\\+','_') + '-' + env.BUILD_NUMBER
            img = reTagImage(img, basename, imgversion)
        }

        // test image
        stage('Test') {

            // run unit tests inside built image
            withCredentials([string(credentialsId: PYPI_INDEX_CRED, variable: 'PYPI_INDEX_URL')]) {
                img.inside("-u root --env PIP_INDEX_URL=${PYPI_INDEX_URL}") {
                    withEnv(['PYTHONWARNINGS=ignore:Unverified HTTPS request']) {
                        // install test dependies
                        // TODO: would be better to use some requirements file to pin versions
                        sh "pip install BCCVL_Visualiser[test]==${version} pytest"
                        // link ini file to test directory
                        sh "ln -s /etc/opt/visualiser/visualiser.ini ./development.ini"
                        // run tests
                        sh "pytest --pyarg bccvl_visualiser"
                    }
                }
            }

            // test if new conatiner starts correctly
            img.withRun() { visualiser ->
                // visualiser ... our container to test
                def address = sh(script: "docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${visualiser.id}",
                                 returnStdout: true).trim()

                // use some image to run tests ... e.g. robot, newly built, base from freshly built image etc...
                // run tests inside base against visualiser?
                img.inside("--add-host=visualiser:${address}") {
                    // clone our source repo with tests from right revision?
                    sh 'curl --fail --silent --show-error --retry 5 --retry-delay 1 http://visualiser:10600/api >/dev/null'
                    // TODO: run some test suite here?
                }

            }

            // check if tests ran fine
            if (currentBuild.result != null && currentBuild.result != 'SUCCESS') {
                // failed
            }
        }

        // publish image to registry
        stage('Publish') {

            if (currentBuild.result == null || currentBuild.result == 'SUCCESS') {
                // success
                docker.withRegistry('https://hub.bccvl.org.au', 'hub.bccvl.org.au') {
                    img.push()
                }

                slackSend color: 'good', message: "New Image ${img.id}\n${env.JOB_URL}"

            }

        }
    }
    catch (err) {
        echo "Running catch"
        throw err
    }
    finally {
        stage('Cleanup') {
            // clean up image
            sh "docker rmi ${img.id}"
        }
    }
}
