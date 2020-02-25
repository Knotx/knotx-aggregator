# Development process
This repository contains scripts that help to manage and develop Knot.x project and its GitHub repositories.
Below you will find instructions on how to setup local Knot.x developer's e environment and build:
- [Knot.x Stack](https://github.com/Knotx/knotx-stack) - a way of distributing a fully functional bootstrap project for Knot.x-based solutions.
- [Knot.x Docker Image](https://github.com/Knotx/knotx-docker) - which is a base image for Knot.x solutions using the Docker `FROM` directive.   
- [Knot.x Starter-Kit](https://github.com/Knotx/knotx-starter-kit) - a template project that you can use when creating Knot.x extensions. 

## Prerequisites
Before proceeding make sure you have installed:
- Java 8
- Gradle 5+
- Maven 3.2+
- (optionally) Your favourite IDE - we will use IntelliJ for the purpose of these instructions
- (optionally) Docker installed (if you intend to build Knot.x Docker images)

If you are a Windows user, please install and configure [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) (WSL).
Scripts in that repository are designed to be used on Linux-based platforms.

## Setup developer environment
Start with cloning this repository into your workspace. Let's call it `$KNOTX`.

### Clone all Knot.x repositories
From the `$KNOTX/knotx-aggregator/development` directory run:

```bash
./pull-all.sh -r ../../ -b master
```

This will pull all Knot.x repositories into `$KNOTX` root and checkout default `master` branch.
The `-r` option specifies the directory where all Knot.x repositories are cloned (which is `$KNOTX`).
Check `./pull-all.sh -h` option for help. 

> Note:
> Execute all scripts from `knotx-aggregator/development` directory, executing them from another 
directory will fail.

### Setup IDE
> This step is optional
 
Now as you have all repositories cloned (make sure by running `ls -al` form `$KNOTX`) you may setup your IDE.
The easiest way to do it is to enter `$KNOTX/knotx-stack` and run `idea .`. 
That will spawn IntelliJ prompt window that will ask you on project import details. After a couple of minutes (importing
all modules make take some time) you should end with configured Knot.x project.

> Note:
> `knotx-stack` repository contains [Gradle composite build](https://docs.gradle.org/current/userguide/composite_builds.html) definition.
> The repository allows you to re-build all Knot.x modules and use them during integration tests, bypassing the
  need to publish artifacts to the maven repository first.

### Build Stack
From the `$KNOTX/knotx-aggregator/development` directory run:

```bash
./build-stack.sh -r ../../
```
The `-r` option points to the directory where all Knot.x repositories were cloned (which is `$KNOTX`).
Check `-h` option for help. 

The `build-stack.sh` command deploys all Knot.x artifacts to the local Maven repository.

### Build Docker Image
To build [Knot.x Base Docker image](https://github.com/Knotx/knotx-docker) run `build-stack.sh` with `-i` (image) flag.

```bash
./build-stack.sh -r ../../ -i
```

After a successful build, you should have `knotx/knotx:X.X.X-SNAPSHOT` image in your local Docker images repository.
Check it running `docker images knotx/knotx` (note `X.X.X-SNAPSHOT` should correspond to the current SNAPSHOT version of Knot.x Stack).

### Build Starter-Kit
To build [Knot.x Starter-Kit](https://github.com/Knotx/knotx-starter-kit) run `build-stack.sh` with `-s` flag.

```bash
./build-stack.sh -r ../../ -s
```

There are 2 distributions that `Knot.x Starter-Kit` builds:
- `ZIP`,
- `Docker image`.

You can find more details in the [Starter Kit repository README](https://github.com/Knotx/knotx-starter-kit).
After [cloning all Knot.x repositories](#clone-all-knotx-repositories) you can find Starter Kit in the
`$KNOTX/knotx-starter-kit`. Navigate to this repository now and follow the instructions from the 
[Starter Kit repository README](https://github.com/Knotx/knotx-starter-kit) to build desired distributions.

> Note that you need to build [Docker Image](#build-docker-image) if you want to use Docker image distribution.
> Otherwise, building [Stack](#build-stack) is sufficient.

## Run Knot.x instance using Knot.x Stack
There is a detailed tutorial on how to run Knot.x instance using the Stack:
- http://knotx.io/tutorials/getting-started-with-knotx-stack
That base on the released Knot.x version. If you [have built the Stack](#build-stack) you may use the `SNAPSHOT` version instead.

## Use cases
> Note: after cloning the repository please make sure all bash files have proper permissions.
> If not, please run:

```
$>git clone git@github.com:Knotx/knotx-aggregator.git
$>chmod -R 755 knotx-aggregator/**/*.sh
```

### Checkout and build all repositories for a specific branch
> This option is useful if you are working on a cross-repository feature

From `knotx-aggregator/development` run:
```
$>./pull-all.sh -r ../../ -b feature/my-changes -m origin/master
$>./build-stack.sh -r projects/knotx
```

# Release process
This section describes release process.

## Prerequisites
1. Sonatype.org [JIRA](https://issues.sonatype.org/secure/Signup!default.jspa) account

2. Your Sonatype.org account needs to be added to the Knot.x project (if it isn't, please contact the Knot.x team
via [User Group](https://groups.google.com/forum/#!forum/knotx) or [Gitter Chat](https://gitter.im/Knotx/Lobby).

3. A GPG key generated for the email you have registered on the Sonatype.org JIRA
(Follow the [Working with PGP Signatures](http://central.sonatype.org/pages/working-with-pgp-signatures.html)
guide to get one).
**Don't forget to deploy your public key to the key server!**

4. Add a `<server>` entry to [your `settings.xml` file](https://maven.apache.org/settings.html#Introduction)
   ```xml
   <servers>
     ...
     <server>
       <id>ossrh</id>
       <username>your_sonatype_org_jira_username</username>
       <password>your_sonatype_org_jira_password</password>
     </server>
       ...
   </servers>    
   ```

5. Assuming you have created account on [Docker Hub](https://hub.docker.com/) and you're assigned to the Knot.x organization, add server entry to your `settings.xml` to enable pushing to the docker registry.
```xml
	<server>
		<id>registry.hub.docker.com</id>
		<username>[Username]</username>
		<password>[password]</password>
	</server>
```

6. Bintray account created (to release Knot.x binary distributions) and token generated.

7. Update your `gradle.properties` with
```
signing.keyId=24875D73
signing.password=secret
signing.secretKeyRingFile=/Users/me/.gnupg/secring.gpg
```
and
```
ossrhUsername=your_sonatype_org_jira_username
ossrhPassword=your_sonatype_org_jira_password
```
For releasing gradle repos.
Also add
```
org.gradle.internal.http.connectionTimeout=60000
org.gradle.internal.http.socketTimeout=300000
```
To fix the read timeouts gradle issue.

## Procedure
> Prerequisites
> Install [Mac OSX/Gsed](http://gridlab-d.shoutwiki.com/wiki/Mac_OSX/Gsed)

From the repository `release` directory execute following commands:

1. Clone repos. (It will do a shallow clone of all repos being a subject of the release procedure)
```bash
./clone.sh
```

2. Start release & provide the release version number
```bash
./start-release.sh 2.0.0
```

3. Validate release on staging repos

4. Release docker image:
```bash
./release-docker.sh
```

5. Close the release
Create manually new versions for `examples` and `distro` packages at bintray.
Run:
```bash
./close-release.sh 1.5.0 1.5.1-SNAPSHOT <bintrayUser> <bintrayToken>
```

6. Manual actions:
  - close and promote repos released by gradle manually at oss.sonatype.org
  - publish bintray files
  - update website - binary distro links
  - update wiki
  - publish release blog

## ToDo
- automatically close and promote repos released by gradle manually at oss.sonatype.org
- update `knotx-website`
  - binary distro links
  - `index` version
  - produce `blog/release-VERSION/` page that consists of all `CHANGELOG.md` changes for every module
  - deploy `SNAPSHOT` versions after release to make development of new versions possible and satisfy failing travis

# CI / CD
Knot.x uses [Azure Pipelines](https://dev.azure.com/knotx/Knotx/_build) to verify commits. Each
repository contains an `azure-pipelines.yml` configuration file that contains details about build and 
verification steps. Each time there is a change in `master` repository or some contributor starts 
the new PR then Azure job starts.

The `azure-pipelines.yml` file is the same across all repositories. So we use Aggregator to update 
it in all places. From the repository `azure` directory execute following commands:
```bash
./update.sh
```
to copy `./azure-pipelines.yml` to all repositories, commit and push. 