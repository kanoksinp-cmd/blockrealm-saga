#!/usr/bin/env python3
"""Godot 4 (tokenizer v100/101) binary GDScript (.gdc) -> source text.

Line numbers and the indentation of each line are restored exactly from the
token line/column tables, so recompiling the output should give the same
tokens / lines.  Usage: gdc_decomp.py file.gdc > file.gd
"""
import struct, sys, zstandard, math

TOK = """EMPTY ANNOTATION IDENTIFIER LITERAL LESS LESS_EQUAL GREATER GREATER_EQUAL EQUAL_EQUAL BANG_EQUAL AND OR NOT
AMPERSAND_AMPERSAND PIPE_PIPE BANG AMPERSAND PIPE TILDE CARET LESS_LESS GREATER_GREATER PLUS MINUS STAR STAR_STAR SLASH
PERCENT EQUAL PLUS_EQUAL MINUS_EQUAL STAR_EQUAL STAR_STAR_EQUAL SLASH_EQUAL PERCENT_EQUAL LESS_LESS_EQUAL
GREATER_GREATER_EQUAL AMPERSAND_EQUAL PIPE_EQUAL CARET_EQUAL IF ELIF ELSE FOR WHILE BREAK CONTINUE PASS RETURN MATCH
WHEN AS ASSERT AWAIT BREAKPOINT CLASS CLASS_NAME CONST ENUM EXTENDS FUNC IN IS NAMESPACE PRELOAD SELF SIGNAL STATIC
SUPER TRAIT VAR VOID YIELD BRACKET_OPEN BRACKET_CLOSE BRACE_OPEN BRACE_CLOSE PARENTHESIS_OPEN PARENTHESIS_CLOSE COMMA
SEMICOLON PERIOD PERIOD_PERIOD PERIOD_PERIOD_PERIOD COLON DOLLAR FORWARD_ARROW UNDERSCORE NEWLINE INDENT DEDENT CONST_PI
CONST_TAU CONST_INF CONST_NAN VCS_CONFLICT_MARKER BACKTICK QUESTION_MARK ERROR EOF""".split()

SYM = {"LESS": "<", "LESS_EQUAL": "<=", "GREATER": ">", "GREATER_EQUAL": ">=", "EQUAL_EQUAL": "==", "BANG_EQUAL": "!=",
       "AND": "and", "OR": "or", "NOT": "not", "AMPERSAND_AMPERSAND": "&&", "PIPE_PIPE": "||", "BANG": "!",
       "AMPERSAND": "&", "PIPE": "|", "TILDE": "~", "CARET": "^", "LESS_LESS": "<<", "GREATER_GREATER": ">>",
       "PLUS": "+", "MINUS": "-", "STAR": "*", "STAR_STAR": "**", "SLASH": "/", "PERCENT": "%", "EQUAL": "=",
       "PLUS_EQUAL": "+=", "MINUS_EQUAL": "-=", "STAR_EQUAL": "*=", "STAR_STAR_EQUAL": "**=", "SLASH_EQUAL": "/=",
       "PERCENT_EQUAL": "%=", "LESS_LESS_EQUAL": "<<=", "GREATER_GREATER_EQUAL": ">>=", "AMPERSAND_EQUAL": "&=",
       "PIPE_EQUAL": "|=", "CARET_EQUAL": "^=", "BRACKET_OPEN": "[", "BRACKET_CLOSE": "]", "BRACE_OPEN": "{",
       "BRACE_CLOSE": "}", "PARENTHESIS_OPEN": "(", "PARENTHESIS_CLOSE": ")", "COMMA": ",", "SEMICOLON": ";",
       "PERIOD": ".", "PERIOD_PERIOD": "..", "PERIOD_PERIOD_PERIOD": "...", "COLON": ":", "DOLLAR": "$",
       "FORWARD_ARROW": "->", "UNDERSCORE": "_", "CONST_PI": "PI", "CONST_TAU": "TAU", "CONST_INF": "INF",
       "CONST_NAN": "NAN", "QUESTION_MARK": "?", "BACKTICK": "`"}
for k in ["IF", "ELIF", "ELSE", "FOR", "WHILE", "BREAK", "CONTINUE", "PASS", "RETURN", "MATCH", "WHEN", "AS", "ASSERT",
          "AWAIT", "BREAKPOINT", "CLASS", "CLASS_NAME", "CONST", "ENUM", "EXTENDS", "FUNC", "IN", "IS", "NAMESPACE",
          "PRELOAD", "SELF", "SIGNAL", "STATIC", "SUPER", "TRAIT", "VAR", "VOID", "YIELD"]:
    SYM[k] = k.lower()


def esc(s):
    out = []
    for ch in s:
        o = ord(ch)
        if ch == "\\": out.append("\\\\")
        elif ch == '"': out.append('\\"')
        elif ch == "\n": out.append("\\n")
        elif ch == "\t": out.append("\\t")
        elif ch == "\r": out.append("\\r")
        elif o < 32: out.append("\\u%04x" % o)
        else: out.append(ch)
    return '"' + "".join(out) + '"'


