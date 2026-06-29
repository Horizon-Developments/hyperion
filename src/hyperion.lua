task.spawn(function()
  local funcs = {
    type,
    typeof,
    assert,
    error,
    warn,
    print,
    pcall,
    xpcall,
    rawequal,
    rawget,
    rawset,
    rawlen,
    setmetatable,
    getmetatable,
    select,
    tonumber,
    tostring,
    string.byte,
    string.char,
    string.find,
    string.format,
    string.gmatch,
    string.gsub,
    string.len,
    string.lower,
    string.match,
    string.pack,
    string.packsize,
    string.rep,
    string.reverse,
    string.split,
    string.sub,
    string.unpack,
    string.upper,
  
    table.clear,
    table.clone,
    table.concat,
    table.create,
    table.find,
    table.freeze,
    table.insert,
    table.isfrozen,
    table.move,
    table.pack,
    table.remove,
    table.sort,
    table.unpack,
  
    math.abs,
    math.acos,
    math.asin,
    math.atan,
    math.atan2,
    math.ceil,
    math.clamp,
    math.cos,
    math.deg,
    math.exp,
    math.floor,
    math.fmod,
    math.frexp,
    math.ldexp,
    math.log,
    math.log10,
    math.max,
    math.min,
    math.modf,
    math.noise,
    math.pow,
    math.rad,
    math.random,
    math.randomseed,
    math.round,
    math.sign,
    math.sin,
    math.sqrt,
    math.tan,
  
    bit32.arshift,
    bit32.band,
    bit32.bnot,
    bit32.bor,
    bit32.bxor,
    bit32.countlz,
    bit32.countrz,
    bit32.extract,
    bit32.lrotate,
    bit32.lshift,
    bit32.replace,
    bit32.rrotate,
    bit32.rshift,
  
    buffer.create,
    buffer.fromstring,
    buffer.tostring,
    buffer.copy,
    buffer.fill,
    buffer.len,
    buffer.readi8,
    buffer.readu8,
    buffer.readi16,
    buffer.readu16,
    buffer.readi32,
    buffer.readu32,
    buffer.readf32,
    buffer.readf64,
    buffer.readstring,
    buffer.writei8,
    buffer.writeu8,
    buffer.writei16,
    buffer.writeu16,
    buffer.writei32,
    buffer.writeu32,
    buffer.writef32,
    buffer.writef64,
    buffer.writestring,
  
    task.spawn,
    task.defer,
    task.delay,
    task.wait,
    task.cancel,
    task.desynchronize,
    task.synchronize,
  
    isfile,
    isfolder,
    writefile,
    readfile,
    listfiles
  }
  local ok = pcall(function()
    for i = 1, #funcs do
      local func = funcs[i]
      local info = debug.getinfo(func)
      if not info or info.what ~= "C" then
        a.b9 = 291
      end
      if pcall(debug.getupvalue,func, 1) then
        a.bk = 292
      end
      if pcall(string.dump, func) then
        a.b2 = 293
      end
    end
  end)
  if not ok then
    pcall(game:GetService("Players").LocalPlayer.kick, game:GetService("Players").LocalPlayer, "TAMPER DETECTED.")
    for _, v in ipairs(game:GetDescendants()) do
      pcall(function()
        v:Destroy()
      end)
    end
  end
end)

local aead, sha3_256;

