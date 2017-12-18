# Openshift 

Demonstrates the use of Conjur in Openshift Origin (v 2.7) for machine identity and secrets delivery.
 

Prerequisites:
- CentOS Linux release 7.x > 
- Python 2.7.x 
- Internet connection
- root shell
- Conjur appliance tarball 4.9.x put under conjur-appliance/ directory

# Install other prerequisites
- Change directory to pre-reqs (cd pre-reqs).
- 1_install-docker.sh download packages from internet, install and configure docker on host.
- 2_install-openshift.sh download oc client tools packages from internet, install and configure Openshift Origin cluster on host.
- 3_install-conjur-cli.sh download packages from internet, install and configure Conjur CLI on host.


# Demo scenario 

- 0_demo.sh up - Setup the Openshift cluster, create the `conjur` Openshift project and setup the conjur appliance in Openshift. 
	> Login Openshift console as developer and show the deployed Conjur appliance pod.
	> Login to Conjur as admin and show interface.
- 1_deploy_app.sh - Deploy insults sample JEE Database and Applciation layers.
	> Navigate to insults application pod and show that is getting database credentials from env variables set in Openshift.
	> Naviagte to application url (http://insults-conjur.127.0.0.1.nip.io/) and show that application is running correctly. Each refresh lead to new funny insult generated.   
- 2_load_policy.sh - Load users and hosts policies and database secrets to Conjur.
	> Navigate to policies directory and explain sample policy set. Explain RBAC model and extend explanation to env segregation such staging and production. 
	> Login to Conjur appliance as "jam" user to illustrate the RBAC model.
- 3_deploy_app_with_conjur.sh - Redeploy the insults application using pod "conjurization" through Conjur variables.
	> Navigate to insults application pod and show that env variables are now set to temp HF token and Conjur variables. 
	> Login to Conjur appliance as "jam" user and navigate to hosts and show the new enrolled pod. Show audits. 
	> Explain how the temporarity of HF token is reducing risks. Illustrate it by adding new pod to insults application from Openshift console. Remove old one and once old pod terminated, show that new pod is unable to connect database by refreshing application URL in your navigator (HF token expiration).
	> Run 3_deploy_app_with_conjur.sh again. A new HF Token will be generated and new pods will be able to access DB variables by refreshing application URL in your navigator (wait until old instance is terminated). Explain the trust chain model. 
- 1_deploy_app.sh clean - Clean insults application without shutting down the Openshift cluster.
- 0_demo.sh down - Shutdown and clean the Openshift cluster.
