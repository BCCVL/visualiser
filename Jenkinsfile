
// we need a node with docker available
node('docker') {

    def imagename = 'hub.bccvl.org.au/bccvl/visualiser'
    def img = null
    def version = 'latest'

    def INDEX_HOST = '172.17.0.1'
    def INDEX_URL = "http://${INDEX_HOST}:3141/bccvl/dev/+simple/"

    try {
        // fetch source
        stage('Checkout') {

            checkout scm

        }

        // build image
        stage('Build') {

            // TODO: get requirements file from build that triggered this build....
            // TODO: get pypi config to fetch artifcats from
            // TODO: determine dev or release build (changes pip options)
            // TODO: install development config, which can be overridden for prod deployment
            img = docker.build(imagename, "--pull --no-cache --build-arg PIP_INDEX_URL=${INDEX_URL} --build-arg PIP_TRUSTED_HOST=${INDEX_HOST} . ")

            // get version:
            img.inside() {
                version = sh(script: "python -c  'import pkg_resources; print pkg_resources.get_distribution(\'BCCVL_Visualiser\').version'",
                             returnStdout: true).trim()
            }

        }

        // test image
        stage('Test') {

            img.withRun() { visualiser ->
                // visualiser ... our container to test

                // use some image to run tests ... e.g. robot, newly built, base from freshly built image etc...
                def baseimage = 'hub.bccvl.org.au/bccvl/visualiserbase:2017-02-01'
                def base = docker.image(baseimage);
                // pull base image
                base.pull()
                // run tests inside base against visualiser?
                base.inside("--link=${visualiser.id}:visualiser") {
                    // clone our source repo with tests from right revision?
                    git 'https://github.com/bccvl/BCCVL_Visualiser'
                    // run test suite? ... visualiser is accessible at http://visualiser:10600/
                    sh '......'
                }

            }

            // check if tests ran fine
            if (currentBuild.result != null && currentBuild.result != 'SUCCESS') {
                // failed
            }
        }

        // publish image to registry
        stage('Publish') {

            if (currentBuld.result == null || currentBuild.result == 'SUCCESS') {
                // success
                // TODO: do I need to untag :latest?
                img.tag(imagename + ':' + version)
                // TODO: see above... would this push :latest and current tag?
                img.push()
                // notify team
                slackSend color: 'good', message: "New Image ${imagename}:${version}\n${env.JOB_URL}"
            }

        }
    }
    catch {

    }
}
