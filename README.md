# Working with Knot.x 1.X

## Development
1. Clone the repo and checkout `1.x` branch.
2. Run `setup.sh` to download repositories.
3. Run `build.sh` to build all repos.

### Save changes
Make sure all repositories you have changes in can be altered (e.g. they are not archived).

Run `save.sh` script with `-m "Commit message"` and `-p` flags to commit and push all changes in repositories. E.g.

```
./save.sh -m "Upgrade vertx to 3.7.1" -p
```

## Releasing

### Prerequisites
1. Sonatype.org [JIRA](https://issues.sonatype.org/secure/Signup!default.jspa) account
2. Your Sonatype.org account needs to be added to the Knot.x project.
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

6. Update your `gradle.properties` with
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
7. On MacOS install [Mac OSX/Gsed](http://gridlab-d.shoutwiki.com/wiki/Mac_OSX/Gsed)

### Steps
1. Make sure you have all repositories up-to date with the branch you want to release.
2. Set `RELEASE_VERSION` in `release.sh`.
3. Run `./release.sh`.
4. Validate release on staging repos at https://oss.sonatype.org/.
5. Promote packages to maven central.
