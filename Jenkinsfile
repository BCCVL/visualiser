
// we need a node with docker available
node('docker') {

    // set unique image name ... including BUILD_NUMBER to support parallel builds
    def basename = 'hub.bccvl.org.au/bccvl/visualiser'
    def imgversion = env.BUILD_NUMBER
    def imgname = basename + ':' + imgversion
    def img = null

    def INDEX_HOST = env.PIP_INDEX_HOST
    def INDEX_URL = "http://${INDEX_HOST}:3141/bccvl/dev/+simple/"

    try {
        // fetch source
        stage('Checkout') {

            checkout scm

        }

        // build image
        stage('Build') {

            // get_requirements from last BCCVL Visualiser 'release' branch build
            get_requirements('BCCVL Visualiser/develop')

            // TODO: determine dev or release build (changes pip options)
            img = docker.build(imgname, "--rm --pull --no-cache --build-arg PIP_INDEX_URL=${INDEX_URL} --build-arg PIP_TRUSTED_HOST=${INDEX_HOST} . ")

            // get version:
            img.inside() {
                version = sh(script: 'python -c  \'import pkg_resources; print pkg_resources.get_distribution("BCCVL_Visualiser").version\'',
                             returnStdout: true).trim()
            }
            // now we know the version ... re-tag and delete old tag
            imgversion = version.replaceAll('\\+','_') + '-' + env.BUILD_NUMBER
            img.tag(imgversion)
            // clear temporary image tag
            sh "docker rmi ${imgname}"
            // set new imagename including correct version
            imgname = basename + ':' + imgversion
            // re init img object with correct name
            img = docker.image(imgname)
        }

        // test image
        stage('Test') {

            // run unit tests inside built image
            img.inside("-u root --env PIP_INDEX_URL=${INDEX_URL} --env PIP_TRUSTED_HOST=${INDEX_HOST}") {
                withEnv(['PYTHONWARNINGS=ignore:Unverified HTTPS request']) {
                    // get install location
                    def testdir=sh(script: 'python -c \'import os.path, bccvl_visualiser; print os.path.dirname(bccvl_visualiser.__file__)\'',
                                   returnStdout: true).trim()
                    // install test dependies
                    // TODO: would be better to use some requirements file to pin versions
                    sh "pip install BCCVL_Visualiser[test]==${version}"
                    // link ini file to test directory
                    sh "ln -s /etc/opt/visualiser/visualiser.ini ${testdir}/development.ini"
                    // run tests
                    sh "nosetests -w ${testdir}"
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

                echo "Would push ${img.id}"
                //img.push()
                // notify team
                //slackSend color: 'good', message: "New Image ${img.id}\n${env.JOB_URL}"

                // TODO: decide if we want latest tag as well?
                if (version.contains('.dev')) {
                    echo "Would push latest ${img.id}"
                    // img.push('latest')
                    // notify team
                    //slackSend color: 'good', message: "New Image ${img.id}:latest\n${env.JOB_URL}"
                }

            }

        }
    }
    catch (err) {
        echo "Running catch"
        throw error
    }
    finally {
        stage('Cleanup') {
            // clean up image
            sh "docker rmi ${img.id}"
            if (version.contains('.dev')) {
                echo "Also clean up latest tag ${img.id}"
            }
        }
    }
}


def get_requirements(project, target='./') {

    step([
        $class: 'CopyArtifact',
        filter: 'requirements.txt',
        target: target,
        projectName: project,
        fingerprintArtifacts: true,
        // parameters ... allows to filter upstream projects based on parameters?
        // parameters: 'BRANCH_NAME=master'
        // selector to pick last successful build
        //selector: [$class: 'StatusBuildSelector', stable: true]
        // selector to pick build that triggered this build
        selector: [
            $class: 'TriggeredBuildSelector',
            allowUpstreamDependencies: false,
            fallbackToLastSuccessful: true,
            upstreamFilterStrategy: 'UseNewest'
        ]
    ])

}


