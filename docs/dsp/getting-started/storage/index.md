# Introduction to storage

Storage is used to refer to functionality to store or persist (for some amount of
time) information in various forms.

It's common practice to refer to different kinds of storage services:

- [block storage](#block-storage)
- [object storage](#object-storage)
- [file storage](#file-storage)

## Block storage

Block storage refers to where storage is offered as a larger area (block) of
data that can be used. One example of this is a hard drive or USB stick which
when plugged in will make its storage available as one area.

For cloud environments, block storage is typically offered through some form
of volume which can be thought of as a virtual hard disk that can be connected
(attached) to virtual machines. While these are typically provided over a
network, they normally show up as some form of local device in the virtual
machine where they are attached.

As hard disks are seldom connected to multiple computers, most uses assume they
have full control of the device and so is also the case for block storage,
meaning it can normally not be connected to more than one machine at the same
time.

Just like hard disks, block storage (volumes) typically need some form of
initialisation (formatting) to be usable.

## Object storage

Object storage (sometimes called blob storage) can be used from multiple points
simultaneously and doesn't require as tight connection between the place where
the data is used and the data is stored.

Object storage on DSP [is described in more detail here](object-store.md).

### Mounting

It's good to note that there exists many solution to expose an object store
as a file system. While this can be very practical, it can behave slightly
different from what would be expected from a file system (e.g. what happens
if files are renamed and so on).

## File storage

File storage is normally offered as a network file system. Like block storage,
this typically requires the place where data is stored and where the data is
used, but in contrast to block storage, file storage can normally be accessed
from multiple places simultaenously.

File service is not currently offered on DSP, but it's a planned feature.
