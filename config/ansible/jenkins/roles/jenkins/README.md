Ansible Role for Jenkins
========================

Installs and completely configures Jenkins using Ansible.

This role is used when you want all your Jenkins configuration
in version control so you can deploy Jenkins repeatably
and reliably and you can treat your Jenkins as a [Cow instead
of a Pet](https://blog.engineyard.com/2014/pets-vs-cattle).

If you are looking for a role to install Jenkins and you
want to configure everything through the web interface and you
don't care about being able to repeatably deploy this
same fully-configured Jenkins then you don't need
this role, have a look at the
[geerlingguy/ansible-role-jenkins](https://github.com/geerlingguy/ansible-role-jenkins)
role instead.

Requirements
------------

Requires curl to be installed on the server.

If deploying using Docker then you need Docker
installed on the server.

(Docker, apt-get and yum are the only supported ways at the moment
although more ways can easily be added, PRs welcome).


Role Variables
--------------

see defaults/main.yml file.


Example Playbook
----------------

see jenkins-deploy.yml playbook file


HTTPS
-----

If you want to enable HTTPS on jenkins we recommend that you use a
reverse proxy like [jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy)
or [traefik](https://github.com/containous/traefik) and configure it
as the HTTPS endpoint instead of configuring jenkins itself with HTTPS.
This gives you more flexibility and better separation of concerns. See
the documentation in those projects for more details on how to deploy
the proxies and configure HTTPS.

If using a reverse proxy in front of the jenkins
instance and deploying using docker you probably
want to set the `jenkins_docker_expose_port` var to false so that the
port is not exposed on the host, only to the reverse proxy.


Jenkins Configs
---------------

The example above will look for the job configs in
`{{ playbook_dir }}/jenkins-configs/jobs/name-of-the-provided-job/config.xml` 

***NOTE***: This directory is customizable, see the `jenkins_source_dir_configs` and `jenkins_source_dir_jobs` role variables.

The role will also look for `{{ playbook_dir }}/jenkins-configs/config.xml`
These config.xml will be templated over to the server to be used as the job configuration.
It will upload the whole secrets directory under `{{ playbook_dir }}/jenkins-configs/secrets` and configure custom files provided under `{{ jenkins_custom_files }}` variable. Note that `{{ jenkins_include_secrets }}` and `{{ jenkins_include_custom_files }}` variables should be set to true for these to work.
Additionally the role can install custom plugins by providing the .jpi or .hpi files as a list under `{{ jenkins_custom_plugins }}` variable.

config.xml and custom files are templated so you can put variables in them,
for example it would be a good idea to encrypt sensitive variables
in ansible vault.

Example Job Configs
-------------------

Here's an example of what you could put in `{{ playbook_dir }}/jenkins-configs/jobs/name-of-the-provided-job/config.xml`:

see jenkins-configs/jobs/spree-project/config.xml file

Example Jenkins Configs
-----------------------

In `{{ jenkins_source_dir_configs }}/config.xml` you put your global
Jenkins configuration, for example:

see jenkins-configs/config.xml.j2 file

Making Changes
--------------

When you want to make a big change in a configuration file
or you want to add a new job the normal workflow is to make
the change in the Jenkins UI
first, then copy the resulting XML back into your VCS.

License
-------

MIT

Author Information
------------------

Made with love by Emmet O'Grady.
Changes made to allow ec2 plugin configuration, installation of several addition plugins and their configurations + store credentials by Hila F

Emmet O'Grady is the founder of [NimbleCI](https://nimbleci.com) which
builds Docker containers for feature branch workflow projects in Github.