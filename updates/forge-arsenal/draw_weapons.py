from PIL import Image, ImageDraw, ImageColor
from pathlib import Path
import json

root = Path(__file__).parent
catalog = json.loads((root / 'arsenal.json').read_text(encoding='utf-8-sig'))
W,H=35,45

def profile(style):
    image=Image.new('L',(W,H),0)
    draw=ImageDraw.Draw(image)
    # Palette 1 outline, 2 shadow, 3 base, 4 highlight, 5 gem, 6 metal, 7 gold, 8 bone, 9 wrap.
    def poly(points, color): draw.polygon(points, fill=color)
    def rect(x0,y0,x1,y1,c): draw.rectangle((x0,y0,x1,y1),fill=c)
    def oval(x0,y0,x1,y1,c): draw.ellipse((x0,y0,x1,y1),fill=c)
    def edge(points, fill): draw.polygon(points,fill=fill,outline=1)
    def jewel(x,y,w,h):
        edge([(x,y-h),(x+w,y),(x,y+h),(x-w,y)],5)
        poly([(x,y-h+1),(x,y),(x-w+1,y)],4)
        poly([(x,y+1),(x+w-1,y),(x,y+h-1)],3)
    def skull(x,y):
        edge([(x-6,y-5),(x-3,y-8),(x+3,y-8),(x+6,y-5),(x+6,y+1),(x+3,y+3),(x+3,y+6),(x-3,y+6),(x-3,y+3),(x-6,y+1)],8)
        rect(x-4,y-3,x-1,y,1);rect(x+1,y-3,x+4,y,1)
        rect(x-3,y-2,x-2,y-1,5);rect(x+2,y-2,x+3,y-1,5)
        rect(x-1,y+2,x+1,y+2,2)
        for dx in [-2,0,2]:rect(x+dx,y+4,x+dx,y+5,2)
    def vine(points):
        draw.line(points, fill=2,width=4,joint='curve')
        draw.line(points, fill=5,width=2,joint='curve')
    def grip(top):
        edge([(14,top),(20,top),(20,40),(18,43),(15,43),(13,40)],9)
        for y in range(top+2,41,4):poly([(14,y),(19,y-1),(19,y),(14,y+1)],6)
        jewel(17,41,3,3)
    def guard(y):
        edge([(6,y-1),(10,y-4),(14,y-2),(17,y-5),(20,y-2),(24,y-4),(28,y-1),(25,y+3),(20,y+2),(17,y+4),(14,y+2),(9,y+3)],7)
        jewel(17,y,4,4)
    def blade(points):
        edge(points,3)
        inset = [(17,points[0][1]+3),(20,points[0][1]+11),(20,points[-2][1]-4),(17,points[-2][1]-1),(15,points[-2][1]-4),(15,points[0][1]+12)]
        poly(inset,2)
        poly([(17,points[0][1]+2),(17,points[-2][1]-3),(15,points[-2][1]-6),(14,points[0][1]+13)],4)
    grip(13 if style in ['solar','frost','gear','vine','dragon','spire'] else 28)
    if style=='solar':
        edge([(3,9),(6,6),(12,9),(22,9),(28,6),(31,9),(31,19),(27,22),(22,19),(12,19),(7,22),(3,19)],7)
        rect(6,9,8,18,4);rect(26,8,28,19,4);rect(13,10,21,19,3)
        jewel(17,14,7,8)
        for x in [6,28]:rect(x-1,14,x+1,15,2)
    elif style=='frost':
        edge([(2,12),(6,6),(12,3),(14,6),(20,5),(23,3),(29,6),(33,11),(31,17),(27,18),(24,24),(21,20),(18,25),(15,19),(10,20),(7,16),(3,18)],3)
        poly([(4,11),(10,5),(14,8),(11,10),(8,15)],4)
        poly([(20,7),(26,5),(30,8),(31,13),(25,11)],4)
        skull(17,13)
        for x in [7,25,29]:poly([(x-2,16),(x+2,17),(x,22)],8)
    elif style=='gear':
        for x,y in [(17,4),(25,6),(30,12),(29,19),(23,24),(14,24),(7,21),(4,14),(7,7)]:
            rect(x-2,y-2,x+2,y+2,7)
        oval(5,4,30,25,1);oval(7,6,28,23,3);oval(10,8,25,21,6);oval(12,9,23,20,2)
        poly([(19,8),(13,15),(17,15),(15,21),(22,13),(18,13)],5)
    elif style=='vine':
        edge([(3,7),(11,4),(19,5),(24,3),(30,7),(31,17),(26,21),(8,22),(3,17)],6)
        rect(6,9,15,11,3);rect(18,15,27,18,2);rect(20,6,26,9,8)
        jewel(24,12,4,5)
        vine([(8,8),(5,13),(10,19),(18,19),(18,15),(14,13),(10,14),(12,16)])
        vine([(18,20),(17,27),(20,31),(15,37),(17,41)])
        poly([(4,11),(2,6),(10,7)],5);poly([(8,19),(4,23),(12,22)],5)
    elif style=='dragon':
        edge([(3,13),(6,6),(13,5),(16,2),(19,6),(26,5),(31,8),(33,13),(29,16),(25,16),(24,18),(29,20),(25,23),(18,21),(14,24),(12,18),(7,17)],3)
        poly([(3,13),(7,6),(12,6),(9,12),(11,17),(8,17)],5)
        poly([(14,8),(17,5),(22,7),(28,7),(31,11),(25,12),(21,10),(18,13)],7)
        poly([(21,13),(30,13),(26,17),(23,16),(27,20),(22,19),(19,17)],1)
        poly([(25,13),(27,13),(26,16)],8);poly([(23,18),(23,16),(25,19)],8)
        rect(19,10,20,11,5)
    elif style=='spire':
        edge([(9,15),(10,9),(14,6),(17,1),(20,6),(25,8),(25,13),(29,17),(24,22),(19,21),(17,24),(14,21),(9,22),(5,17)],3)
        jewel(17,11,6,10)
        poly([(7,16),(13,16),(13,20),(9,20)],6);poly([(22,16),(27,16),(25,20),(21,20)],6)
        jewel(17,20,4,4)
    elif style=='lion':
        blade([(17,2),(22,9),(24,17),(22,27),(20,30),(14,30),(11,25),(11,15),(13,9)])
        jewel(17,18,3,6)
        guard(31)
        edge([(10,28),(13,25),(17,26),(21,25),(25,29),(24,34),(20,37),(15,37),(11,34)],7)
        poly([(13,28),(17,29),(21,28),(23,31),(19,35),(15,35),(12,31)],4)
        rect(14,30,16,30,5);rect(19,30,21,30,5);poly([(16,32),(20,32),(18,34)],1)
    elif style=='skull':
        edge([(7,4),(12,8),(15,16),(15,27),(11,31),(5,29),(3,20),(5,9)],3)
        edge([(27,4),(22,8),(19,16),(19,27),(23,31),(29,29),(31,20),(29,9)],3)
        poly([(7,5),(6,14),(5,21),(8,25),(8,12)],4)
        poly([(27,5),(28,14),(29,21),(26,25),(26,12)],4)
        guard(29);skull(17,29)
    elif style=='violet':
        edge([(17,3),(22,9),(24,16),(22,24),(27,28),(21,31),(14,31),(9,28),(13,23),(11,16),(13,9)],3)
        poly([(17,4),(17,21),(13,17),(14,9)],4)
        poly([(18,7),(23,16),(21,23),(18,27)],2)
        guard(29);skull(17,30)
    elif style=='grave':
        edge([(9,29),(7,22),(8,12),(12,6),(17,3),(22,6),(26,12),(27,22),(24,29),(20,34),(14,34)],3)
        draw.arc((9,5,25,28),185,355,fill=4,width=2)
        for x in [11,23]:rect(x,13,x+1,24,6)
        rect(15,12,19,13,4);rect(17,12,18,23,4)
        jewel(17,8,3,3)
        for x,y in [(7,28),(10,30),(14,31),(20,31),(24,30),(27,28)]:
            poly([(x-2,y+2),(x,y-4),(x+2,y+2)],5)
        jewel(17,35,3,3)
    elif style=='crescent':
        edge([(9,4),(16,3),(24,5),(29,9),(31,15),(30,21),(27,27),(22,31),(16,33),(13,30),(20,26),(24,20),(25,14),(23,10),(18,7)],7)
        poly([(11,4),(20,4),(26,7),(29,11),(30,17),(29,22),(27,20),(28,15),(25,10),(21,7)],4)
        for x,y in [(25,6),(30,11),(31,18),(28,24)]:poly([(x-2,y),(x+2,y-2),(x+2,y+2)],4)
        guard(32);jewel(17,34,4,4)
    else:
        edge([(17,2),(21,7),(25,13),(26,21),(23,28),(28,31),(23,35),(18,33),(12,35),(6,31),(11,28),(9,21),(10,14),(13,7)],3)
        poly([(17,3),(17,25),(12,20),(12,13),(15,8)],4)
        poly([(18,8),(23,16),(24,21),(20,26),(18,27)],2)
        draw.line([(17,11),(14,17),(16,21),(13,26),(15,30)],fill=5,width=1)
        draw.line([(17,11),(20,17),(18,21),(21,26),(19,30)],fill=5,width=1)
        guard(31);jewel(17,32,4,5)
    return image

