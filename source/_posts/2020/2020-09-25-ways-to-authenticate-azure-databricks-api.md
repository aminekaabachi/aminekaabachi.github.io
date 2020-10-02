---
layout: post
title: Ways to authenticate Azure Databricks REST API
date: 2020-09-25 12:15:00+01:00
description: This article will give you insight on which authentification method to choose for your use-case and also give you a fast track to implementing it (backed by links to Microsoft docs for further details).
image:
  url: /assets/images/posts/auth-databricks/feature.png
  width: 1508
  height: 774
permalink: ways-to-authenticate-azure-databricks-api
tags:
  - databricks
  - azure
---

If you ever need to access the [Azure Databricks API](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/), you will wonder about the best way to authenticate. Depending on the use-case,  there are two ways to access the API: through personal access tokens or Azure AD tokens. Besides, there are also two methods for generating Azure AD tokens, either by impersonating a user or via a service principal. So which way to choose?

<div style="position:relative;padding-bottom:52.25%;">
  <img loading="lazy" style="max-width:100%; border: 0;position:absolute;top:0;left:0" sizes="(max-width: 768px) 100vw, 684px" src="/assets/images/posts/auth-databricks/feature.png" alt="">
</div>



This article will give you insight on which method to choose for your use-case and also give you a fast track to implementing SP based auth (backed by links to Microsoft docs for further details).

<!-- more -->
In fact, those methods provide users with many possibilities and enable several use-cases. However, it's also confusing to have multiple ways to authenticate to the API without giving clear guidelines. I will try to provide some basic rules to help you figure out the best solution for your case.

What to choose
-------------------

The first criteria to consider is automation: 
- If you need to fully automate API calls without having to ask anything from the user. The best solution is to use ***AD Tokens with a service principal***. General use-case is app to app communication.
- ***Impersonating users through AD Tokens*** is a semi-automatic solution where users still need a way to authenticate through Azure AD but the tokens are automatically generated. The best use-case, is an app that logins in through Azure AD and then uses the Databricks service on the user's behalf.
- The manual solution is to generate personal access tokens from the Databricks workspace. It is useful for dev tools and apps. You can also generate multiple tokens per user and revoke each individually.

The other criteria I can think of is Identity:
- ***Personal access tokens*** and ***Impersonating AD Tokens*** keep track of the user identity. Which is useful in the case of dev teams and interactive analytics workloads. This can also be helpful for audit trial as it enforces <abbr title="Least Privilege Principle">LPP</abbr>.
- ***SPs*** are generally anonymous. If you still need to keep Identity and use an SP, you will need to come up with more structure like giving each team an SP or something of a sort (but this is more like a hack).

Accessing the API using service principals
-------------------

