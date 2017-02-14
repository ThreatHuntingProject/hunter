#!/usr/bin/env python
from __future__ import print_function

from IPython.lib import passwd
import os

if os.environ['JUPYTER_NB_PASS']:
    password = passwd(os.environ['JUPYTER_NB_PASS'])

    print("\n\n# Set the default password for the notebook")
    print("c.NotebookApp.password = u'%s'" % password)
    print("\n\n")
