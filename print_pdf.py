import subprocess, json, sys, os, urllib.request, time, base64, websocket

chrome = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
html_file = sys.argv[1]
pdf_file = os.path.splitext(html_file)[0] + ".pdf"

proc = subprocess.Popen(
    [chrome, "--headless", "--disable-gpu", "--remote-debugging-port=9222", "--remote-allow-origins=*"],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
)

try:
    time.sleep(0.8)
    # get first page target
    resp = urllib.request.urlopen("http://localhost:9222/json")
    targets = json.loads(resp.read())
    ws_url = [t["webSocketDebuggerUrl"] for t in targets if t["type"] == "page"][0]

    ws = websocket.create_connection(ws_url, suppress_origin=True)
    mid = 1
    def send(cmd, params={}):
        global mid; mid += 1
        ws.send(json.dumps({"id": mid, "method": cmd, "params": params}, ensure_ascii=False))
        while True:
            r = json.loads(ws.recv())
            if "result" in r: return r["result"]

    send("Page.navigate", {"url": "file:///" + html_file.replace("\\", "/")})
    time.sleep(3)

    result = send("Page.printToPDF", {
        "paperWidth": 8.27,
        "paperHeight": 11.69,
        "marginTop": 0.3,
        "marginBottom": 0.3,
        "marginLeft": 0,
        "marginRight": 0,
        "displayHeaderFooter": False,
        "printBackground": True,
        "preferCSSPageSize": True
    })

    pdf_data = base64.b64decode(result["data"])
    with open(pdf_file, "wb") as f: f.write(pdf_data)
    print(f"OK: {pdf_file}")

finally:
    try: ws.close()
    except: pass
    proc.terminate(); proc.wait()
