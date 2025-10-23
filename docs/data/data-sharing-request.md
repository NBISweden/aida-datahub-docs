
# Requesting access to AIDA Data Hub dataset through REMS

Most datasets on AIDA Data Hub uses [REMS](https://github.com/CSCfi/rems), (Resource Entitlement Management System) to manage request and access to datasets. This system allows you to apply for access to datasets and for handlers to review your application. Before you request access to a dataset, you first need to login at <https://rems.dsp.aida.scilifelab.se/>

![REMS Login Screen](imgs/data-sharing-request/rems-login-screen.jpg)

To login to REMS, you need to authenticate using Life Science Login. If you don't already have a user at Life Science login, please follow [this guide](../dsp/getting-started/life-science-login.md).

## Using REMS

Once you have authenticated using Life Science login, you will be redirected back to REMS, you are greeted by the dataset catalogue:

![REMS Catalogue](imgs/data-sharing-request/rems-catalogue-items.jpg)

Here you can browse all available datasets and add them to a cart. Each application still needs to be done one at a time, but the cart allows you to make a list of datasets you would like to request access to before starting the application process. After you've added a dataset to the basket, you will have the option to apply for access:

![REMS dataset in basket](imgs/data-sharing-request/rems-added-to-basket.jpg)

### Applying for access

To apply for a dataset, click the `Apply` button. This will take you to the application form.

![REMS dataset application form](imgs/data-sharing-request/rems-application-form.jpg)

This form has multiple fields which needs to be filled in. All datasets have some form of agreement you need to accept. Often, these are in the form of PDF attachment which you need to download and review before accepting.

Many datasets also have mandatory fields you need to fill in which shows that the recipient researcher is competent to conduct ethical research using medical data, and details about the researcher needs to be filled out for us to lawfully share the data.

You can also find a set of **actions** which you can perform in the top right of the application form, these are:

- Save as draft: Save the current state of this application without sending it in. You can continue working on it at a later date.
- Send application: Send the application for processing. It will be in your list of applications.
- Delete draft: Delete the application, removing it from your list of applications.
- Copy as new application: Create a new application for the same dataset, with the same filled in items, e.g. for applying to the resource on behalf of another recipient scientist.
- Download PDF: Download a PDF version of the application.

Once you have filled in the the application, use the "Send application" action to send it for processing. A handler will manually review your application, and once that is done you will receive a decision. This is either approval or rejection. You will receive e-mail both when you apply and when the application has been processed to the e-mail you have registered with LifeScience Login.

#### Rejected applications

A rejection often means that the handler could not with *reasonable effort* make sure that the recipient researcher is competent to conduct ethical medical research. 
If your application is rejected due to insufficient information, when you make a new application please make sure that:

- The recipient researcher holds at least a PhD in a relevant field.
- The e-mail of the recipient researcher is clearly tied to the given institution.
- The profile page and other supporting links for the researcher clearly shows that the researcher is competent in conducting ethical medical research in a relevant field.

The clearer the credentials of the recipient researcher is (e.g. e-mail is obviously tied to the researchers institution, the researcher has a clearly informative profile page at that institution, the researcher has a publication record or position relevant to the field).

### The Application listing

You can see the status of your applications in REMS under the **Applications** menu:

![REMS list of applications](imgs/data-sharing-request/rems-list-applications.jpg)

You can continue working on you saved drafts as well as look at your submitted applications.

### Getting access to the datasets

If your request is approved, you will receive an email containing the details of how to download the datasets. The download link you receive is typically valid for 14 days. If you need a new share link please make a copy of your approved application and re-send it.

To make data downloading easier, see [this guide](download-dataset.md).