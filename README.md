A simple utility for uploading lots of files to Microsoft OneDrive.

Astute observers may realize that this is nigh-on-pointless, since anyone with a Windows computer (i.e. me, evidently, because I use .bat files for scripting) can just drag all of their files over to the OneDrive folder.

But I needed to back up some files off a Raspberry Pi NAS and felt like doing it the fancy way.

## Usage
First (after `pub get`), create an upload_state.json file by running

`pub run bin/main.dart plan --local-path <local directory to back up> --cloud-path <existing OneDrive directory to upload to>`

Then run

`pub run bin/main.dart execute`

The latter automatically saves its progress as necessary; if it is interrupted, it can be safely resumed simply by running it again.