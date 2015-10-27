--IsBetween(a,b,c,dist)							
--Returns true if b is in a line between a and c. Example: IsBetween(GetOrigin(myHero),GetOrigin(minion),GetOrigin(target),125)
--Credits to Valorian my friend from LeagueBot

function IsBetween(a,b,c,dist)
	if a~=nil and b~=nil and c~=nil then
	 a=GetOrigin(a)
	 b=GetOrigin(b)
	 c=GetOrigin(c)
		ex = a.x
		ez = a.z
		tx = c.x
		tz = c.z
		dx = ex-tx
		dz = ez-tz
		if dx ~= 0 then
	  	m = dz/dx
  		c = ez-m*ex
		end
		mx = b.x
		mz = b.z
		distanc = (math.abs(mz - m*mx - c))/(math.sqrt(m*m+1))
		if distanc<dist and math.sqrt((tx-ex)*(tx-ex)+(tz-ez)*(tz-ez))>math.sqrt((tx-mx)*(tx-mx)+(tz-mz)*(tz-mz)) then
			return true
		end
	end
end

