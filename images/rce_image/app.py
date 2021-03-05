from flask import Flask, render_template
from flask import request
import subprocess
app = Flask(__name__)

basehtml = '''
<head><title>SNYKY ADMIN CONSOLE</title></head>
<body>
<h1>Hello, Admin. What command should I run?</h1>
<p>{cmd}</p>
<p>
<textarea rows="40" cols="80">{cmd_output}</textarea>
</p>
'''

@app.route("/")
def hello():
    try:
        cmd = request.args.get('cmd',)
        test = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
        output = test.communicate()[0].decode('ascii')
        return basehtml.format(cmd_output=output, cmd=cmd)
    except:
        return basehtml.format(cmd_output="", cmd="NONE")

if __name__ == "__main__":
    app.run(debug=True,host='0.0.0.0')
