A simple utility for uploading lots of files to Microsoft OneDrive.

Astute observers may realize that this is nigh-on-pointless, since anyone with a Windows computer (i.e. me, evidently, because I use .bat files for scripting) can just drag all of their files over to the OneDrive folder.

But I needed to back up some files off a Raspberry Pi NAS and felt like doing it the fancy way.

Update: It worked for a few hours, then had a conniption fit. There was apparently an "unhandled exception," though it told me nothing about said exception, and upload_state.json was left completely empty for some reason. Ended up going and grabbing the hard drive to drag and drop with anyway. 0/10, do not recommend.

## Usage
First (after `pub get`), create an upload_state.json file by running

`pub run bin/main.dart plan --local-path <local directory to back up> --cloud-path <existing OneDrive directory to upload to>`

Then run

`pub run bin/main.dart execute`

The latter automatically saves its progress as necessary; if it is interrupted, it can be safely resumed simply by running it again.
