This script will take or remove snapshots from groups of machines with the same tag. It can be useful in scenarios where you will
be doing updates to a large number of machines in a single motion and want to quickly snapshot or remove a snapshot.

Notes:

Snapshots will be provided a specific name to avoid confusion with other snapshots as well as to easily remove the correct snapshot.  
This name will start with "VMSM-" and end with the category/tag used.  For example - snapshots taken for the category Patching and Dev tag will be called:

    VMSM-Patching/Dev

Disclaimer:  This script was obtained from https://github.com/cybersylum
  * You are free to use or modify this code for your own purposes.
  * No warranty or support for this code is provided or implied.  
  * Use this at your own risk.  
  * Testing is highly recommended.