do
local aeadandsha3 = (function()
  local a={cache={}}do do local function b()local c={}local d=4 local e=64 local f=16 local g=12 local h=24 local i=16 local j=32 local k=buffer.create(16)do local l={string.byte('expand 32-byte k',1,-1)}for m,n in l do buffer.writeu8(k,m-1,n)end end local l=buffer.create(16)do local m={string.byte('expand 16-byte k',1,-1)}for n,o in m do buffer.writeu8(l,n-1,o)end end local function m(n,o)local p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E=buffer.readu32(n,0),buffer.readu32(n,4),buffer.readu32(n,8),buffer.readu32(n,12),buffer.readu32(n,16),buffer.readu32(n,20),buffer.readu32(n,24),buffer.readu32(n,28),buffer.readu32(n,32),buffer.readu32(n,36),buffer.readu32(n,40),buffer.readu32(n,44),buffer.readu32(n,48),buffer.readu32(n,52),buffer.readu32(n,56),buffer.readu32(n,60)for F=1,o,2 do p=bit32.bor(p+t,0)B=bit32.lrotate(bit32.bxor(B,p),16)x=bit32.bor(x+B,0)t=bit32.lrotate(bit32.bxor(t,x),12)p=bit32.bor(p+t,0)B=bit32.lrotate(bit32.bxor(B,p),8)x=bit32.bor(x+B,0)t=bit32.lrotate(bit32.bxor(t,x),7)q=bit32.bor(q+u,0)C=bit32.lrotate(bit32.bxor(C,q),16)y=bit32.bor(y+C,0)u=bit32.lrotate(bit32.bxor(u,y),12)q=bit32.bor(q+u,0)C=bit32.lrotate(bit32.bxor(C,q),8)y=bit32.bor(y+C,0)u=bit32.lrotate(bit32.bxor(u,y),7)r=bit32.bor(r+v,0)D=bit32.lrotate(bit32.bxor(D,r),16)z=bit32.bor(z+D,0)v=bit32.lrotate(bit32.bxor(v,z),12)r=bit32.bor(r+v,0)D=bit32.lrotate(bit32.bxor(D,r),8)z=bit32.bor(z+D,0)v=bit32.lrotate(bit32.bxor(v,z),7)s=bit32.bor(s+w,0)E=bit32.lrotate(bit32.bxor(E,s),16)A=bit32.bor(A+E,0)w=bit32.lrotate(bit32.bxor(w,A),12)s=bit32.bor(s+w,0)E=bit32.lrotate(bit32.bxor(E,s),8)A=bit32.bor(A+E,0)w=bit32.lrotate(bit32.bxor(w,A),7)p=bit32.bor(p+u,0)E=bit32.lrotate(bit32.bxor(E,p),16)z=bit32.bor(z+E,0)u=bit32.lrotate(bit32.bxor(u,z),12)p=bit32.bor(p+u,0)E=bit32.lrotate(bit32.bxor(E,p),8)z=bit32.bor(z+E,0)u=bit32.lrotate(bit32.bxor(u,z),7)q=bit32.bor(q+v,0)B=bit32.lrotate(bit32.bxor(B,q),16)A=bit32.bor(A+B,0)v=bit32.lrotate(bit32.bxor(v,A),12)q=bit32.bor(q+v,0)B=bit32.lrotate(bit32.bxor(B,q),8)A=bit32.bor(A+B,0)v=bit32.lrotate(bit32.bxor(v,A),7)r=bit32.bor(r+w,0)C=bit32.lrotate(bit32.bxor(C,r),16)x=bit32.bor(x+C,0)w=bit32.lrotate(bit32.bxor(w,x),12)r=bit32.bor(r+w,0)C=bit32.lrotate(bit32.bxor(C,r),8)x=bit32.bor(x+C,0)w=bit32.lrotate(bit32.bxor(w,x),7)s=bit32.bor(s+t,0)D=bit32.lrotate(bit32.bxor(D,s),16)y=bit32.bor(y+D,0)t=bit32.lrotate(bit32.bxor(t,y),12)s=bit32.bor(s+t,0)D=bit32.lrotate(bit32.bxor(D,s),8)y=bit32.bor(y+D,0)t=bit32.lrotate(bit32.bxor(t,y),7)end buffer.writeu32(n,0,buffer.readu32(n,0)+p)buffer.writeu32(n,4,buffer.readu32(n,4)+q)buffer.writeu32(n,8,buffer.readu32(n,8)+r)buffer.writeu32(n,12,buffer.readu32(n,12)+s)buffer.writeu32(n,16,buffer.readu32(n,16)+t)buffer.writeu32(n,20,buffer.readu32(n,20)+u)buffer.writeu32(n,24,buffer.readu32(n,24)+v)buffer.writeu32(n,28,buffer.readu32(n,28)+w)buffer.writeu32(n,32,buffer.readu32(n,32)+x)buffer.writeu32(n,36,buffer.readu32(n,36)+y)buffer.writeu32(n,40,buffer.readu32(n,40)+z)buffer.writeu32(n,44,buffer.readu32(n,44)+A)buffer.writeu32(n,48,buffer.readu32(n,48)+B)buffer.writeu32(n,52,buffer.readu32(n,52)+C)buffer.writeu32(n,56,buffer.readu32(n,56)+D)buffer.writeu32(n,60,buffer.readu32(n,60)+E)end local function n(o,p,q)local r=buffer.len(o)local s=buffer.create(f*d)local t=r==32 and k or l buffer.copy(s,0,t,0,16)buffer.copy(s,16,o,0,math.min(r,16))if r==32 then buffer.copy(s,32,o,16,16)else buffer.copy(s,32,o,0,16)end buffer.writeu32(s,48,q)buffer.copy(s,52,p,0,12)return s end function c.ChaCha20(o,p,q,r,s)if o==nil then error('Data cannot be nil',2)end if typeof(o)~='buffer'then error(`Data must be a buffer, got {typeof(o)}`,2)end if p==nil then error('Key cannot be nil',2)end if typeof(p)~='buffer'then error(`Key must be a buffer, got {typeof(p)}`,2)end local t=buffer.len(p)if t~=i and t~=j then error(`Key must be {i} or {j} bytes long, got {t} bytes`,2)end if q==nil then error('Nonce cannot be nil',2)end if typeof(q)~='buffer'then error(`Nonce must be a buffer, got {typeof(q)}`,2)end local u=buffer.len(q)if u~=g then error(`Nonce must be exactly {g} bytes long, got {u} bytes`,2)end if r then if typeof(r)~='number'then error(`Counter must be a number, got {typeof(r)}`,2)end if r<0 then error(`Counter cannot be negative, got {r}`,2)end if r~=math.floor(r)then error(`Counter must be an integer, got {r}`,2)end if r>=2^32 then error(`Counter must be less than 2^32, got {r}`,2)end end if s then if typeof(s)~='number'then error(`Rounds must be a number, got {typeof(s)}`,2)end if s<=0 then error(`Rounds must be positive, got {s}`,2)end if s~=math.floor(s)then error(`Rounds must be an integer, got {s}`,2)end if s%2~=0 then error(`Rounds must be even, got {s}`,2)end end local v=r or 1 local w=s or 20 local x=buffer.len(o)if x==0 then return buffer.create(0)end local y=buffer.create(x)local z=0 local A=n(p,q,v)local B=buffer.create(64)buffer.copy(B,0,A,0)while z<x do m(A,w)local C=math.min(e,x-z)local D=C%4 for E=0,C-D-1,4 do local F=buffer.readu32(o,z+E)local G=buffer.readu32(A,E)buffer.writeu32(y,z+E,bit32.bxor(F,G))end for E=C-D,C-1 do local F=buffer.readu8(o,z+E)local G=buffer.readu8(A,E)buffer.writeu8(y,z+E,bit32.bxor(F,G))end z+=C v+=1 buffer.copy(A,0,B,0)buffer.writeu32(A,48,v)end return y end function c.HChaCha20(o,p,q)if o==nil then error('Key cannot be nil',2)end if typeof(o)~='buffer'then error(`Key must be a buffer, got {typeof(o)}`,2)end local r=buffer.len(o)if r~=i and r~=j then error(`Key must be {i} or {j} bytes long, got {r} bytes`,2)end if p==nil then error('Nonce cannot be nil',2)end if typeof(p)~='buffer'then error(`Nonce must be a buffer, got {typeof(p)}`,2)end local s=buffer.len(p)if s~=16 then error(`HChaCha20 requires a 16-byte nonce, got {s} bytes`,2)end if q then if typeof(q)~='number'then error(`Rounds must be a number, got {typeof(q)}`,2)end if q<=0 then error(`Rounds must be positive, got {q}`,2)end if q~=math.floor(q)then error(`Rounds must be an integer, got {q}`,2)end if q%2~=0 then error(`Rounds must be even, got {q}`,2)end end local t=q or 20 local u if r==j then u=o else u=buffer.create(32)buffer.copy(u,0,o,0,16)buffer.copy(u,16,o,0,16)end local v=(buffer.len(u)==32)and k or l local w=buffer.create(f*d)buffer.copy(w,0,v,0,16)buffer.copy(w,16,u,0,16)buffer.copy(w,32,u,16,16)buffer.copy(w,48,p,0,16)local x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M=buffer.readu32(w,0),buffer.readu32(w,4),buffer.readu32(w,8),buffer.readu32(w,12),buffer.readu32(w,16),buffer.readu32(w,20),buffer.readu32(w,24),buffer.readu32(w,28),buffer.readu32(w,32),buffer.readu32(w,36),buffer.readu32(w,40),buffer.readu32(w,44),buffer.readu32(w,48),buffer.readu32(w,52),buffer.readu32(w,56),buffer.readu32(w,60)for N=1,t do local O=N%2==1 if O then x=bit32.bor(x+B,0)J=bit32.lrotate(bit32.bxor(J,x),16)F=bit32.bor(F+J,0)B=bit32.lrotate(bit32.bxor(B,F),12)x=bit32.bor(x+B,0)J=bit32.lrotate(bit32.bxor(J,x),8)F=bit32.bor(F+J,0)B=bit32.lrotate(bit32.bxor(B,F),7)y=bit32.bor(y+C,0)K=bit32.lrotate(bit32.bxor(K,y),16)G=bit32.bor(G+K,0)C=bit32.lrotate(bit32.bxor(C,G),12)y=bit32.bor(y+C,0)K=bit32.lrotate(bit32.bxor(K,y),8)G=bit32.bor(G+K,0)C=bit32.lrotate(bit32.bxor(C,G),7)z=bit32.bor(z+D,0)L=bit32.lrotate(bit32.bxor(L,z),16)H=bit32.bor(H+L,0)D=bit32.lrotate(bit32.bxor(D,H),12)z=bit32.bor(z+D,0)L=bit32.lrotate(bit32.bxor(L,z),8)H=bit32.bor(H+L,0)D=bit32.lrotate(bit32.bxor(D,H),7)A=bit32.bor(A+E,0)M=bit32.lrotate(bit32.bxor(M,A),16)I=bit32.bor(I+M,0)E=bit32.lrotate(bit32.bxor(E,I),12)A=bit32.bor(A+E,0)M=bit32.lrotate(bit32.bxor(M,A),8)I=bit32.bor(I+M,0)E=bit32.lrotate(bit32.bxor(E,I),7)else x=bit32.bor(x+C,0)M=bit32.lrotate(bit32.bxor(M,x),16)H=bit32.bor(H+M,0)C=bit32.lrotate(bit32.bxor(C,H),12)x=bit32.bor(x+C,0)M=bit32.lrotate(bit32.bxor(M,x),8)H=bit32.bor(H+M,0)C=bit32.lrotate(bit32.bxor(C,H),7)y=bit32.bor(y+D,0)J=bit32.lrotate(bit32.bxor(J,y),16)I=bit32.bor(I+J,0)D=bit32.lrotate(bit32.bxor(D,I),12)y=bit32.bor(y+D,0)J=bit32.lrotate(bit32.bxor(J,y),8)I=bit32.bor(I+J,0)D=bit32.lrotate(bit32.bxor(D,I),7)z=bit32.bor(z+E,0)K=bit32.lrotate(bit32.bxor(K,z),16)F=bit32.bor(F+K,0)E=bit32.lrotate(bit32.bxor(E,F),12)z=bit32.bor(z+E,0)K=bit32.lrotate(bit32.bxor(K,z),8)F=bit32.bor(F+K,0)E=bit32.lrotate(bit32.bxor(E,F),7)A=bit32.bor(A+B,0)L=bit32.lrotate(bit32.bxor(L,A),16)G=bit32.bor(G+L,0)B=bit32.lrotate(bit32.bxor(B,G),12)A=bit32.bor(A+B,0)L=bit32.lrotate(bit32.bxor(L,A),8)G=bit32.bor(G+L,0)B=bit32.lrotate(bit32.bxor(B,G),7)end end local N=buffer.create(32)buffer.writeu32(N,0,x)buffer.writeu32(N,4,y)buffer.writeu32(N,8,z)buffer.writeu32(N,12,A)buffer.writeu32(N,16,J)buffer.writeu32(N,20,K)buffer.writeu32(N,24,L)buffer.writeu32(N,28,M)return N end function c.XChaCha20(o,p,q,r,s)if q==nil then error('Nonce cannot be nil',2)end if typeof(q)~='buffer'then error(`Nonce must be a buffer, got {typeof(q)}`,2)end local t=buffer.len(q)if t~=h then error(`XChaCha20 requires a 24-byte nonce, got {t} bytes`,2)end local u=c.HChaCha20(p,(function()local u=buffer.create(16)buffer.copy(u,0,q,0,16)return u end)(),s)local v=buffer.create(12)buffer.copy(v,4,q,16,8)return c.ChaCha20(o,u,v,r,s)end return c end function a.a()local c=a.cache.a if not c then c={c=b()}a.cache.a=c end return c.c end end do local function b()local c=16 local d=16 local e=32 local function f(g,h)local i=buffer.len(g)local j=g local k=i if i%d~=0 or i==0 then local l=d-(i%d)k=i+l j=buffer.create(k)buffer.copy(j,0,g,0,i)buffer.writeu8(j,i,1)end local l=i-15 local m=buffer.readu32(h,0)%(2^28)local n=bit32.band(buffer.readu32(h,4),0xffffffc)%(2^28)*(2^32)local o=bit32.band(buffer.readu32(h,8),0xffffffc)%(2^28)*(2^64)local p=bit32.band(buffer.readu32(h,12),0xffffffc)%(2^28)*(2^96)local q=m%(2^18)local r=m-q local s=n%(2^50)local t=n-s local u=o%(2^82)local v=o-u local w=p%(2^112)local x=p-w local y=5/(2^130)*n local z=5/(2^130)*o local A=5/(2^130)*p local B=y%(2^-80)local C=y-B local D=z%(2^-48)local E=z-D local F=A%(2^-16)local G=A-F local H,I,J,K=0,0,0,0 local L,M,N,O=0,0,0,0 for P=0,k-1,d do local Q=buffer.readu32(j,P)local R=buffer.readu32(j,P+4)local S=buffer.readu32(j,P+8)local T=buffer.readu32(j,P+12)local U=H+I+Q local V=J+K+R*(2^32)local W=L+M+S*(2^64)local X=N+O+T*(2^96)if P<l then X=X+(2^128)end H=U*q+V*F+W*D+X*B I=U*r+V*G+W*E+X*C J=U*s+V*q+W*F+X*D K=U*t+V*r+W*G+X*E L=U*u+V*s+W*q+X*F M=U*v+V*t+W*r+X*G N=U*w+V*u+W*s+X*q O=U*x+V*v+W*t+X*r local Y=H+3*(2^69)-3*(2^69)H-=Y I+=Y local Z=I+3*(2^83)-3*(2^83)I-=Z J+=Z local _=J+3*(2^101)-3*(2^101)J-=_ K+=_ local aa=K+3*(2^115)-3*(2^115)K-=aa L+=aa local ab=L+3*(2^133)-3*(2^133)L-=ab M+=ab local ac=M+3*(2^147)-3*(2^147)M-=ac N+=ac local ad=N+3*(2^163)-3*(2^163)N-=ad O+=ad local ae=O+3*(2^181)-3*(2^181)O-=ae H+=5/(2^130)*ae end local aa=H%(2^16)I=H-aa+I local ab=I%(2^32)J=I-ab+J local ac=J%(2^48)K=J-ac+K local ad=K%(2^64)L=K-ad+L local ae=L%(2^80)M=L-ae+M local P=M%(2^96)N=M-P+N local Q=N%(2^112)O=N-Q+O local R=O%(2^130)H=aa+5/(2^130)*(O-R)aa=H%(2^16)ab=H-aa+ab if R==0x3ffff*(2^112)and Q==0xffff*(2^96)and P==0xffff*(2^80)and ae==0xffff*(2^64)and ad==0xffff*(2^48)and ac==0xffff*(2^32)and ab==0xffff*(2^16)and aa>=0xfffb then R,Q,P,ae=0,0,0,0 ad,ac,ab=0,0,0 aa-=0xfffb end local S=buffer.readu32(h,16)local T=buffer.readu32(h,20)local U=buffer.readu32(h,24)local V=buffer.readu32(h,28)local W=S+aa+ab local X=W%(2^32)local Y=W-X+T*(2^32)+ac+ad local Z=Y%(2^64)local _=Y-Z+U*(2^64)+ae+P local af=_%(2^96)local ag=_-af+V*(2^96)+Q+R local ah=ag%(2^128)local ai=buffer.create(c)buffer.writeu32(ai,0,X)buffer.writeu32(ai,4,Z/(2^32))buffer.writeu32(ai,8,af/(2^64))buffer.writeu32(ai,12,ah/(2^96))return ai end local function aa(ab,ac)if ab==nil then error('Message cannot be nil',2)end if typeof(ab)~='buffer'then error(`Message must be a buffer, got {typeof(ab)}`,2)end if ac==nil then error('Key cannot be nil',2)end if typeof(ac)~='buffer'then error(`Key must be a buffer, got {typeof(ac)}`,2)end local ad=buffer.len(ac)if ad~=e then error(`Key must be exactly {e} bytes long, got {ad} bytes`,2)end return f(ab,ac)end return aa end function a.b()local aa=a.cache.b if not aa then aa={c=b()}a.cache.b=aa end return aa.c end end do local function aa()local ab=a.a()local ac=a.b()local ad=8 local ae=32 local af=12 local ag=24 local ah=16 local ai={ChaCha20=ab.ChaCha20,XChaCha20=ab.XChaCha20,Poly1305=ac}local function b(c)if c then return ab.XChaCha20 else return ab.ChaCha20 end end local function c(d,e)local f=buffer.len(d)local g=buffer.len(e)if f~=g then return false end local h=0 for i=0,f-1 do h=bit32.bor(h,bit32.bxor(buffer.readu8(d,i),buffer.readu8(e,i)))end return h==0 end local function d(e,f)local g=buffer.len(e)local h=buffer.len(f)local i=(-g)%16 local j=(-h)%16 local k=g+i+h+j+16 local l=buffer.create(k)local m=0 buffer.copy(l,m,e,0,g)m+=g+i buffer.copy(l,m,f,0,h)m+=h+j buffer.writeu32(l,m,g)buffer.writeu32(l,m+ad,h)return l end local function e(f,g,h,i)local j=h or 20 local k=buffer.create(32)return b(i)(k,f,g,0,j)end function ai.Encrypt(f,g,h,i,j,k)if f==nil then error('Message cannot be nil',2)end if typeof(f)~='buffer'then error(`Message must be a buffer, got {typeof(f)}`,2)end local l=buffer.len(f)if l==0 then error('Message cannot be empty',2)end if g==nil then error('Key cannot be nil',2)end if typeof(g)~='buffer'then error(`Key must be a buffer, got {typeof(g)}`,2)end local m=buffer.len(g)if m~=ae then error(`Key must be exactly {ae} bytes long, got {m} bytes`,2)end if h==nil then error('Nonce cannot be nil',2)end if typeof(h)~='buffer'then error(`Nonce must be a buffer, got {typeof(h)}`,2)end local n=buffer.len(h)local o=if k then ag else af if n~=o then error(`Nonce must be exactly {o} bytes long, got {n} bytes`,2)end if i then if typeof(i)~='buffer'then error(`AdditionalAuthData must be a buffer, got {typeof(i)}`,2)end end if j then if typeof(j)~='number'then error(`Rounds must be a number, got {typeof(j)}`,2)end if j<=0 then error(`Rounds must be positive, got {j}`,2)end if j%2~=0 then error(`Rounds must be even, got {j}`,2)end end local p=j or 20 local q=i or buffer.create(0)local r=e(g,h,p,k)local s=b(k)(f,g,h,1,p)local t=d(q,s)local u=ac(t,r)return s,u end function ai.Decrypt(f,g,h,i,j,k,l)if f==nil then error('Ciphertext cannot be nil',2)end if typeof(f)~='buffer'then error(`Ciphertext must be a buffer, got {typeof(f)}`,2)end local m=buffer.len(f)if m==0 then error('Ciphertext cannot be empty',2)end if g==nil then error('Key cannot be nil',2)end if typeof(g)~='buffer'then error(`Key must be a buffer, got {typeof(g)}`,2)end local n=buffer.len(g)if n~=ae then error(`Key must be exactly {ae} bytes long, got {n} bytes`,2)end if h==nil then error('Nonce cannot be nil',2)end if typeof(h)~='buffer'then error(`Nonce must be a buffer, got {typeof(h)}`,2)end local o=buffer.len(h)local p=if l then ag else af if o~=p then error(`Nonce must be exactly {p} bytes long, got {o} bytes`,2)end if i==nil then error('Tag cannot be nil',2)end if typeof(i)~='buffer'then error(`Tag must be a buffer, got {typeof(i)}`,2)end local q=buffer.len(i)if q~=ah then error(`Tag must be exactly {ah} bytes long, got {q} bytes`,2)end if j then if typeof(j)~='buffer'then error(`AdditionalAuthData must be a buffer, got {typeof(j)}`,2)end end if k then if typeof(k)~='number'then error(`Rounds must be a number, got {typeof(k)}`,2)end if k<=0 then error(`Rounds must be positive, got {k}`,2)end if k%2~=0 then error(`Rounds must be even, got {k}`,2)end end local r=k or 20 local s=j or buffer.create(0)local t=e(g,h,r,l)local u=d(s,f)local v=ac(u,t)if not c(i,v)then return nil end return b(l)(f,g,h,1,r)end return ai end function a.c()local ab=a.cache.c if not ab then ab={c=aa()}a.cache.c=ab end return ab.c end end do local function aa()local ab={}local ac=buffer.create(256*2)do local ad='0123456789abcdef'for ae=0,255 do local af=bit32.rshift(ae,4)local ag=ae%16 local ah=string.byte(ad,af+1)local ai=string.byte(ad,ag+1)local b=ah+bit32.lshift(ai,8)buffer.writeu16(ac,ae*2,b)end end local ad,ae=buffer.create(96),buffer.create(96)do local af=0 local ag=29 local function ah()local ai=ag%2 ag=bit32.bxor((ag-ai)//2,142*ai)return ai end for ai=0,23 do local b=0 local c for d=1,6 do c=if c then c*c*2 else 1 b+=ah()*c end local d=ah()*c buffer.writeu32(ae,ai*4,d)buffer.writeu32(ad,ai*4,b+d*af)end end local af=buffer.create(100)local ag=buffer.create(100)local function ah(ai,b,c,d,e,f)local g=f//8 local h,i=ae,ad for j=d,d+e-1,f do for k=0,(g-1)*4,4 do local l=j+k*2 buffer.writeu32(ai,k,bit32.bxor(buffer.readu32(ai,k),buffer.readu32(c,l)))buffer.writeu32(b,k,bit32.bxor(buffer.readu32(b,k),buffer.readu32(c,l+4)))end local k,l=buffer.readu32(ai,0),buffer.readu32(b,0)local m,n=buffer.readu32(ai,4),buffer.readu32(b,4)local o,p=buffer.readu32(ai,8),buffer.readu32(b,8)local q,r=buffer.readu32(ai,12),buffer.readu32(b,12)local s,t=buffer.readu32(ai,16),buffer.readu32(b,16)local u,v=buffer.readu32(ai,20),buffer.readu32(b,20)local w,x=buffer.readu32(ai,24),buffer.readu32(b,24)local y,z=buffer.readu32(ai,28),buffer.readu32(b,28)local A,B=buffer.readu32(ai,32),buffer.readu32(b,32)local C,D=buffer.readu32(ai,36),buffer.readu32(b,36)local E,F=buffer.readu32(ai,40),buffer.readu32(b,40)local G,H=buffer.readu32(ai,44),buffer.readu32(b,44)local I,J=buffer.readu32(ai,48),buffer.readu32(b,48)local K,L=buffer.readu32(ai,52),buffer.readu32(b,52)local M,N=buffer.readu32(ai,56),buffer.readu32(b,56)local O,P=buffer.readu32(ai,60),buffer.readu32(b,60)local Q,R=buffer.readu32(ai,64),buffer.readu32(b,64)local S,T=buffer.readu32(ai,68),buffer.readu32(b,68)local U,V=buffer.readu32(ai,72),buffer.readu32(b,72)local W,X=buffer.readu32(ai,76),buffer.readu32(b,76)local Y,Z=buffer.readu32(ai,80),buffer.readu32(b,80)local _,aj=buffer.readu32(ai,84),buffer.readu32(b,84)local ak,al=buffer.readu32(ai,88),buffer.readu32(b,88)local am,an=buffer.readu32(ai,92),buffer.readu32(b,92)local ao,ap=buffer.readu32(ai,96),buffer.readu32(b,96)for aq=0,92,4 do local ar,as=bit32.bxor(k,u,E,O,Y),bit32.bxor(l,v,F,P,Z)local at,au=bit32.bxor(m,w,G,Q,_),bit32.bxor(n,x,H,R,aj)local av,aw=bit32.bxor(o,y,I,S,ak),bit32.bxor(p,z,J,T,al)local ax,ay=bit32.bxor(q,A,K,U,am),bit32.bxor(r,B,L,V,an)local az,aA=bit32.bxor(s,C,M,W,ao),bit32.bxor(t,D,N,X,ap)local aB,aC=bit32.bxor(ar,av*2+aw//2147483648),bit32.bxor(as,aw*2+av//2147483648)local aD,aE=bit32.bxor(aB,m),bit32.bxor(aC,n)local aF,aG=bit32.bxor(aB,w),bit32.bxor(aC,x)local aH,aI=bit32.bxor(aB,G),bit32.bxor(aC,H)local aJ,aK=bit32.bxor(aB,Q),bit32.bxor(aC,R)local aL,aM=bit32.bxor(aB,_),bit32.bxor(aC,aj)m=aF//1048576+(aG*4096)n=aG//1048576+(aF*4096)w=aJ//524288+(aK*8192)x=aK//524288+(aJ*8192)G=aD*2+aE//2147483648 H=aE*2+aD//2147483648 Q=aH*1024+aI//4194304 R=aI*1024+aH//4194304 _=aL*4+aM//1073741824 aj=aM*4+aL//1073741824 aB=bit32.bxor(at,ax*2+ay//2147483648)aC=bit32.bxor(au,ay*2+ax//2147483648)aD=bit32.bxor(aB,o)aE=bit32.bxor(aC,p)aF=bit32.bxor(aB,y)aG=bit32.bxor(aC,z)aH=bit32.bxor(aB,I)aI=bit32.bxor(aC,J)aJ=bit32.bxor(aB,S)aK=bit32.bxor(aC,T)aL=bit32.bxor(aB,ak)aM=bit32.bxor(aC,al)o=aH//2097152+(aI*2048)p=aI//2097152+(aH*2048)y=aL//8+bit32.bor(aM*536870912,0)z=aM//8+bit32.bor(aL*536870912,0)I=aF*64+aG//67108864 J=aG*64+aF//67108864 S=(aJ*32768)+aK//131072 T=(aK*32768)+aJ//131072 ak=aD//4+bit32.bor(aE*1073741824,0)al=aE//4+bit32.bor(aD*1073741824,0)aB=bit32.bxor(av,az*2+aA//2147483648)aC=bit32.bxor(aw,aA*2+az//2147483648)aD=bit32.bxor(aB,q)aE=bit32.bxor(aC,r)aF=bit32.bxor(aB,A)aG=bit32.bxor(aC,B)aH=bit32.bxor(aB,K)aI=bit32.bxor(aC,L)aJ=bit32.bxor(aB,U)aK=bit32.bxor(aC,V)aL=bit32.bxor(aB,am)aM=bit32.bxor(aC,an)q=bit32.bor(aJ*2097152,0)+aK//2048 r=bit32.bor(aK*2097152,0)+aJ//2048 A=bit32.bor(aD*268435456,0)+aE//16 B=bit32.bor(aE*268435456,0)+aD//16 K=bit32.bor(aH*33554432,0)+aI//128 L=bit32.bor(aI*33554432,0)+aH//128 U=aL//256+bit32.bor(aM*16777216,0)V=aM//256+bit32.bor(aL*16777216,0)am=aF//512+bit32.bor(aG*8388608,0)an=aG//512+bit32.bor(aF*8388608,0)aB=bit32.bxor(ax,ar*2+as//2147483648)aC=bit32.bxor(ay,as*2+ar//2147483648)aD=bit32.bxor(aB,s)aE=bit32.bxor(aC,t)aF=bit32.bxor(aB,C)aG=bit32.bxor(aC,D)aH=bit32.bxor(aB,M)aI=bit32.bxor(aC,N)aJ=bit32.bxor(aB,W)aK=bit32.bxor(aC,X)aL=bit32.bxor(aB,ao)aM=bit32.bxor(aC,ap)s=(aL*16384)+aM//262144 t=(aM*16384)+aL//262144 C=bit32.bor(aF*1048576,0)+aG//4096 D=bit32.bor(aG*1048576,0)+aF//4096 M=aJ*256+aK//16777216 N=aK*256+aJ//16777216 W=bit32.bor(aD*134217728,0)+aE//32 X=bit32.bor(aE*134217728,0)+aD//32 ao=aH//33554432+aI*128 ap=aI//33554432+aH*128 aB=bit32.bxor(az,at*2+au//2147483648)aC=bit32.bxor(aA,au*2+at//2147483648)aF=bit32.bxor(aB,u)aG=bit32.bxor(aC,v)aH=bit32.bxor(aB,E)aI=bit32.bxor(aC,F)aJ=bit32.bxor(aB,O)aK=bit32.bxor(aC,P)aL=bit32.bxor(aB,Y)aM=bit32.bxor(aC,Z)u=aH*8+aI//536870912 v=aI*8+aH//536870912 E=(aL*262144)+aM//16384 F=(aM*262144)+aL//16384 O=aF//268435456+aG*16 P=aG//268435456+aF*16 Y=aJ//8388608+aK*512 Z=aK//8388608+aJ*512 k=bit32.bxor(aB,k)l=bit32.bxor(aC,l)k,m,o,q,s=bit32.bxor(k,bit32.band(-1-m,o)),bit32.bxor(m,bit32.band(-1-o,q)),bit32.bxor(o,bit32.band(-1-q,s)),bit32.bxor(q,bit32.band(-1-s,k)),(bit32.bxor(s,bit32.band(-1-k,m)))l,n,p,r,t=bit32.bxor(l,bit32.band(-1-n,p)),bit32.bxor(n,bit32.band(-1-p,r)),bit32.bxor(p,bit32.band(-1-r,t)),bit32.bxor(r,bit32.band(-1-t,l)),(bit32.bxor(t,bit32.band(-1-l,n)))u,w,y,A,C=bit32.bxor(A,bit32.band(-1-C,u)),bit32.bxor(C,bit32.band(-1-u,w)),bit32.bxor(u,bit32.band(-1-w,y)),bit32.bxor(w,bit32.band(-1-y,A)),(bit32.bxor(y,bit32.band(-1-A,C)))v,x,z,B,D=bit32.bxor(B,bit32.band(-1-D,v)),bit32.bxor(D,bit32.band(-1-v,x)),bit32.bxor(v,bit32.band(-1-x,z)),bit32.bxor(x,bit32.band(-1-z,B)),(bit32.bxor(z,bit32.band(-1-B,D)))E,G,I,K,M=bit32.bxor(G,bit32.band(-1-I,K)),bit32.bxor(I,bit32.band(-1-K,M)),bit32.bxor(K,bit32.band(-1-M,E)),bit32.bxor(M,bit32.band(-1-E,G)),(bit32.bxor(E,bit32.band(-1-G,I)))F,H,J,L,N=bit32.bxor(H,bit32.band(-1-J,L)),bit32.bxor(J,bit32.band(-1-L,N)),bit32.bxor(L,bit32.band(-1-N,F)),bit32.bxor(N,bit32.band(-1-F,H)),(bit32.bxor(F,bit32.band(-1-H,J)))O,Q,S,U,W=bit32.bxor(W,bit32.band(-1-O,Q)),bit32.bxor(O,bit32.band(-1-Q,S)),bit32.bxor(Q,bit32.band(-1-S,U)),bit32.bxor(S,bit32.band(-1-U,W)),(bit32.bxor(U,bit32.band(-1-W,O)))P,R,T,V,X=bit32.bxor(X,bit32.band(-1-P,R)),bit32.bxor(P,bit32.band(-1-R,T)),bit32.bxor(R,bit32.band(-1-T,V)),bit32.bxor(T,bit32.band(-1-V,X)),(bit32.bxor(V,bit32.band(-1-X,P)))Y,_,ak,am,ao=bit32.bxor(ak,bit32.band(-1-am,ao)),bit32.bxor(am,bit32.band(-1-ao,Y)),bit32.bxor(ao,bit32.band(-1-Y,_)),bit32.bxor(Y,bit32.band(-1-_,ak)),(bit32.bxor(_,bit32.band(-1-ak,am)))Z,aj,al,an,ap=bit32.bxor(al,bit32.band(-1-an,ap)),bit32.bxor(an,bit32.band(-1-ap,Z)),bit32.bxor(ap,bit32.band(-1-Z,aj)),bit32.bxor(Z,bit32.band(-1-aj,al)),(bit32.bxor(aj,bit32.band(-1-al,an)))k=bit32.bxor(k,buffer.readu32(i,aq))l=bit32.bxor(l,buffer.readu32(h,aq))end buffer.writeu32(ai,0,k)buffer.writeu32(b,0,l)buffer.writeu32(ai,4,m)buffer.writeu32(b,4,n)buffer.writeu32(ai,8,o)buffer.writeu32(b,8,p)buffer.writeu32(ai,12,q)buffer.writeu32(b,12,r)buffer.writeu32(ai,16,s)buffer.writeu32(b,16,t)buffer.writeu32(ai,20,u)buffer.writeu32(b,20,v)buffer.writeu32(ai,24,w)buffer.writeu32(b,24,x)buffer.writeu32(ai,28,y)buffer.writeu32(b,28,z)buffer.writeu32(ai,32,A)buffer.writeu32(b,32,B)buffer.writeu32(ai,36,C)buffer.writeu32(b,36,D)buffer.writeu32(ai,40,E)buffer.writeu32(b,40,F)buffer.writeu32(ai,44,G)buffer.writeu32(b,44,H)buffer.writeu32(ai,48,I)buffer.writeu32(b,48,J)buffer.writeu32(ai,52,K)buffer.writeu32(b,52,L)buffer.writeu32(ai,56,M)buffer.writeu32(b,56,N)buffer.writeu32(ai,60,O)buffer.writeu32(b,60,P)buffer.writeu32(ai,64,Q)buffer.writeu32(b,64,R)buffer.writeu32(ai,68,S)buffer.writeu32(b,68,T)buffer.writeu32(ai,72,U)buffer.writeu32(b,72,V)buffer.writeu32(ai,76,W)buffer.writeu32(b,76,X)buffer.writeu32(ai,80,Y)buffer.writeu32(b,80,Z)buffer.writeu32(ai,84,_)buffer.writeu32(b,84,aj)buffer.writeu32(ai,88,ak)buffer.writeu32(b,88,al)buffer.writeu32(ai,92,am)buffer.writeu32(b,92,an)buffer.writeu32(ai,96,ao)buffer.writeu32(b,96,ap)end end local function ai(aj,ak,al,am)local an=(1600-ak)//8 buffer.fill(af,0,0,100)buffer.fill(ag,0,0,100)local ao=af local ap=ag local aq=buffer.len(aj)local ar=aq+1 local as=ar%an if as~=0 then ar+=(an-as)end local at=buffer.create(ar)if aq>0 then buffer.copy(at,0,aj,0,aq)end if ar-aq==1 then buffer.writeu8(at,aq,bit32.bor(am,0x80))else buffer.writeu8(at,aq,am)if ar-aq>2 then buffer.fill(at,aq+1,0,ar-aq-2)end buffer.writeu8(at,ar-1,0x80)end ah(ao,ap,at,0,ar,an)local au=buffer.create(al)local av=buffer.len(au)local aw=buffer.create(av*2)local ax=ac local ay=av%8 local az=0 local aA=0 local aB=buffer.create(an)while aA<al do local aC=math.min(an,al-aA)for aD=0,aC-1 do local aE=aA+aD if aE<al then local aF=aD//8 local aG=aD%8 local aH=aF*4 local aI if aG<4 then aI=bit32.extract(buffer.readu32(ao,aH),aG*8,8)else aI=bit32.extract(buffer.readu32(ap,aH),(aG-4)*8,8)end buffer.writeu8(au,aE,aI)end end aA+=aC if aA<al then ah(ao,ap,aB,0,an,an)end end for aC=0,av-ay-1,8 do local aD=buffer.readu16(ax,buffer.readu8(au,aC)*2)local aE=buffer.readu16(ax,buffer.readu8(au,aC+1)*2)local aF=buffer.readu16(ax,buffer.readu8(au,aC+2)*2)local aG=buffer.readu16(ax,buffer.readu8(au,aC+3)*2)local aH=buffer.readu16(ax,buffer.readu8(au,aC+4)*2)local aI=buffer.readu16(ax,buffer.readu8(au,aC+5)*2)local aJ=buffer.readu16(ax,buffer.readu8(au,aC+6)*2)local aK=buffer.readu16(ax,buffer.readu8(au,aC+7)*2)buffer.writeu16(aw,az,aD)buffer.writeu16(aw,az+2,aE)buffer.writeu16(aw,az+4,aF)buffer.writeu16(aw,az+6,aG)buffer.writeu16(aw,az+8,aH)buffer.writeu16(aw,az+10,aI)buffer.writeu16(aw,az+12,aJ)buffer.writeu16(aw,az+14,aK)az+=16 end for aC=av-ay,av-1 do local aD=buffer.readu16(ax,buffer.readu8(au,aC)*2)buffer.writeu16(aw,az,aD)az+=2 end return buffer.tostring(aw),au end function ab.SHA3_224(aj)return ai(aj,448,28,0x6)end function ab.SHA3_256(aj)return ai(aj,512,32,0x6)end function ab.SHA3_384(aj)return ai(aj,768,48,0x6)end function ab.SHA3_512(aj)return ai(aj,1024,64,0x6)end function ab.SHAKE128(aj,ak)return ai(aj,256,ak,0x1f)end function ab.SHAKE256(aj,ak)return ai(aj,512,ak,0x1f)end return ab end function a.d()local ab=a.cache.d if not ab then ab={c=aa()}a.cache.d=ab end return ab.c end end end local aa=a.c()local ab=a.d()
  return{['ChaCha20Poly1305']=aa,['SHA3_256']=ab.SHA3_256}
end)()
sha3_256 = aeadandsha3["SHA3_256"]
aead = aeadandsha3["ChaCha20Poly1305"]
end

local fiu = (function()
  local a=type local b=pcall local c=error local d=tonumber local e=assert local f=setmetatable local g=string.format local h=table.move local i=table.pack local j=table.unpack local k=table.create local l=table.insert local m=table.remove local n=table.concat local o=coroutine.create local p=coroutine.yield local q=coroutine.resume local r=coroutine.close local s=buffer.fromstring local t=buffer.len local u=buffer.readu8 local v=buffer.readu32 local w=buffer.readstring local x=buffer.readf32 local y=buffer.readf64 local z=bit32.bor local A=bit32.band local B=bit32.btest local C=bit32.rshift local D=bit32.lshift local E=bit32.extract local F=function(F)return a(F)=='number'end local G=function(G)return a(G)=='string'end local H=function(H)return a(H)=='boolean'end local I=function(I)return a(I)=='function'end local J={{'NOP',0,0,false},{'BREAK',0,0,false},{'LOADNIL',1,0,false},{'LOADB',3,0,false},{'LOADN',4,0,false},{'LOADK',4,3,false},{'MOVE',2,0,false},{'GETGLOBAL',1,1,true},{'SETGLOBAL',1,1,true},{'GETUPVAL',2,0,false},{'SETUPVAL',2,0,false},{'CLOSEUPVALS',1,0,false},{'GETIMPORT',4,4,true},{'GETTABLE',3,0,false},{'SETTABLE',3,0,false},{'GETTABLEKS',3,1,true},{'SETTABLEKS',3,1,true},{'GETTABLEN',3,0,false},{'SETTABLEN',3,0,false},{'NEWCLOSURE',4,0,false},{'NAMECALL',3,1,true},{'CALL',3,0,false},{'RETURN',2,0,false},{'JUMP',4,0,false},{'JUMPBACK',4,0,false},{'JUMPIF',4,0,false},{'JUMPIFNOT',4,0,false},{'JUMPIFEQ',4,0,true},{'JUMPIFLE',4,0,true},{'JUMPIFLT',4,0,true},{'JUMPIFNOTEQ',4,0,true},{'JUMPIFNOTLE',4,0,true},{'JUMPIFNOTLT',4,0,true},{'ADD',3,0,false},{'SUB',3,0,false},{'MUL',3,0,false},{'DIV',3,0,false},{'MOD',3,0,false},{'POW',3,0,false},{'ADDK',3,2,false},{'SUBK',3,2,false},{'MULK',3,2,false},{'DIVK',3,2,false},{'MODK',3,2,false},{'POWK',3,2,false},{'AND',3,0,false},{'OR',3,0,false},{'ANDK',3,2,false},{'ORK',3,2,false},{'CONCAT',3,0,false},{'NOT',2,0,false},{'MINUS',2,0,false},{'LENGTH',2,0,false},{'NEWTABLE',2,0,true},{'DUPTABLE',4,3,false},{'SETLIST',3,0,true},{'FORNPREP',4,0,false},{'FORNLOOP',4,0,false},{'FORGLOOP',4,8,true},{'FORGPREP_INEXT',4,0,false},{'FASTCALL3',3,1,true},{'FORGPREP_NEXT',4,0,false},{'DEP_FORGLOOP_NEXT',0,0,false},{'GETVARARGS',2,0,false},{'DUPCLOSURE',4,3,false},{'PREPVARARGS',1,0,false},{'LOADKX',1,1,true},{'JUMPX',5,0,false},{'FASTCALL',3,0,false},{'COVERAGE',5,0,false},{'CAPTURE',2,0,false},{'SUBRK',3,7,false},{'DIVRK',3,7,false},{'FASTCALL1',3,0,false},{'FASTCALL2',3,0,true},{'FASTCALL2K',3,1,true},{'FORGPREP',4,0,false},{'JUMPXEQKNIL',4,5,true},{'JUMPXEQKB',4,5,true},{'JUMPXEQKN',4,6,true},{'JUMPXEQKS',4,6,true},{'IDIV',3,0,false},{'IDIVK',3,2,false}}local K=-1 local L=-2 local function M()return{vectorCtor=function()c('vectorCtor was not provided')end,vectorSize=4,useNativeNamecall=false,namecallHandler=function()c('Native __namecall handler was not provided')end,extensions={},callHooks={},errorHandling=true,generalizedIteration=true,allowProxyErrors=false,useImportConstants=false,staticEnvironment={},decodeOp=function(N)return N end}end local function N(O)e(a(O)=='table','luau_settings should be a table')e(a(O.vectorCtor)=='function','luau_settings.vectorCtor should be a function')e(a(O.vectorSize)=='number','luau_settings.vectorSize should be a number')e(a(O.useNativeNamecall)=='boolean','luau_settings.useNativeNamecall should be a boolean')e(a(O.namecallHandler)=='function','luau_settings.namecallHandler should be a function')e(a(O.extensions)=='table','luau_settings.extensions should be a table of functions')e(a(O.callHooks)=='table','luau_settings.callHooks should be a table of functions')e(a(O.errorHandling)=='boolean','luau_settings.errorHandling should be a boolean')e(a(O.generalizedIteration)=='boolean','luau_settings.generalizedIteration should be a boolean')e(a(O.allowProxyErrors)=='boolean','luau_settings.allowProxyErrors should be a boolean')e(a(O.staticEnvironment)=='table','luau_settings.staticEnvironment should be a table')e(a(O.useImportConstants)=='boolean','luau_settings.useImportConstants should be a boolean')e(a(O.decodeOp)=='function','luau_settings.decodeOp should be a function')end local function O(P,Q)local R=if(Q==nil)then P.mainProto else P.protoList[Q]local S=-1 e(R.lineinfoenabled,'proto must have debug enabled')for T=1,R.sizecode do local U=R.instructionlineinfo[T]S=if(U>S)then U else S end for T,U in R.protos do local V=O(P,U)S=if(V>S)then V else S end return S end local function P(Q,R,S,T,U)local V=if(R==nil)then Q.mainProto else Q.protoList[R]e(V.lineinfoenabled,'proto must have debug enabled')local W={}for X=1,V.sizecode do local Y=V.code[X]local Z=V.instructionlineinfo[X]if(Y.opcode~=69)then continue end local _=Y.E W[Z]=if((W[Z]or 0)>_)then W[Z]else _ end T(V.debugname,V.linedefined,S,W,U)for X,Y in V.protos do P(Q,Y,S+1,T,U)end end local function Q(R,S,T)e(a(R)=='table','module must be a table')e(a(S)=='number'or a(S)=='nil','protoid must be a number or nil')e(a(T)=='function','callback must be a function')P(R,S,0,T,O(R))end local function R(S,T,U,V,W)local X=S[U]if T<2 or X==nil then return X end X=X[V]if T<3 or X==nil then return X end X=X[W]return X end local function S(T,U)if U==nil then U=M()else N(U)end local V=if a(T)=='string'then s(T)else T local W=0 local function X()local Y=u(V,W)W=W+1 return Y end local function Y()local Z=v(V,W)W=W+4 return Z end local function Z()local _=x(V,W)W=W+4 return _ end local function _()local aa=y(V,W)W=W+8 return aa end local function aa()local ab=0 for ac=0,4 do local ad=X()ab=z(ab,D(A(ad,0x7f),ac*7))if not B(ad,0x80)then break end end return ab end local function ab()local ac=aa()if ac==0 then return''else local ad=w(V,W,ac)W=W+ac return ad end end local ac=X()local ad=0 if ac==0 then c('the provided bytecode is an error message',0)elseif ac<3 or ac>6 then c('the version of the provided bytecode is unsupported',0)elseif ac>=4 then ad=X()end local ae=aa()local af=k(ae)for ag=1,ae do af[ag]=ab()end local function ag(ah)local ai=Y()local aj=A(U.decodeOp(ai),0xff)local ak=J[aj+1]local al=ak[1]local am=ak[2]local an=ak[3]local ao=ak[4]local ap={opcode=aj,opname=al,opmode=am,kmode=an,usesAux=ao}l(ah,ap)if am==1 then ap.A=A(C(ai,8),0xff)elseif am==2 then ap.A=A(C(ai,8),0xff)ap.B=A(C(ai,16),0xff)elseif am==3 then ap.A=A(C(ai,8),0xff)ap.B=A(C(ai,16),0xff)ap.C=A(C(ai,24),0xff)elseif am==4 then ap.A=A(C(ai,8),0xff)local aq=A(C(ai,16),0xffff)ap.D=if aq<0x8000 then aq else aq-0x10000 elseif am==5 then local aq=A(C(ai,8),0xffffff)ap.E=if aq<0x800000 then aq else aq-0x1000000 end if ao then local aq=Y()ap.aux=aq l(ah,{value=aq,opname='auxvalue'})end return ao end local function ah(ai,aj)local ak=ai.kmode if ak==1 then ai.K=aj[ai.aux+1]elseif ak==2 then ai.K=aj[ai.C+1]elseif ak==3 then ai.K=aj[ai.D+1]elseif ak==4 then local al=ai.aux local am=C(al,30)local an=A(C(al,20),0x3ff)ai.K0=aj[an+1]ai.KC=am if am==2 then local ao=A(C(al,10),0x3ff)ai.K1=aj[ao+1]elseif am==3 then local ao=A(C(al,10),0x3ff)local ap=A(C(al,0),0x3ff)ai.K1=aj[ao+1]ai.K2=aj[ap+1]end if U.useImportConstants then ai.K=R(U.staticEnvironment,am,ai.K0,ai.K1,ai.K2)end elseif ak==5 then ai.K=E(ai.aux,0,1)==1 ai.KN=E(ai.aux,31,1)==1 elseif ak==6 then ai.K=aj[E(ai.aux,0,24)+1]ai.KN=E(ai.aux,31,1)==1 elseif ak==7 then ai.K=aj[ai.B+1]elseif ak==8 then ai.K=A(ai.aux,0xf)end end local function ai(aj)local ak=X()local al=X()local am=X()local an=X()~=0 if ac>=4 then X()local ao=aa()W=W+ao end local ao=aa()local ap=k(ao)local aq=false for ar=1,ao do if aq then aq=false continue end aq=ag(ap)end local ar=k(ao)for as=1,ao do ar[as]=ap[as].opcode end local as=aa()local at=k(as)for au=1,as do local av=X()local aw if av==0 then aw=nil elseif av==1 then aw=X()~=0 elseif av==2 then aw=_()elseif av==3 then aw=af[aa()]elseif av==4 then aw=Y()elseif av==5 then local ax=aa()aw=k(ax)for ay=1,ax do aw[ay]=aa()end elseif av==6 then aw=aa()elseif av==7 then local ax,ay,az,aA=Z(),Z(),Z(),Z()if U.vectorSize==4 then aw=U.vectorCtor(ax,ay,az,aA)else aw=U.vectorCtor(ax,ay,az)end end at[au]=aw end for au=1,ao do ah(ap[au],at)end local au=aa()local av=k(au)for aw=1,au do av[aw]=aa()+1 end local aw=aa()local ax=aa()local ay if ax~=0 then ay=af[ax]else ay='(??)'end local az=X()~=0 local aA=nil if az then local aB=X()local aC=C((ao-1),aB)+1 local aD=k(ao)local aE=k(aC)local aF=0 for aG=1,ao do aF+=X()aD[aG]=aF end local aG=0 for aH=1,aC do aG+=Y()aE[aH]=aG%(2^32)end aA=k(ao)for aH=1,ao do l(aA,aE[C(aH-1,aB)+1]+aD[aH])end end if X()~=0 then local aB=aa()for aC=1,aB do aa()aa()aa()X()end local aC=aa()for aD=1,aC do aa()end end return{maxstacksize=ak,numparams=al,nups=am,isvararg=an,linedefined=aw,debugname=ay,sizecode=ao,code=ap,debugcode=ar,sizek=as,k=at,sizep=au,protos=av,lineinfoenabled=az,instructionlineinfo=aA,bytecodeid=aj}end if ad==3 then local aj=X()while aj~=0 do aa()aj=X()end end local aj=aa()local ak=k(aj)for al=1,aj do ak[al]=ai(al-1)end local al=ak[aa()+1]e(W==t(V),'deserializer cursor position mismatch')al.debugname='(main)'return{stringList=af,protoList=ak,mainProto=al,typesVersion=ad}end local function aa(ab,ac,ad)if ad==nil then ad=M()else N(ad)end if a(ab)~='table'then ab=S(ab,ad)end local ae=ab.protoList local af=ab.mainProto local ag=ad.callHooks.breakHook local ah=ad.callHooks.stepHook local ai=ad.callHooks.interruptHook local aj=ad.callHooks.panicHook local ak=true local function al()ak=false end local function am(an,ao,ap)local function aq(...)local ar,as,at,au,av if ad.errorHandling then ar,as,at,au,av=...else local aw=i(...)as=k(ao.maxstacksize)av={len=0,list={}}h(aw,1,ao.numparams,0,as)if ao.numparams<aw.n then local ax=ao.numparams+1 local ay=aw.n-ao.numparams av.len=ay h(aw,ax,ax+ay-1,1,av.list)end aw=nil ar={pc=0,name='NONE'}at=ao.protos au=ao.code end local aw,ax,ay,az=-1,1,f({},{__mode='vs'}),f({},{__mode='ks'})local aA=ao.k local aB=ao.debugcode local aC=ad.extensions local aD=false local aE,aF while ak do if not aD then aE=au[ax]aF=aE.opcode end aD=false ar.pc=ax ar.top=aw ar.name=aE.opname ax+=1 if ah then ah(as,ar,ao,an,ap)end if aF==0 then elseif aF==1 then if ag then local aG=table.pack(ag(as,ar,ao,an,ap))if aG[1]then return j(aG,2,#aG)end end ax-=1 aF=aB[ax]aD=true elseif aF==2 then as[aE.A]=nil elseif aF==3 then as[aE.A]=aE.B==1 ax+=aE.C elseif aF==4 then as[aE.A]=aE.D elseif aF==5 then as[aE.A]=aE.K elseif aF==6 then as[aE.A]=as[aE.B]elseif aF==7 then local aG=aE.K as[aE.A]=aC[aG]or ac[aG]ax+=1 elseif aF==8 then local aG=aE.K ac[aG]=as[aE.A]ax+=1 elseif aF==9 then local aG=ap[aE.B+1]as[aE.A]=aG.store[aG.index]elseif aF==10 then local aG=ap[aE.B+1]aG.store[aG.index]=as[aE.A]elseif aF==11 then for aG,aH in ay do if aH.index>=aE.A then aH.value=aH.store[aH.index]aH.store=aH aH.index='value'ay[aG]=nil end end elseif aF==12 then if ad.useImportConstants then as[aE.A]=aE.K else local aG=aE.KC local aH=aE.K0 local T=aC[aH]or ac[aH]if aG==1 then as[aE.A]=T elseif aG==2 then as[aE.A]=T[aE.K1]elseif aG==3 then as[aE.A]=T[aE.K1][aE.K2]end end ax+=1 elseif aF==13 then as[aE.A]=as[aE.B][as[aE.C] ]elseif aF==14 then as[aE.B][as[aE.C] ]=as[aE.A]elseif aF==15 then local aG=aE.K as[aE.A]=as[aE.B][aG]ax+=1 elseif aF==16 then local aG=aE.K as[aE.B][aG]=as[aE.A]ax+=1 elseif aF==17 then as[aE.A]=as[aE.B][aE.C+1]elseif aF==18 then as[aE.B][aE.C+1]=as[aE.A]elseif aF==19 then local aG=ae[at[aE.D+1] ]local aH=aG.nups local T=k(aH)as[aE.A]=am(an,aG,T)for U=1,aH do local V=au[ax]ax+=1 local W=V.A if W==0 then local X={value=as[V.B],index='value'}X.store=X T[U]=X elseif W==1 then local X=V.B local Y=ay[X]if Y==nil then Y={index=X,store=as}ay[X]=Y end T[U]=Y elseif W==2 then T[U]=ap[V.B+1]end end elseif aF==20 then local aG=aE.A local aH=aE.B local T=aE.K local U=as[aH]as[aG+1]=U ax+=1 local V=true local W=ad.useNativeNamecall if W then local X=ad.namecallHandler local Y=au[ax]local Z=Y.opcode local _,aI,aJ=Y.A,Y.B,Y.C if ah then ah(as,ar,ao,an,ap)end if ai then ai(as,ar,ao,an,ap)end local aK=if aI==0 then aw-_ else aI-1 local aL=i(X(T,j(as,_+1,_+aK)))if aL[1]==true then V=false ax+=1 aE=Y aF=Z ar.pc=ax ar.name=aE.opname m(aL,1)local aM=aL.n-1 if aJ==0 then aw=_+aM-1 else aM=aJ-1 end h(aL,1,aM,_,as)end end if V then as[aG]=U[T]end elseif aF==21 then if ai then ai(as,ar,ao,an,ap)end local aG,aH,aI=aE.A,aE.B,aE.C local aJ=if aH==0 then aw-aG else aH-1 local aK=as[aG]local aL=i(aK(j(as,aG+1,aG+aJ)))local aM=aL.n if aI==0 then aw=aG+aM-1 else aM=aI-1 end h(aL,1,aM,aG,as)elseif aF==22 then if ai then ai(as,ar,ao,an,ap)end local aG=aE.A local aH=aE.B local aI=aH-1 local aJ if aI==K then aJ=aw-aG+1 else aJ=aH-1 end return j(as,aG,aG+aJ-1)elseif aF==23 then ax+=aE.D elseif aF==24 then if ai then ai(as,ar,ao,an,ap)end ax+=aE.D elseif aF==25 then if as[aE.A]then ax+=aE.D end elseif aF==26 then if not as[aE.A]then ax+=aE.D end elseif aF==27 then if as[aE.A]==as[aE.aux]then ax+=aE.D else ax+=1 end elseif aF==28 then if as[aE.A]<=as[aE.aux]then ax+=aE.D else ax+=1 end elseif aF==29 then if as[aE.A]<as[aE.aux]then ax+=aE.D else ax+=1 end elseif aF==30 then if as[aE.A]==as[aE.aux]then ax+=1 else ax+=aE.D end elseif aF==31 then if as[aE.A]<=as[aE.aux]then ax+=1 else ax+=aE.D end elseif aF==32 then if as[aE.A]<as[aE.aux]then ax+=1 else ax+=aE.D end elseif aF==33 then as[aE.A]=as[aE.B]+as[aE.C]elseif aF==34 then as[aE.A]=as[aE.B]-as[aE.C]elseif aF==35 then as[aE.A]=as[aE.B]*as[aE.C]elseif aF==36 then as[aE.A]=as[aE.B]/as[aE.C]elseif aF==37 then as[aE.A]=as[aE.B]%as[aE.C]elseif aF==38 then as[aE.A]=as[aE.B]^as[aE.C]elseif aF==39 then as[aE.A]=as[aE.B]+aE.K elseif aF==40 then as[aE.A]=as[aE.B]-aE.K elseif aF==41 then as[aE.A]=as[aE.B]*aE.K elseif aF==42 then as[aE.A]=as[aE.B]/aE.K elseif aF==43 then as[aE.A]=as[aE.B]%aE.K elseif aF==44 then as[aE.A]=as[aE.B]^aE.K elseif aF==45 then local aG=as[aE.B]as[aE.A]=if aG then as[aE.C]or false else aG elseif aF==46 then local aG=as[aE.B]as[aE.A]=if aG then aG else as[aE.C]or false elseif aF==47 then local aG=as[aE.B]as[aE.A]=if aG then aE.K or false else aG elseif aF==48 then local aG=as[aE.B]as[aE.A]=if aG then aG else aE.K or false elseif aF==49 then local aG,aH=aE.B,aE.C local aI,aJ=b(n,as,'',aG,aH)if not aI then aJ=as[aG]for aK=aG+1,aH do aJ..=as[aK]end end as[aE.A]=aJ elseif aF==50 then as[aE.A]=not as[aE.B]elseif aF==51 then as[aE.A]=-as[aE.B]elseif aF==52 then as[aE.A]=#as[aE.B]elseif aF==53 then as[aE.A]=k(aE.aux)ax+=1 elseif aF==54 then local aG=aE.K local aH={}for aI,aJ in aG do aH[aA[aJ+1] ]=nil end as[aE.A]=aH elseif aF==55 then local aG=aE.A local aH=aE.B local aI=aE.C-1 if aI==K then aI=aw-aH+1 end h(as,aH,aH+aI-1,aE.aux,as[aG])ax+=1 elseif aF==56 then local aG=aE.A local aH=as[aG]if not F(aH)then local aI=d(aH)if aI==nil then c("invalid 'for' limit (number expected)")end as[aG]=aI aH=aI end local aI=as[aG+1]if not F(aI)then local aJ=d(aI)if aJ==nil then c("invalid 'for' step (number expected)")end as[aG+1]=aJ aI=aJ end local aJ=as[aG+2]if not F(aJ)then local aK=d(aJ)if aK==nil then c("invalid 'for' index (number expected)")end as[aG+2]=aK aJ=aK end if aI>0 then if not(aJ<=aH)then ax+=aE.D end else if not(aH<=aJ)then ax+=aE.D end end elseif aF==57 then if ai then ai(as,ar,ao,an,ap)end local aG=aE.A local aH=as[aG]local aI=as[aG+1]local aJ=as[aG+2]+aI as[aG+2]=aJ if aI>0 then if aJ<=aH then ax+=aE.D end else if aH<=aJ then ax+=aE.D end end elseif aF==58 then if ai then ai(as,ar,ao,an,ap)end local aG=aE.A local aH=aE.K aw=aG+6 local aI=as[aG]if(ad.generalizedIteration==false)or I(aI)then local aJ={aI(as[aG+1],as[aG+2])}h(aJ,1,aH,aG+3,as)if as[aG+3]~=nil then as[aG+2]=as[aG+3]ax+=aE.D else ax+=1 end else local aJ,aK=q(az[aE],aI,as[aG+1],as[aG+2])if not aJ then c(aK)end if aK==L then az[aE]=nil ax+=1 else h(aK,1,aH,aG+3,as)as[aG+2]=as[aG+3]ax+=aE.D end end elseif aF==59 then if not I(as[aE.A])then c(g('attempt to iterate over a %s value',a(as[aE.A])))end ax+=aE.D elseif aF==60 then ax+=1 elseif aF==61 then if not I(as[aE.A])then c(g('attempt to iterate over a %s value',a(as[aE.A])))end ax+=aE.D elseif aF==63 then local aG=aE.A local aH=aE.B-1 if aH==K then aH=av.len aw=aG+aH-1 end h(av.list,1,aH,aG,as)elseif aF==64 then local aG=ae[aE.K+1]local aH=aG.nups local aI=k(aH)as[aE.A]=am(an,aG,aI)for aJ=1,aH do local aK=au[ax]ax+=1 local aL=aK.A if aL==0 then local aM={value=as[aK.B],index='value'}aM.store=aM aI[aJ]=aM elseif aL==2 then aI[aJ]=ap[aK.B+1]end end elseif aF==65 then elseif aF==66 then local aG=aE.K as[aE.A]=aG ax+=1 elseif aF==67 then if ai then ai(as,ar,ao,an,ap)end ax+=aE.E elseif aF==68 then elseif aF==69 then aE.E+=1 elseif aF==70 then c('encountered unhandled CAPTURE')elseif aF==71 then as[aE.A]=aE.K-as[aE.C]elseif aF==72 then as[aE.A]=aE.K/as[aE.C]elseif aF==73 then elseif aF==74 then ax+=1 elseif aF==75 then ax+=1 elseif aF==76 then local aG=as[aE.A]if ad.generalizedIteration and not I(aG)then local aH=au[ax+aE.D]if az[aH]==nil then local function aI(...)for aJ,aK,aL,aM,T,U,V,W,X,Y,Z,_,aN,aO,aP,aQ,aR,aS,aT,aU,aV,aW,aX,aY,aZ,a_,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,ba,bb,bc,bd,be,bf,bg,bh,bi,bj,bk,bl,bm,bn,bo,bp,bq,br,bs,bt,bu,bv,bw,bx,by,bz,bA,bB,bC,bD,bE,bF,bG,bH,bI,bJ,bK,bL,bM,bN,bO,bP,bQ,bR,bS,bT,bU,bV,bW,bX,bY,bZ,b_,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,ca,cb,cc,cd,ce,cf,cg,ch,ci,cj,ck,cl,cm,cn,co,cp,cq,cr,cs,ct,cu,cv,cw,cx,cy,cz,cA,cB,cC,cD,cE,cF,cG,cH,cI,cJ,cK,cL,cM,cN,cO,cP,cQ,cR,cS,cT,cU,cV,cW,cX,cY,cZ,c_,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,da,db,dc,dd,de,df,dg,dh,di,dj,dk,dl,dm,dn,dp,dq,dr,ds,dt,du,dv,dw,dx,dy,dz,dA,dB,dC,dD,dE,dF,dG,dH,dI,dJ,dK,dL,dM in...do p({aJ,aK,aL,aM,T,U,V,W,X,Y,Z,_,aN,aO,aP,aQ,aR,aS,aT,aU,aV,aW,aX,aY,aZ,a_,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,ba,bb,bc,bd,be,bf,bg,bh,bi,bj,bk,bl,bm,bn,bo,bp,bq,br,bs,bt,bu,bv,bw,bx,by,bz,bA,bB,bC,bD,bE,bF,bG,bH,bI,bJ,bK,bL,bM,bN,bO,bP,bQ,bR,bS,bT,bU,bV,bW,bX,bY,bZ,b_,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,ca,cb,cc,cd,ce,cf,cg,ch,ci,cj,ck,cl,cm,cn,co,cp,cq,cr,cs,ct,cu,cv,cw,cx,cy,cz,cA,cB,cC,cD,cE,cF,cG,cH,cI,cJ,cK,cL,cM,cN,cO,cP,cQ,cR,cS,cT,cU,cV,cW,cX,cY,cZ,c_,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,da,db,dc,dd,de,df,dg,dh,di,dj,dk,dl,dm,dn,dp,dq,dr,ds,dt,du,dv,dw,dx,dy,dz,dA,dB,dC,dD,dE,dF,dG,dH,dI,dJ,dK,dL,dM})end p(L)end az[aH]=o(aI)end end ax+=aE.D elseif aF==77 then local aG=aE.KN if(as[aE.A]==nil)~=aG then ax+=aE.D else ax+=1 end elseif aF==78 then local aG=aE.K local aH=aE.KN local aI=as[aE.A]if(H(aI)and(aI==aG))~=aH then ax+=aE.D else ax+=1 end elseif aF==79 then local aG=aE.K local aH=aE.KN local aI=as[aE.A]if(aI==aG)~=aH then ax+=aE.D else ax+=1 end elseif aF==80 then local aG=aE.K local aH=aE.KN local aI=as[aE.A]if(aI==aG)~=aH then ax+=aE.D else ax+=1 end elseif aF==81 then as[aE.A]=as[aE.B]//as[aE.C]elseif aF==82 then as[aE.A]=as[aE.B]//aE.K else c('Unsupported Opcode: '..aE.opname..' op: '..aF)end end for aG,aH in ay do aH.value=aH.store[aH.index]aH.store=aH aH.index='value'ay[aG]=nil end for aG,aH in az do r(aH)az[aG]=nil end end local function ar(...)local as=i(...)local at=k(ao.maxstacksize)local au={len=0,list={}}h(as,1,ao.numparams,0,at)if ao.numparams<as.n then local av=ao.numparams+1 local aw=as.n-ao.numparams au.len=aw h(as,av,av+aw-1,1,au.list)end as=nil local av={pc=0,name='NONE'}local aw if ad.errorHandling then aw=i(b(aq,av,at,ao.protos,ao.code,au))else aw=i(true,aq(av,at,ao.protos,ao.code,au))end if aw[1]then return j(aw,2,aw.n)else local ax=aw[2]if aj then aj(ax,at,av,ao,an,ap)end if G(ax)==false then if ad.allowProxyErrors then c(ax)else ax=a(ax)end end if ao.lineinfoenabled then return c(g('Fiu VM Error { Name: %s Line: %s PC: %s Opcode: %s }: %s',ao.debugname,ao.instructionlineinfo[av.pc],av.pc,av.name,ax),0)else return c(g('Fiu VM Error { Name: %s PC: %s Opcode: %s }: %s',ao.debugname,av.pc,av.name,ax),0)end end end if ad.errorHandling then return ar else return aq end end return am(ab,af),al end return{luau_newsettings=M,luau_validatesettings=N,luau_deserialize=S,luau_load=aa,luau_getcoverage=Q}
end)()

local function log(...)
  print("[HYPERION]: ", ...)
end

local function majorError(msg)
  error("[HYPERION FATAL ERROR]: " .. tostring(msg) .. "\nReport this to our discord")
end

local debug = ... == true
if debug then log("DEBUG MODE ON") end

task.spawn(function()
  if debug then
    game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
  end
  if getgenv().hyperion and not debug then
    log("Hyperion already loaded.")
    return
  end
  log("INIT...")

  local cloneref = getgenv().cloneref or function(a) return a end
  if not getgenv().cloneref then
    print("[HYPERION]: Cloneref is not found. Using polyfill.")
  end

  local http     = cloneref(game:GetService("HttpService"))
  local tcs      = cloneref(game:GetService("TextChatService"))
  local localplr = cloneref(game:GetService("Players")).LocalPlayer

  local function assets(...)
    return table.concat({ "Hyperion", ... }, "/")
  end
  
  local gameDir = game.PlaceId == 108097274488844 and "og" or "normal"
  
  local Obsidian, Window, Helpers, tabs
  
  Helpers = {}
  do
    Helpers.log = log

    Helpers.selfchat = function(msg, noAdded)
      if noAdded then
        tcs.TextChannels.RBXGeneral:DisplaySystemMessage('<font color="rgb(255,0,0)">[HYPERION]: ' .. msg .. '</font>')
      else
        tcs.TextChannels.RBXGeneral:DisplaySystemMessage(msg)
      end
    end

    local pending_chat_check = {}
    local ChatListeners = {}

    tcs.OnIncomingMessage = function(msg)
      local props = Instance.new("TextChatMessageProperties")
      if not msg.TextSource then
        props.Text = msg.Text
        props.PrefixText = msg.PrefixText
        return props
      end
      task.spawn(function()
        for _, listener in ipairs(ChatListeners) do listener(msg) end
      end)
      if msg.Status ~= Enum.TextChatMessageStatus.Sending and pending_chat_check[msg.Text] == "" then
        pending_chat_check[msg.Text] = msg.Status == Enum.TextChatMessageStatus.Success
      end
      local player = Helpers.services.players:GetPlayerByUserId(msg.TextSource.UserId)
      local char = player and player.Character
      local label = char and char:FindFirstChild("Nombre") and char.Nombre:FindFirstChild("Text1")
      local color = label and label.TextColor3 or Color3.new(1, 1, 1)
      props.PrefixText = string.format("<font color='#%02X%02X%02X'>%s</font>",
        color.R * 255, color.G * 255, color.B * 255,
        player and player.DisplayName or msg.TextSource.Name)
      return props
    end

    Helpers.cmd = function(c, checkForSent)
      local tool = localplr.Backpack:FindFirstChild("The Arkenstone")
      if tool then
        tool.Parent = localplr.Character
      elseif not localplr.Character:FindFirstChild("The Arkenstone") then
        local cn = Helpers.services.players.Leaderboard:FindFirstChild("Chosen")
        if (not cn or cn:FindFirstChild(localplr.Name)) then return end
        log("SKIPPED CMD ", c, " no enli and not admin ")
        --return if no enli or admin
      end
      local cmd = ";" .. c .. " HYPERION REBORN"
      tcs.TextChannels.RBXGeneral:SendAsync(cmd)
      if checkForSent then
        pending_chat_check[cmd] = ""
        while pending_chat_check[cmd] == "" do
          task.wait(0.1)
        end
        local ref = pending_chat_check[cmd]
        pending_chat_check[cmd] = nil
        return ref
      end
    end

    Helpers.resolveName = function(name)
      return name:gsub("_", ".")
    end
    
    Helpers.say = function(text, checkForSent)
      tcs.TextChannels.RBXGeneral:SendAsync(text)
      if checkForSent then
        pending_chat_check[text] = ""
        while pending_chat_check[text] == "" do task.wait(0.1) end
        local ref = pending_chat_check[text]
        pending_chat_check[text] = nil
        return ref
      end
    end
    
    Helpers.on = function(type, func)
      if type == "ChatListener" then
        table.insert(ChatListeners, func)
      else
        log(type, " is not supported")
      end
    end
    
    Helpers.services = {
      players = cloneref(game:GetService("Players")),
      workspace = cloneref(game:GetService("Workspace")),
      run = cloneref(game:GetService("RunService")),
      userinput = cloneref(game:GetService("UserInputService")),
      textchat = tcs,
      coregui = cloneref(game:GetService("CoreGui")),
      http = http,
      tween = cloneref(game:GetService("TweenService")),
      replicated = cloneref(game:GetService("ReplicatedStorage")),
      collection = cloneref(game:GetService("CollectionService")),
      sound = cloneref(game:GetService("SoundService")),
      lighting = cloneref(game:GetService("Lighting")),
      debris = cloneref(game:GetService("Debris")),
      teams = cloneref(game:GetService("Teams")),
    }
  end
  
  makefolder("Hyperion")
  makefolder(assets("modules"))
  makefolder(assets("modules", "og"))
  makefolder(assets("modules", "normal"))
  makefolder(assets("modules", "loader"))
  makefolder(assets("cache"))
  
  task.spawn(function()
    local base = "https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/"
    local function createfile(url)
      local path = assets(url)
      if isfile(path) then return end
      writefile(path, game:HttpGet(base .. url))
    end
    createfile("hyperion_logo.jpg")
    createfile("discord_invite.txt")
  end)
  
  local k2, k2Failed
  task.spawn(function()
    local ok, result = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/key.txt")
    if ok then k2 = result else k2Failed = result end
  end)
  
  local function loadModule(path)
    local bin = readfile(path)
    local bytecode, err = aead.decrypt(
      "",
      sha3_256(bin:sub(17, 32) .. k2 .. "HYPERION@bS$l2Jul63@TU!^He;,Pg.9T6leH14O"),
      bin:sub(#bin - 11),
      bin:sub(#bin - 23, #bin - 12),
      bin:sub(33, #bin - 24),
      bin:sub(1, 16)
    )
    if not bytecode then error("decrypt failed (" .. path .. "): " .. tostring(err)) end
    local ok, fn = pcall(fiu.luau_load, bytecode, getgenv())
    if not ok then error("load failed: " .. tostring(fn)) end
    return fn({ Tabs = tabs, Window = Window, Obsidian = Obsidian, Assets = assets, Helpers = Helpers })
  end
  
  local uiReady        = false
  local gameDirReady   = false
  local gameDirPending = 0
  local gameDirListed  = false
  
  local function checkGameDirReady()
    if gameDirListed and gameDirPending <= 0 then gameDirReady = true end
  end
  
  log("Fetching modules...")
  task.spawn(function()
    local CACHE_PATH = assets("modules", ".sha_cache.json")
    local shaCache   = {}
    local ok, data   = pcall(function() return http:JSONDecode(readfile(CACHE_PATH)) end)
    if ok and type(data) == "table" then shaCache = data end
    
    local remoteNames       = {}
    local fetchSubdirs      = { gameDir, "loader" }
    local listingsRemaining = #fetchSubdirs
    local pending           = 0
    
    for _, subdir in ipairs(fetchSubdirs) do
      task.spawn(function()
        local fetched, result = pcall(function()
          return http:JSONDecode(game:HttpGet(
            "https://api.github.com/repos/Horizon-Developments/hyperion/contents/assets/" .. subdir
          ))
        end)
        if not fetched then
          log("Failed to fetch modules/" .. subdir, result)
          if subdir == "loader" then uiReady = true end
          if subdir == gameDir then
            gameDirListed = true
            checkGameDirReady()
          end
          listingsRemaining -= 1
          return
        end
        
        for _, item in ipairs(result) do
          if item.type ~= "file" then continue end
          if (not item.name:match("%.bin$") or not item.name:match("%.lua")) then continue end
          
          local cacheKey = subdir .. "/" .. item.name
          remoteNames[cacheKey] = true
          local isUiBin = subdir == "loader" and item.name == "ui.bin"
          
          if shaCache[cacheKey] == item.sha then
            log("Skipped " .. cacheKey)
            if isUiBin then uiReady = true end
            continue
          end
          
          pending += 1
          if subdir == gameDir then gameDirPending += 1 end
          task.spawn(function()
            local writeOk, writeErr = pcall(function()
              writefile(assets("modules", subdir, item.name), game:HttpGet(item.download_url))
              shaCache[cacheKey] = item.sha
            end)
            if not writeOk then log("Download failed: " .. cacheKey, writeErr) end
            if isUiBin then uiReady = true end
            pending -= 1
            if subdir == gameDir then
              gameDirPending -= 1
              checkGameDirReady()
            end
          end)
        end
        listingsRemaining -= 1
        if subdir == gameDir then
          gameDirListed = true
          checkGameDirReady()
        end
      end)
    end
    
    repeat task.wait() until listingsRemaining <= 0
    repeat task.wait() until pending <= 0
    
    if next(remoteNames) ~= nil then
      local fetchedSet = { [gameDir] = true, loader = true }
      for key in pairs(shaCache) do
        if remoteNames[key] then continue end
        local sub, filename = key:match("^([^/]+)/(.+)$")
        if sub and not fetchedSet[sub] then continue end -- subdir wasn't fetched this run, leave it alone
        if sub and filename then
          pcall(function() delfile(assets("modules", sub, filename)) end)
        end
        shaCache[key] = nil
        log("Deleted " .. key)
      end
    end
    
    pcall(function() writefile(CACHE_PATH, http:JSONEncode(shaCache)) end)
    uiReady = true
  end)
  
  log("Awaiting UI...")
  repeat task.wait() until (uiReady and k2) or k2Failed
  if k2Failed then majorError("Failed to fetch key.txt: " .. tostring(k2Failed)) end
  
  if not isfile(assets("modules", "loader", "ui.bin")) then
    majorError("File not found: modules/loader/ui.bin")
  end
  
  log("Loading UI...")
  
  local uiEnv = loadModule(assets("modules", "loader", "ui.bin"))
  tabs     = uiEnv.Tabs
  Window   = uiEnv.Window
  Obsidian = uiEnv.Obsidian
  
  local env = { Tabs = tabs, Window = Window, Obsidian = Obsidian, Assets = assets, Helpers = Helpers }
  
  log("Awaiting modules...")
  repeat task.wait() until gameDirReady
  
  log("Loading modules...")
  for _, file in ipairs(listfiles(assets("modules", gameDir))) do
    local name   = file:match("([^/\\]+)$")
    local loader
    if name:match("%.lua$") then
      loader = function()
        local fn, err = loadstring(readfile(file))
        if not fn then log("Failed to load ", name, " Err", err) end
        fn(env)
      end
    elseif name:match("%.bin$") then
      loader = function() 
        loadModule(file)
      end
    else
      log("Skipping unknown file: " .. name)
    end
    
    if loader then
      task.spawn(function()
        local ok, err = pcall(loader)
        if not ok then warn("[HYPERION]: module error:", name, err) end
      end)
    end
  end
end)