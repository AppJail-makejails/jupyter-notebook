import os
import shlex
import sys

command = []

command.append("jupyter")

jupyter_command = os.environ.get("JUPYTER_CMD", "lab")
command.append(jupyter_command)

if "JUPYTER_ARGS" in os.environ:
    command += shlex.split(os.environ["JUPYTER_ARGS"])
else:
    command += ["--ip=0.0.0.0", "--port=8888"]

command += sys.argv[1:]

print("Executing:", " ".join(command))
os.execvp(command[0], command)
