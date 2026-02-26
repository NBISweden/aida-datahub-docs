# Important information

## VM States Overview

A brief intro to VM status.

!!! Note
    Charges applies to VMs that are Active, Running, Suspended, Paused, Shut off. Charges will not
    be applied unless VM is deleted or shelved.

**Running**

VM is running and resources are actively used.

**Paused**

This request stores the state of the VM in RAM. A paused server continues to run in a frozen state.

Unpause returns a paused server back to an active state.

**Suspended**

Users might want to suspend a server if it is infrequently used or to perform system maintenance. When you suspend a server, its VM state is stored on disk, all memory is written to disk, and the virtual machine is stopped. Suspending a server is similar to placing a device in hibernation and its occupied resource will not be freed but rather kept for when the server is resumed.

**Shelved**

Shelving a server indicates it will not be needed for some time and may be temporarily removed from the hypervisors. This allows its resources to be freed up for use by someone else.

**Deleted**

The instance is permanently removed from the environment. Associated compute resources are released.
