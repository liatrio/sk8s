For setting up the Client VPN to be used to connect to the EKS cluster we can use pre-existing docs created by AWS. [Client VPN setup](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/cvpn-getting-started.html#cvpn-getting-started-certs)

Step 1: In the AWS Client VPN setup this step asks you to setup client/server certificates and keys. 

    - Within this there is a link to set this up using the OpenVPN easy-rsa utility using mutual authentication between client and server.[OpenVPN easy-rsa mutual authenitication](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/client-authentication.html#mutual)

- At `Step 7` of the instruction it prompts you to import client/server certificates and keys to ACM (AWS Management Console) via the AWS cli. 
    - If you want to import the certificates and keys you can use [Importing a certificate](https://docs.aws.amazon.com/acm/latest/userguide/import-certificate-api-cli.html) docs to run you through importing it through the console as well as the cli.

- Step 4-6: 
    - For these steps in the `Client VPN setup` you require a VPC that should be configured in the EKS setup. 
    - VPC should be set up within the terraform to build EKS ARC set up so ensure that is up and running before you proceed with these steps. 
    - Step 5 can be skipped since the authorization rule sets up a routing table to connect to the VPC CIDR in Step 4.


Once you have ran through all the steps in the Client VPN setup doc:
- You can now start testing connectivity using the brand new client VPN. 
- For this step we need to download and install the AWS Client VPN. 
- Here is the [document](https://aws.amazon.com/vpn/client-vpn-download/) to download the Client VPN.

- Next is to make a new profile using the AWS provided client:
- Here is the AWS [documentation](https://docs.aws.amazon.com/vpn/latest/clientvpn-user/connect-aws-client-vpn-connect.html) to setup a new profile using the vpn config file you made during the Client VPN setup for your supported OS.