def fmt_float(v):
    if math.isinf(v): return "INF" if v > 0 else "-INF"
    if math.isnan(v): return "NAN"
    r = repr(v)
    if "e" in r or "E" in r:
        m, e = r.lower().split("e")
        if "." not in m: m += ".0"
        return m + "e" + e
    if "." not in r: r += ".0"
    return r


def decode_variant(b, off):
    hdr = struct.unpack_from("<I", b, off)[0]
    typ = hdr & 0xFFFF
    f64 = hdr & (1 << 16)
    p = off + 4
    if typ == 0: return "null", p
    if typ == 1:
        return ("true" if struct.unpack_from("<I", b, p)[0] else "false"), p + 4
    if typ == 2:
        if f64: return str(struct.unpack_from("<q", b, p)[0]), p + 8
        return str(struct.unpack_from("<i", b, p)[0]), p + 4
    if typ == 3:
        if f64: return fmt_float(struct.unpack_from("<d", b, p)[0]), p + 8
        return fmt_float(struct.unpack_from("<f", b, p)[0]), p + 4
    if typ in (4, 21, 22):   # String, StringName, NodePath (NodePath stored differently)
        if typ == 22:
            raise ValueError("NodePath literal")
        n = struct.unpack_from("<I", b, p)[0]
        s = b[p + 4:p + 4 + n].decode("utf-8")
        p = p + 4 + n
        p += (4 - n % 4) % 4
        return ("&" if typ == 21 else "") + esc(s), p
    raise ValueError("variant type %d at %d" % (typ, off))


def decompile(data):
    assert data[:4] == b"GDSC", data[:4]
    ver, size = struct.unpack_from("<II", data, 4)
    raw = zstandard.ZstdDecompressor().decompress(data[12:], max_output_size=size) if size else data[12:]
    ic, cc, lc, tc = struct.unpack_from("<4I", raw, 0)
    off = 16
    ids = []
    for _ in range(ic):
        n = struct.unpack_from("<I", raw, off)[0]; off += 4
        cs = [struct.unpack_from("<I", bytes(x ^ 0xb6 for x in raw[off + 4 * j:off + 4 * j + 4]))[0] for j in range(n)]
        off += 4 * n
        ids.append("".join(map(chr, cs)))
    consts = []
    for _ in range(cc):
        v, off = decode_variant(raw, off)
        consts.append(v)
    lines, cols = {}, {}
    for _ in range(lc):
        ti, ln = struct.unpack_from("<II", raw, off); off += 8; lines[ti] = ln
    for _ in range(lc):
        ti, co = struct.unpack_from("<II", raw, off); off += 8; cols[ti] = co
    toks = []
    for _ in range(tc):
        if raw[off] & 0x80:
            t = struct.unpack_from("<I", raw, off)[0]; off += 4
        else:
            t = raw[off]; off += 1
        ln = struct.unpack_from("<I", raw, off)[0]; off += 4
        typ = TOK[t & 0x7F]
        idx = t >> 8
        toks.append((typ, idx, ln))
    assert off == len(raw), (off, len(raw))

    out_lines = {}
    cur_line = None
    buf = []
    prev = None

    def flush():
        if cur_line is not None:
            out_lines[cur_line] = out_lines.get(cur_line, "") + "".join(buf)

    for i, (typ, idx, ln) in enumerate(toks):
        if i == 0 or i in lines:
            flush()
            buf = []
            cur_line = lines.get(i, ln)
            col = cols.get(i, 1)
            indent = "\t" * (col - 1)       # the tokenizer counts a tab as one column
            buf.append(indent)
            prev = None
        elif ln > cur_line:
            # continuation line (inside brackets or after a backslash)
            buf.append(" \\")
            flush()
            buf = [indent + "\t\t"]
            cur_line = ln
            prev = None
        if typ in ("IDENTIFIER", "ANNOTATION"): text = ids[idx]
        elif typ == "LITERAL": text = consts[idx]
        elif typ == "ERROR": text = consts[idx]
        else: text = SYM.get(typ, "")
        # spacing
        if prev is not None:
            no_space = (
                typ in ("PERIOD", "COMMA", "PARENTHESIS_CLOSE", "BRACKET_CLOSE", "COLON", "SEMICOLON")
                or prev in ("PERIOD", "PARENTHESIS_OPEN", "BRACKET_OPEN", "DOLLAR", "BRACE_OPEN_NS")
                or (typ in ("PARENTHESIS_OPEN", "BRACKET_OPEN") and prev in ("IDENTIFIER", "PARENTHESIS_CLOSE", "BRACKET_CLOSE", "PRELOAD", "SUPER", "SELF", "LITERAL", "ASSERT", "AWAIT_X"))
            )
            if typ == "COLON" and prev in ("ELSE",):
                no_space = True
            if not no_space:
                buf.append(" ")
        buf.append(text)
        prev = typ
    flush()
    if not out_lines:
        return ""
    last = max(out_lines)
    res = []
    for n in range(1, last + 1):
        res.append(out_lines.get(n, "").rstrip())
    return "\n".join(res) + "\n"


if __name__ == "__main__":
    sys.stdout.write(decompile(open(sys.argv[1], "rb").read()))
