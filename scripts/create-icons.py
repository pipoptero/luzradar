from PIL import Image, ImageDraw
for size,name in [(192,'icon-192.png'),(512,'icon-512.png'),(180,'apple-touch-icon.png')]:
 im=Image.new('RGB',(size,size),'#173d38');d=ImageDraw.Draw(im);scale=size/192;pts=[(105,23),(51,104),(90,104),(83,169),(142,78),(101,78)];d.polygon([(int(x*scale),int(y*scale)) for x,y in pts],fill='#d4ed74');im.save('public/'+name)
