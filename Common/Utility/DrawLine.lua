function DrawLine(x1,y1,x2,y2,width,quality,color,Ltype)
	Ltype = Ltype or 0
	x1, y1 = x1>=0 and x1<66000 and x1 or 0, y1>=0 and y1<66000 and y1 or 0
	x2, y2 = x2>=0 and x2<66000 and x2 or 0, y2>=0 and y2<66000 and y2 or 0
	dx = x2-x1
	dy = y2-y1
	adx = math.abs(dx)
	ady = math.abs(dy)
	sdx = math.sign(dx)
	sdy = math.sign(dy)
	if adx > ady then
		pdx = sdx * quality
		pdy = 0
		ddx = sdx * quality
		ddy = sdy * quality
		es  = ady
		el  = adx
	else
		pdx = 0
		pdy = sdy * quality
		ddx = sdx * quality
		ddy = sdy * quality
		es  = adx
		el  = ady
	end
	x = x1
	y = y1
	if Ltype == 1 then
		pos = WorldToScreen(1,x,0,y)
		DrawText(".",width,pos.x,pos.y,color)
	else
		DrawText(".",width,x,y,color)
	end
	fehler = el/2
	for i=1,el,quality do
		fehler = fehler - es
		if fehler < 0 then
			fehler = fehler + el
			x = x + ddx
			y = y + ddy
		else
			x = x + pdx
			y = y + pdy
		end
    if Ltype == 1 then
			pos = WorldToScreen(1,x,0,y)
			DrawText(".",width,pos.x,pos.y,color)
		else
			DrawText(".",width,x,y,color)
		end
	end
end

function math.sign(x)
   if x<0 then
     return -1
   elseif x>0 then
     return 1
   else
     return 0
   end
end
