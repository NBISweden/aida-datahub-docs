# Download a dataset from AIDA Nextcloud using rclone

## Step 1 - Setup a remote

```bash
rclone config create drsk webdav url=https://nextcloud.aida.scilifelab.se/public.php/webdav vendor=nextcloud user=<USERNAME> pass=<PASSWORD>
```

Alternatively set vendor to other, if the above command is failing when set to nextcloud.

```bash
rclone config create drsk webdav url=https://nextcloud.aida.scilifelab.se/public.php/webdav vendor=other user=<USERNAME> pass=<PASSWORD>
```

Here, we have chosen the name `drsk` for the remote. You can of course choose
whatever name you want. Probably use something short that doesn't contain
spaces.

Your username is the last part of the share link you got from us, i.e:
`https://nextcloud.aida.scilifelab.se/s/USERNAME`

Your username could for example be something like `Y4gVyiVyyiF6fug`.

Your password is the string of random characters you got from us separately.
You will probably need to "quote" or 'quote' it on the command-line, as it very
likely contains special characters.

If you'd rather answer questions interactively, do this instead, and do what it
says:

```bash
rclone config`
```

The exact questions may differ depending on what version rclone you have.

## Step 2 - Download from the remote

Use the same name here that you chose in the previous step.

```bash
rclone copy drsk: .
```

Or if you want progress written to the terminal:

```bash
rclone copy --progress drsk: .
```
