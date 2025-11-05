# Data sharing requests - Decider guide

This is a guide of how to work withe REMS (Resource Entitlement Management System) as a decider.

Once a request for data sharing has been sent to REMS, a handler will review it. If the application looks good, the handler then sends it to the designated decider for that dataset which is where you come in.

The first thing you need to do as a decider is to login at <https://rems.dsp.aida.scilifelab.se/>

![REMS login screen](imgs/data-sharing-request/rems-login-screen.jpg)

REMS uses **Life Science Login** to handle authentication. If you don't already have a user at Life Science login, please follow [this guide](../dsp/getting-started/life-science-login.md).

## Approving applications as a Decider

As a decider, your task is to act as the formal approval of an application. Once you are logged in to REMS, you will have a section at the top called **Actions** which will show you all the open applications you are involved in.
![View of the Actions section as a decider, listing an applications for the decider to act on](imgs/data-sharing-handler/decider-actions.jpg)

You will see a list of applications where the _Action needed_ column has the text `Waiting for your decision`. These are the ones you should decide on. By clicking _View_ you are shown the application which will display all of its details, as well as the events at the top. If the handler has left any comments, you will see them in the events list. Events have an icon which indicates whether the applicant can see them, events between the handler and you as a decider are hidden from the applicant (they can't see your decision or comments you do).

On the right side, you can see a menu with _Actions_ you can take for the currently displayed application.

![View of a submitted application as a decider, showing events on the top](imgs/data-sharing-handler/decider-application-overview.jpg)

You make a decision on an application by using the `Decide` action. Here you can choose to `Approve` or `Reject` the application, if you reject the application please leave a comment in the text field for the handler detailing the reason.

![View of a submitted application, with the decide action in progress, showing buttons to cancel, reject or approve](imgs/data-sharing-handler/decider-application-decide.jpg)

Once all you have reviewed all application waiting for your decision, the _Actions_ section will be empty. You can look at previous applications under the _show more_ button under _Processed application_

![View of the Actions section after all applications has been decided on, listing no further applications](imgs/data-sharing-handler/decider-actions-empty.jpg)