def pal(base, light, gem):
    b=ImageColor.getrgb('#'+base)
    dark=tuple(round(c*.47) for c in b)
    return [(0,0,0),(27,27,37),dark,b,ImageColor.getrgb('#'+light),ImageColor.getrgb('#'+gem),(128,142,159),(187,135,55),(224,232,217),(75,50,47)]

icons=root/'pixel'
icons.mkdir(exist_ok=True)
sheets={}
for id,_,_,kind,style,*entry in catalog:
    base,light,gem=entry[4:7]
    img=profile(style)
    colors=pal(base,light,gem)
    rgba=Image.new('RGBA',(W,H))
    rgba.putdata([colors[v]+(255 if v else 0,) for v in img.getdata()])
    rgba.save(icons/(id+'.png'))
    text=[''.join('.KDBLGMHOW'[img.getpixel((x,y))] for x in range(W)) for y in range(H)]
    palette={ch:'#%02x%02x%02x'%rgb for ch,rgb in zip('KDBLGMHOW',colors[1:])}
    grip_y=32.0 if style in ['solar','frost','gear','vine','dragon','spire'] else 38.0
    pitch=0.039 if kind in ['greatsword','staff','axe'] else (0.029 if kind in ['dagger','katar'] else 0.034)
    sheets[id]={'rows':text,'palette':palette,'grip':[17.0,grip_y],'pitch':pitch}
(root/'shapes.json').write_text(json.dumps(sheets,indent=2),encoding='utf-8')
