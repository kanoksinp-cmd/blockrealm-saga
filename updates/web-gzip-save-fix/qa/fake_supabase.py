import http.server,json,sys
MODE=sys.argv[1]
slot={"player_name":"Test","job":"Rune Knight","job_id":"swordsman","base_level":50,"zeny":79275,"save_point":[1,0.1,2],
      "inventory":[], "stats":"broken", "appearance":None, "hotbar":{"x":1}}   # wrong types + many keys missing
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self,*a):pass
    def do_POST(self):
        n=int(self.headers.get('Content-Length',0));self.rfile.read(n)
        if self.path.endswith('game_whoami'):b={"ok":True,"user":{"id":"11111111-2222-3333-4444-555555555555","username":"guide"}}
        elif self.path.endswith('game_read_save'):
            b=None if MODE=='norow' else {"ok":True,"revision":7,"payload":{"schema":1,"slots":[slot,None,None,None,None],"last_slot":0}}
        else:b={"ok":True,"revision":8}
        code=200
        if MODE=='http500' and self.path.endswith('game_read_save'):code=500;b={"code":"42883","message":"function extensions.digest(text, unknown) does not exist","hint":None}
        if MODE=='text' and self.path.endswith('game_read_save'):b="oops"
        d=json.dumps(b).encode();self.send_response(code);self.send_header('Content-Type','application/json');self.send_header('Content-Length',str(len(d)))
        if MODE=='gzipheader' and self.path.endswith('game_read_save'):self.send_header('Content-Encoding','gzip')  # body already decoded, like a browser fetch
        self.end_headers();self.wfile.write(d)
http.server.HTTPServer(('127.0.0.1',8099),H).serve_forever()