### Create a service principal
The first thing is to create a service principal by navigating to `Azure Active Directory > App Registrations > New Registrations` and to generate a secret on `Certificates & secrets` on the portal. Refer to [this link](https://docs.microsoft.com/en-us/azure-stack/operator/azure-stack-create-service-principals?view=azs-2005#create-a-service-principal-that-uses-a-client-secret-credential) in you need more detailed steps. 

You can also generate it using az cli.

```powershell
$sp = New-AzADServicePrincipal -DisplayName DatabricksSP
```

The returned object contains the Secret member, which is a SecureString containing the generated password. Its value won't be displayed in the console output. However, the following code will allow you to export the secret:

```powershell
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sp.Secret)
$UnsecureSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
```

Now you have a `client-id` and `client-secret` to use.

### Generate a management token

For this you will need your SP credentials and also the Tenant ID.

You can generate the token using curl for example:

```curl
curl -X GET -H 'Content-Type: application/x-www-form-urlencoded' \
-d 'grant_type=client_credentials&client_id=%client-id%&resource=https://management.core.windows.net/&client_secret=%client-secret%' \
https://login.microsoftonline.com/<tenantid>/oauth2/token
```

The same thing can be achieved with this helper python function: 

```python
def get_management_token(tenant_id):
    base_url = 'https://login.microsoftonline.com/%s/oauth2/token' % tenant_id
    return requests.post(
        base_url,
        headers={"Content-type": "application/x-www-form-urlencoded"},
        data={
            "grant_type": "client_credentials",
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "resource": "https://management.core.windows.net/"
        }
    )
```

The `access_token` in the response is the management endpoint access token.


### Generate an access token 

We need to generate an access token with the AzureDatabricks login application as the resource. For this you will also need the SP credentials and Tenant ID. 

You can generate the token using curl for example:

```curl
curl -X GET -H 'Content-Type: application/x-www-form-urlencoded' \
-d 'grant_type=client_credentials&client_id=%client-id%&resource=2ff814a6-3304-4ab8-85cb-cd0e6f879c1d&client_secret=%client-secret%' \
https://login.microsoftonline.com/<tenant-id>/oauth2/token
```

The same thing can be achieved with this helper python function: 

```python
def get_access_token(tenant_id):
    base_url = 'https://login.microsoftonline.com/%s/oauth2/token' % tenant_id
    return requests.post(
        base_url,
        headers={"Content-type": "application/x-www-form-urlencoded"},
        data={
            "grant_type": "client_credentials",
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "resource": "2ff814a6-3304-4ab8-85cb-cd0e6f879c1d"
        }
    )
```

The `access_token` in the response is the Azure AD access token.

To note that Azure Databricks resource ID	is static value always equal to `2ff814a6-3304-4ab8-85cb-cd0e6f879c1d`.


### Calling the API

To showcase how to use the databricks API. I implemented  python wrapper for those operations:

```python
class DatabricksAPIInterface:
    def run_now_job(self, job_id):
        raise NotImplementedError()

    def get_run(self, run_id):
        raise NotImplementedError()

    def run_submit(self, json):
        raise NotImplementedError()

    def run_cancel(self, run_id):
        raise NotImplementedError()
```


To be able to call the API endpoints. You will need to provide a `X-Databricks-Azure-Workspace-Resource-Id` as header which will specify the workspace resource ID. It follows this template : `/subscriptions/%subscription-id%/resourceGroups/<resource-group-name>/providers/Microsoft.Databricks/workspaces/%workspace-name%`. You can also get it from the resources explorer.


```python

import requests

class DatabricksAPI(DatabricksAPIInterface):
    def __init__(self):
        self.host = "databricks_url"
        self.resource_id = "resource_id"
        self.base_url = 'https://%s/api/2.0' % (self.host)

        self.access_token = get_access_token().json().get('access_token')
        self.mgmt_token = get_management_token().json().get('access_token')


    def run_now_job(self, job_id):
        return requests.get(
            "%s/jobs/run-now" % self.base_url,
            headers={
                "Authorization": "Bearer %s" % self.access_token,
                "X-Databricks-Azure-SP-Management-Token": self.mgmt_token,
                "X-Databricks-Azure-Workspace-Resource-Id": self.resource_id,
                "Content-type": "application/json"
            },
            json={"job_id": job_id}
        )

    def get_run(self, run_id):
        job_result = '%s/jobs/runs/get?run_id=%s' % (self.base_url, run_id)
        return requests.get(
            job_result,
            headers={
                "Authorization": "Bearer %s" % self.access_token,
                "X-Databricks-Azure-SP-Management-Token": self.mgmt_token,
                "X-Databricks-Azure-Workspace-Resource-Id": self.resource_id,
                "Content-type": "application/json"
            }
        )

    def run_submit(self, json):
        return requests.post(
            "%s/jobs/runs/submit" % self.base_url,
            headers={
                "Authorization": "Bearer %s" % self.access_token,
                "X-Databricks-Azure-SP-Management-Token": self.mgmt_token,
                "X-Databricks-Azure-Workspace-Resource-Id": self.resource_id,
                "Content-type": "application/json"
            },
            json=json
        )

    def run_cancel(self, run_id):
        return requests.post(
            "%s/jobs/runs/cancel" % self.base_url,
            headers={
                "Authorization": "Bearer %s" % self.access_token,
                "X-Databricks-Azure-SP-Management-Token": self.mgmt_token,
                "X-Databricks-Azure-Workspace-Resource-Id": self.resource_id,
                "Content-type": "application/json"
            },
            json={'run_id': run_id}
        )

```

Wrapping up
-------------------

In this article, I showcased some rules and patterns to help you choose which authentification method to access Azure Databricks API. I also showed a fast track on implementing an SP based authentification on admin mode, refer to [these docs](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/service-prin-aad-token#non-admin-user-login) for non-admin use cases. 

I hope this article was useful. Feel free to comment on Medium or to reach me if you need more help or to discuss specific use-cases.