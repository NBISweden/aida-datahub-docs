# Handling data sharing requests

This is a guide of how to process data sharing requests, both as a handler and as a decider. If you are a decider, you can go directly to the [decider](#approving-applications-as-a-decider) section.

Once a request for data sharing has been sent to REMS, a handler must review it. If the application looks good, the handler then sends it to the designated decider for that dataset.

If you as a handler or decider you must first login at <https://rems.dsp.aida.scilifelab.se/>

![REMS login screen](imgs/data-sharing-request/rems-login-screen.jpg)

To login to REMS, you need to authenticate using **Life Science Login**. If you don't already have a user at Life Science login, please follow [this guide](../dsp/getting-started/life-science-login.md).

## Handling requests

As a handler or decider, you will have the section **Actions** on the top of the window. Clicking it will present you will the following view:

![Display of the actions section, showing the applications for a handler to act on](imgs/data-sharing-handler/handler-actions.jpg)

Here you can see the open applications applications are awaiting actions. The _action needed_ column gives a brief overview of what needs to be done. Applications listed as _New application_ will need a handler to review it. Open the application by clicking **view**.

### The application view

You will be shown the application as filled in by the requester:

![View of a submitted application, showing a list of events for the application](imgs/data-sharing-handler/handler-application-overview.jpg)

At the top is a list of the events for this application. The events which the applicant sees has an open eye icon, while events hidden (such as requests for decision) are denoted by a crossed out eye. To the top right are the actions you as a handler can perform. The ones you will use are:

- Return to applicant...
- Request decision
- Approve or reject

The important parts of the application is at the bottom:

![View of submitted application, showing a form with details about the recipient scientist](imgs/data-sharing-handler/handler-application-details-review.jpg)

These lists the details the applicant has given about the recipient scientist and is what you as a handler will use to review the application.

### Reviewing the application

Most datasets requires us to establish that the recipient scientist is trained in handling sensitive data. As a way of proving this, we have put a requirement on the recipient scientist to hold at least a PhD in a relevant field (see [Legal explanation](#legal-explanation) for more details). As a handler you need to look at the fields filled in by the applicant, follow the credentials and make a conclusion that the recipient scientist have the required credentials.

- If you can't, follow the instructions under [Application is incomplete](#application-is-incomplete) below. 
- If everything looks good, instead follow the instructions under [Application is complete](#application-is-complete).

#### Application is incomplete

If you cannot with reasonable effort establish that the recipient scientist is competent to handle medical data, return the application (use the action **Return to applicant**) to the requester with the comment:

```text
Thank you for your interest in this dataset. We could not establish the identity of the recipient scientist with the given information. Please read https://docs.datahub.aida.scilifelab.se/data/data-sharing-request/#rejected-applications for further details. Please clarify the following:

- Name of recipient scientist,
- Recipient scientist e-mail for the workplace institution,
- Name and department of recipient scientist institution,
- Adress of institution,
- Details which demonstrate that the researcher has expertise in relevant field, such as ORCID, profile page at research institution
```

Remove any of bullet points which are clear and don't need further details.

![View of a submitted application, with the "Return to applicant" action initiated](imgs/data-sharing-handler/handler-application-return-application.jpg)

#### Application is complete

If the details of the recipient scientist looks correct and suitable, the next step is to send it to the decider. Use the **Request decision** action. Choose `from existing user...`:

![View of a submitted application, with the "Request decision" action highlighted](imgs/data-sharing-handler/handler-application-request-decision-1.jpg)

This gives you a menu where you can search for the decider:

![View of a submitted application, in the process of selecting deciders by choosing from a list of existing users](imgs/data-sharing-handler/handler-application-request-decision-2.jpg)

Add the necessary deciders to the list of deciders and choose `Request decision`. The application will now be waiting for decisions from the deciders.

## Approving applications as a Decider

As a decider, you approve an application. Once you are logged in to REMS, you will have a section at the top called **Actions** which will show you all the open applications you are involved in. There will be applications where the _Action needed_ column has the text `Waiting for your decision`. These are the ones you should review.

![View of the Actions section as a decider, listing an applications for the decider to act on](imgs/data-sharing-handler/decider-actions.jpg)

By clicking _View_ you are shown the application. This will display all details of the application, as well as the events at the top. If the handler has left any comments, you will see them in the event list. On the right side, you can see a menu with _Actions_ you can take for the currently displayed application.

![View of a submitted application as a decider, showing events on the top](imgs/data-sharing-handler/decider-application-overview.jpg)

You make a decision on an application by using the _Decide_ action. Here you can choose to approve or reject the application, if you reject the application please leave a comment for the handler.

![View of a submitted application, with the decide action in progress, showing buttons to cancel, reject or approve](imgs/data-sharing-handler/decider-application-decide.jpg)

Once all you have reviewed all application waiting for your decision, the _Actions_ section will be empty. You can look at previous applications under the _show more_ button under _Processed application_

![View of the Actions section after all applications has been decided on, listing no further applications](imgs/data-sharing-handler/decider-actions-empty.jpg)

## Finishing approval

Once all deciders have made their decisions on an application, it will be listed under the _Actions_ with the text `All requests have been responded to`.

![View of the Actions section showing that deciders has responded to an application](imgs/data-sharing-handler/handler-application-deciders-responded.jpg)

Once all deciders have responded, review the application again

![View of a submitted application showing approval events from deciders](imgs/data-sharing-handler/handler-application-deciders-responded-overview.jpg)

Under the _Events_, you can see what the decisions is. If all deciders approve the application, you should now finalize the approval. Before doing so, create the share link for downloading the dataset on NextCloud, then use the following text as a comment (replacing the link and password with the one created) with the approval:

```text
Thank you for your interest in this dataset. Your application has been approved and you can download the dataset from the following link:
[SHARE LINK]
Password to access the shared data is [SHARE PASSWORD]
This link is valid for 14 days.
```

![View of submitted application, after the approval action has been initiated by the handler with the comment field filled in](imgs/data-sharing-handler/handler-application-approve.jpg)

Once you've filled in these details, approve the applications and you're done!

## Legal explanation

As a policy, we require the recipient researcher to hold at least a PhD in a relevant field.
This requirement has to do with the legal framework under which the data can be shared.

This requirement is based on the legal framework governing data sharing.
According to Swedish law, clinical datasets can be shared only when used for research activities conducted under the supervision of a qualified researcher, someone with the necessary scientific competence to ensure that research is carried out as described in the ethical review application and in accordance with institutional policies.

For a more detailed discussion of the legal framework surrounding the sharing of clinical data in Sweden, please see the [Legal Discussion](https://datahub.aida.scilifelab.se/sharing/legal/) on the AIDA Data Hub.
