# Releasing with Gradle process

## Prerequisites
1. Sonatype.org [JIRA](https://issues.sonatype.org/secure/Signup!default.jspa) account.
Your account needs to be added to the Knot.x project (if it isn't, please contact the Knot.x team
[Gitter Chat](https://gitter.im/Knotx/Lobby).

2. A GPG key generated for the email you have registered on the Sonatype.org JIRA
(Follow the [Working with PGP Signatures](http://central.sonatype.org/pages/working-with-pgp-signatures.html)
guide to get one). Make sure it is not expired. 
**Don't forget to deploy your public key to the key server!**

3. [Docker Hub](https://hub.docker.com/) account assigned to the Knot.x organization.
Generate [DockerHub access token](https://www.docker.com/blog/docker-hub-new-personal-access-tokens/).

4. Update your `gradle.properties` in order to be able to perform release

```
# Sonatype
ossrhUsername=<your-sonatype-org-jira-username>
ossrhPassword=<your-sonatype-org-jira-password>

# GPG key
signing.keyId=<key-id-here>
signing.password=<key-pass-here>>
signing.secretKeyRingFile=</Users/you/.gnupg/secring.gpg>

# DockerHub
dockerHubUsername=<your-dockerhub-username>
dockerHubPassword=<your-dockerhub-access-token>

# Fixed timeouts to successfully upload artifacts to the maven repository
org.gradle.internal.http.connectionTimeout=60000
org.gradle.internal.http.socketTimeout=300000
```


## Running the release

1. Run
    `./gradlew release -PreleaseVersion=2.0.0 -PnextVersion=2.1.0-SNAPSHOT -Pbranch=master`
    
    or to save results to log:
    
    `./gradlew release -PreleaseVersion=2.0.0 -PnextVersion=2.1.0-SNAPSHOT -Pbranch=master 2>&1 | tee ./release.log`
    
    That will run following phases in that order:
    - `prepare`
    - `publilsh`
    - `close`
    
    Properties:
    - `releaseVersion` - sets the desired release version,
    - `nextVersion` - sets the next development version (will be set at the `close` phase),
    - `branch` - the branch that will be used as a release base for all repos,
    - `dryRun` - if set to `true` nothing will be saved (all changes will be done only locally).

2. Promote manually artifacts to maven central repo using https://oss.sonatype.org/.

3. Do GitHub releases.

4. Publish release post.

For more details see [this issue](https://github.com/Knotx/knotx-aggregator/issues/19).

# ToDo
- automate releasing on GitHub
- make `dryRun` not pushing artifacts to DockerHub and Maven Central.

