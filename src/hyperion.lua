local aead = (function()
  local a,b=table.insert,table.concat;local function c(d,e,f,g,h)local i,j,k,l=d[e],d[f],d[g],d[h]local m;i=i+j&0xffffffff;m=l~i;l=m<<16|(m>>16)&0xffffffff;k=k+l&0xffffffff;m=j~k;j=m<<12|(m>>20)&0xffffffff;i=i+j&0xffffffff;m=l~i;l=m<<8|(m>>24)&0xffffffff;k=k+l&0xffffffff;m=j~k;j=m<<7|(m>>25)&0xffffffff;d[e],d[f],d[g],d[h]=i,j,k,l;return d end;local n={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}local o={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}local p=function(q,r,s)local d=n;local t=o;d[1],d[2],d[3],d[4]=0x61707865,0x3320646e,0x79622d32,0x6b206574;for u=1,8 do d[u+4]=q[u]end;d[13]=r;for u=1,3 do d[u+13]=s[u]end;for u=1,16 do t[u]=d[u]end;for v=1,10 do c(t,1,5,9,13)c(t,2,6,10,14)c(t,3,7,11,15)c(t,4,8,12,16)c(t,1,6,11,16)c(t,2,7,12,13)c(t,3,8,9,14)c(t,4,5,10,15)end;for u=1,16 do d[u]=d[u]+t[u]&0xffffffff end;return d end;local w="<I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4"local function x(q,r,s,y,z)local A=#y-z+1;if A<64 then local B=string.sub(y,z)y=B..string.rep('\0',64-A)z=1 end;assert(#y>=64)local C=table.pack(string.unpack(w,y,z))local D=p(q,r,s)for u=1,16 do C[u]=C[u]~D[u]end;local E=string.pack(w,table.unpack(C))if A<64 then E=string.sub(E,1,A)end;return E end;local F=function(q,r,s,y)assert(r+#y//64+1<0xffffffff,"block counter must fit an uint32")assert(#q==32,"#key must be 32")assert(#s==12,"#nonce must be 12")local G=table.pack(string.unpack("<I4I4I4I4I4I4I4I4",q))local H=table.pack(string.unpack("<I4I4I4",s))local m={}local z=1;while z<=#y do a(m,x(G,r,H,y,z))z=z+64;r=r+1 end;local I=b(m)return I end;local function J(q,K)local G=table.pack(string.unpack("<I4I4I4I4I4I4I4I4",q))local H=table.pack(string.unpack("<I4I4I4I4",K))local d={}d[1],d[2],d[3],d[4]=0x61707865,0x3320646e,0x79622d32,0x6b206574;for u=1,8 do d[u+4]=G[u]end;for u=1,4 do d[u+12]=H[u]end;for v=1,10 do c(d,1,5,9,13)c(d,2,6,10,14)c(d,3,7,11,15)c(d,4,8,12,16)c(d,1,6,11,16)c(d,2,7,12,13)c(d,3,8,9,14)c(d,4,5,10,15)end;local L=string.pack("<I4I4I4I4I4I4I4I4",d[1],d[2],d[3],d[4],d[13],d[14],d[15],d[16])return L end;local function M(q,r,s,y)assert(#q==32,"#key must be 32")assert(#s==24,"#nonce must be 24")local L=J(q,s:sub(1,16))local N='\0\0\0\0'..s:sub(17)return F(L,r,N,y)end;local O={chacha20_encrypt=F,chacha20_decrypt=F,encrypt=F,decrypt=F,hchacha20=J,xchacha20_encrypt=M,xchacha20_decrypt=M,key_size=32,nonce_size=12,xnonce_size=24}local P=string.unpack;local function Q(R)local d={r={P('<I4',R,1)&0x3ffffff,P('<I4',R,4)>>2&0x3ffff03,P('<I4',R,7)>>4&0x3ffc0ff,P('<I4',R,10)>>6&0x3f03fff,P('<I4',R,13)>>8&0x00fffff},h={0,0,0,0,0},pad={P('<I4',R,17),P('<I4',R,21),P('<I4',R,25),P('<I4',R,29)},buffer="",leftover=0,final=false}return d end;local function S(d,T)local U=#T;local V=1;local W=d.final and 0 or 0x01000000;local X=d.r[1]local Y=d.r[2]local Z=d.r[3]local _=d.r[4]local a0=d.r[5]local a1=Y*5;local a2=Z*5;local a3=_*5;local a4=a0*5;local a5=d.h[1]local a6=d.h[2]local a7=d.h[3]local a8=d.h[4]local a9=d.h[5]local aa,ab,ac,ad,ae,k;while U>=16 do a5=a5+P('<I4',T,V)&0x3ffffff;a6=a6+P('<I4',T,V+3)>>2&0x3ffffff;a7=a7+P('<I4',T,V+6)>>4&0x3ffffff;a8=a8+P('<I4',T,V+9)>>6&0x3ffffff;a9=a9+P('<I4',T,V+12)>>8|W;aa=a5*X+a6*a4+a7*a3+a8*a2+a9*a1;ab=a5*Y+a6*X+a7*a4+a8*a3+a9*a2;ac=a5*Z+a6*Y+a7*X+a8*a4+a9*a3;ad=a5*_+a6*Z+a7*Y+a8*X+a9*a4;ae=a5*a0+a6*_+a7*Z+a8*Y+a9*X;k=aa>>26&0xffffffff;a5=aa&0x3ffffff;ab=ab+k;k=ab>>26&0xffffffff;a6=ab&0x3ffffff;ac=ac+k;k=ac>>26&0xffffffff;a7=ac&0x3ffffff;ad=ad+k;k=ad>>26&0xffffffff;a8=ad&0x3ffffff;ae=ae+k;k=ae>>26&0xffffffff;a9=ae&0x3ffffff;a5=a5+k*5;k=a5>>26;a5=a5&0x3ffffff;a6=a6+k;V=V+16;U=U-16 end;d.h[1]=a5;d.h[2]=a6;d.h[3]=a7;d.h[4]=a8;d.h[5]=a9;d.bytes=U;d.midx=V;return d end;local function af(d,T)d.bytes,d.midx=#T,1;if d.bytes>=16 then S(d,T)end;if d.bytes==0 then else local ag=string.sub(T,d.midx)..'\x01'..string.rep('\0',16-d.bytes-1)assert(#ag==16)d.final=true;S(d,ag)end;return d end;local function ah(d)local k,ai;local aj;local a5=d.h[1]local a6=d.h[2]local a7=d.h[3]local a8=d.h[4]local a9=d.h[5]k=a6>>26;a6=a6&0x3ffffff;a7=a7+k;k=a7>>26;a7=a7&0x3ffffff;a8=a8+k;k=a8>>26;a8=a8&0x3ffffff;a9=a9+k;k=a9>>26;a9=a9&0x3ffffff;a5=a5+k*5;k=a5>>26;a5=a5&0x3ffffff;a6=a6+k;local ak=a5+5;k=ak>>26;ak=ak&0x3ffffff;local al=a6+k;k=al>>26;al=al&0x3ffffff;local am=a7+k;k=am>>26;am=am&0x3ffffff;local an=a8+k;k=an>>26;an=an&0x3ffffff;local ao=a9+k-0x4000000&0xffffffff;ai=ao>>31-1&0xffffffff;ak=ak&ai;al=al&ai;am=am&ai;an=an&ai;ao=ao&ai;ai=~ai&0xffffffff;a5=a5&ai|ak;a6=a6&ai|al;a7=a7&ai|am;a8=a8&ai|an;a9=a9&ai|ao;a5=a5|(a6<<26)&0xffffffff;a6=a6>>6|(a7<<20)&0xffffffff;a7=a7>>12|(a8<<14)&0xffffffff;a8=a8>>18|(a9<<8)&0xffffffff;aj=a5+d.pad[1]a5=aj&0xffffffff;aj=a6+d.pad[2]+aj>>32;a6=aj&0xffffffff;aj=a7+d.pad[3]+aj>>32;a7=aj&0xffffffff;aj=a8+d.pad[4]+aj>>32;a8=aj&0xffffffff;local ap=string.pack('<I4I4I4I4',a5,a6,a7,a8)return ap end;local function aq(T,R)assert(#R==32)local d=Q(R)af(d,T)local ap=ah(d)return ap end;local function ar(T,R,ap)local as=aq(T,R)return as==ap end;local at={init=Q,update=af,finish=ah,auth=aq,verify=ar}local au=function(q,s)local r=0;local T=string.rep('\0',64)local av=O.encrypt(q,r,s,T)return av:sub(1,32)end;local aw=function(ax)return#ax%16==0 and""or'\0':rep(16-#ax%16)end;local a=table.insert;local ay=function(az,q,aA,aB,aC)local aD={}local s=aB..aA;local aE=au(q,s)local aF=O.encrypt(q,1,s,aC)a(aD,az)a(aD,aw(az))a(aD,aF)a(aD,aw(aF))a(aD,string.pack('<I8',#az))a(aD,string.pack('<I8',#aF))local aG=table.concat(aD)local aH=at.auth(aG,aE)return aF,aH end;local function aI(az,q,aA,aB,aF,aH)local aD={}local s=aB..aA;local aE=au(q,s)a(aD,az)a(aD,aw(az))a(aD,aF)a(aD,aw(aF))a(aD,string.pack('<I8',#az))a(aD,string.pack('<I8',#aF))local aG=table.concat(aD)local ap=at.auth(aG,aE)if ap==aH then local aC=O.encrypt(q,1,s,aF)return aC else return nil,"auth failed"end end;
  return{poly_keygen=au,encrypt=ay,decrypt=aI}
end)()
local sha3 = (function()
  local a=string.char;local b=table.concat;local c,d=string.pack,string.unpack;local e=24;local f={0x0000000000000001,0x0000000000008082,0x800000000000808A,0x8000000080008000,0x000000000000808B,0x0000000080000001,0x8000000080008081,0x8000000000008009,0x000000000000008A,0x0000000000000088,0x0000000080008009,0x000000008000000A,0x000000008000808B,0x800000000000008B,0x8000000000008089,0x8000000000008003,0x8000000000008002,0x8000000000000080,0x000000000000800A,0x800000008000000A,0x8000000080008081,0x8000000000008080,0x0000000080000001,0x8000000080008008}local g={{0,36,3,41,18},{1,44,10,45,2},{62,6,43,15,61},{28,55,25,21,56},{27,20,39,8,14}}local function h(i)local j=i.permuted;local k=i.parities;for l=1,e do for m=1,5 do k[m]=0;local n=i[m]for o=1,5 do k[m]=k[m]~n[o]end end;local p,q,r;p=k[2]q=k[5]~(p<<1|(p>>63))r=i[1]for o=1,5 do r[o]=r[o]~q end;p=k[3]q=k[1]~(p<<1|(p>>63))r=i[2]for o=1,5 do r[o]=r[o]~q end;p=k[4]q=k[2]~(p<<1|(p>>63))r=i[3]for o=1,5 do r[o]=r[o]~q end;p=k[5]q=k[3]~(p<<1|(p>>63))r=i[4]for o=1,5 do r[o]=r[o]~q end;p=k[1]q=k[4]~(p<<1|(p>>63))r=i[5]for o=1,5 do r[o]=r[o]~q end;for o=1,5 do local s=j[o]local t;for m=1,5 do r,t=i[m][o],g[m][o]s[(2*m+3*o)%5+1]=r<<t|(r>>64-t)end end;local u,v,w;r,u,v,w=i[1],j[1],j[2],j[3]for o=1,5 do r[o]=u[o]~(~v[o]&w[o])end;r,u,v,w=i[2],j[2],j[3],j[4]for o=1,5 do r[o]=u[o]~(~v[o]&w[o])end;r,u,v,w=i[3],j[3],j[4],j[5]for o=1,5 do r[o]=u[o]~(~v[o]&w[o])end;r,u,v,w=i[4],j[4],j[5],j[1]for o=1,5 do r[o]=u[o]~(~v[o]&w[o])end;r,u,v,w=i[5],j[5],j[1],j[2]for o=1,5 do r[o]=u[o]~(~v[o]&w[o])end;i[1][1]=i[1][1]~f[l]end end;local function x(i,y)local z=i.rate/8;local A=z/8;local B=#y+1;y=y..'\x06'..a(0):rep(z-B%z)B=#y;local C={}for D=1,B-B%8,8 do C[#C+1]=d('<I8',y,D)end;local E=#C;C[E]=C[E]|0x8000000000000000;for F=1,E,A do local G=0;for o=1,5 do for m=1,5 do if G<A then local H=F+G;i[m][o]=i[m][o]~C[H]G=G+1 end end end;h(i)end end;local function I(i)local z=i.rate/8;local A=z/4;local J={}local G=1;for o=1,5 do for m=1,5 do if G<A then J[G]=c("<I8",i[m][o])G=G+1 end end end;return b(J)end;local function K(L,M,N)local O={{0,0,0,0,0},{0,0,0,0,0},{0,0,0,0,0},{0,0,0,0,0},{0,0,0,0,0}}O.rate=L;O.permuted={{},{},{},{},{}}O.parities={0,0,0,0,0}x(O,N)return I(O):sub(1,M/8)end;local function P(N)return K(1088,256,N)end;local function Q(N)return K(576,512,N)end;
  return{sha256=P,sha512=Q}
end)()
local fiu = (function()
  local type=type local pcall=pcall local error=error local tonumber=tonumber local assert=assert local setmetatable=setmetatablelocal string_format=string.formatlocal table_move=table.move local table_pack=table.pack local table_unpack=table.unpack local table_create=table.create local table_insert=table.insert local table_remove=table.remove local table_concat=table.concatlocal coroutine_create=coroutine.create local coroutine_yield=coroutine.yield local coroutine_resume=coroutine.resume local coroutine_close=coroutine.closelocal buffer_fromstring=buffer.fromstring local buffer_len=buffer.len local buffer_readu8=buffer.readu8 local buffer_readu32=buffer.readu32 local buffer_readstring=buffer.readstring local buffer_readf32=buffer.readf32 local buffer_readf64=buffer.readf64local bit32_bor=bit32.bor local bit32_band=bit32.band local bit32_btest=bit32.btest local bit32_rshift=bit32.rshift local bit32_lshift=bit32.lshift local bit32_extract=bit32.extractlocal ttisnumber=function (v)return type(v)=="number" end local ttisstring=function (v)return type(v)=="string" end local ttisboolean=function (v)return type(v)=="boolean" end local ttisfunction=function (v)return type(v)=="function " endlocal opList={{"NOP",0,0,false},{"BREAK",0,0,false},{"LOADNIL",1,0,false},{"LOADB",3,0,false},{"LOADN",4,0,false},{"LOADK",4,3,false},{"MOVE",2,0,false},{"GETGLOBAL",1,1,true},{"SETGLOBAL",1,1,true},{"GETUPVAL",2,0,false},{"SETUPVAL",2,0,false},{"CLOSEUPVALS",1,0,false},{"GETIMPORT",4,4,true},{"GETTABLE",3,0,false},{"SETTABLE",3,0,false},{"GETTABLEKS",3,1,true},{"SETTABLEKS",3,1,true},{"GETTABLEN",3,0,false},{"SETTABLEN",3,0,false},{"NEWCLOSURE",4,0,false},{"NAMECALL",3,1,true},{"CALL",3,0,false},{"RETURN",2,0,false},{"JUMP",4,0,false},{"JUMPBACK",4,0,false},{"JUMPIF",4,0,false},{"JUMPIFNOT",4,0,false},{"JUMPIFEQ",4,0,true},{"JUMPIFLE",4,0,true},{"JUMPIFLT",4,0,true},{"JUMPIFNOTEQ",4,0,true},{"JUMPIFNOTLE",4,0,true},{"JUMPIFNOTLT",4,0,true},{"ADD",3,0,false},{"SUB",3,0,false},{"MUL",3,0,false},{"DIV",3,0,false},{"MOD",3,0,false},{"POW",3,0,false},{"ADDK",3,2,false},{"SUBK",3,2,false},{"MULK",3,2,false},{"DIVK",3,2,false},{"MODK",3,2,false},{"POWK",3,2,false},{"AND",3,0,false},{"OR",3,0,false},{"ANDK",3,2,false},{"ORK",3,2,false},{"CONCAT",3,0,false},{"NOT",2,0,false},{"MINUS",2,0,false},{"LENGTH",2,0,false},{"NEWTABLE",2,0,true},{"DUPTABLE",4,3,false},{"SETLIST",3,0,true},{"FORNPREP",4,0,false},{"FORNLOOP",4,0,false},{"FORGLOOP",4,8,true},{"FORGPREP_INEXT",4,0,false},{"FASTCALL3",3,1,true},{"FORGPREP_NEXT",4,0,false},{"DEP_FORGLOOP_NEXT",0,0,false},{"GETVARARGS",2,0,false},{"DUPCLOSURE",4,3,false},{"PREPVARARGS",1,0,false},{"LOADKX",1,1,true},{"JUMPX",5,0,false},{"FASTCALL",3,0,false},{"COVERAGE",5,0,false},{"CAPTURE",2,0,false},{"SUBRK",3,7,false},{"DIVRK",3,7,false},{"FASTCALL1",3,0,false},{"FASTCALL2",3,0,true},{"FASTCALL2K",3,1,true},{"FORGPREP",4,0,false},{"JUMPXEQKNIL",4,5,true},{"JUMPXEQKB",4,5,true},{"JUMPXEQKN",4,6,true},{"JUMPXEQKS",4,6,true},{"IDIV",3,0,false},{"IDIVK",3,2,false},}local LUA_MULTRET=-1 local LUA_GENERALIZED_TERMINATOR=-2local function luau_newsettings()return {vectorCtor=function ()error("vectorCtor was not provided")end ,vectorSize=4,useNativeNamecall=false,namecallHandler=function ()error("Native __namecall handler was not provided")end ,extensions={},callHooks={},errorHandling=true,generalizedIteration=true,allowProxyErrors=false,useImportConstants=false,staticEnvironment={},decodeOp=function (op)return op end}endlocal function luau_validatesettings(luau_settings)assert(type(luau_settings)=="table","luau_settings should be a table")assert(type(luau_settings.vectorCtor)=="function ","luau_settings.vectorCtor should be a function ")assert(type(luau_settings.vectorSize)=="number","luau_settings.vectorSize should be a number")assert(type(luau_settings.useNativeNamecall)=="boolean","luau_settings.useNativeNamecall should be a boolean")assert(type(luau_settings.namecallHandler)=="function ","luau_settings.namecallHandler should be a function ")assert(type(luau_settings.extensions)=="table","luau_settings.extensions should be a table of functions")assert(type(luau_settings.callHooks)=="table","luau_settings.callHooks should be a table of functions")assert(type(luau_settings.errorHandling)=="boolean","luau_settings.errorHandling should be a boolean")assert(type(luau_settings.generalizedIteration)=="boolean","luau_settings.generalizedIteration should be a boolean")assert(type(luau_settings.allowProxyErrors)=="boolean","luau_settings.allowProxyErrors should be a boolean")assert(type(luau_settings.staticEnvironment)=="table","luau_settings.staticEnvironment should be a table")assert(type(luau_settings.useImportConstants)=="boolean","luau_settings.useImportConstants should be a boolean")assert(type(luau_settings.decodeOp)=="function ","luau_settings.decodeOp should be a function ")endlocal function getmaxline(module,protoid)local proto=if (protoid==nil)then module.mainProto else module.protoList[protoid]local size=-1 assert(proto.lineinfoenabled,"proto must have debug enabled")for pc=1,proto.sizecode do local line=proto.instructionlineinfo[pc]size=if (line>size)then line else size endfor i,subid in proto.protos do local maxline=getmaxline(module,subid)size=if (maxline>size)then maxline else size endreturn size endlocal function getcoverage(module,protoid,depth,callback,size)local proto=if (protoid==nil)then module.mainProto else module.protoList[protoid]assert(proto.lineinfoenabled,"proto must have debug enabled")local buffer={}for pc=1,proto.sizecode do local inst=proto.code[pc]local line=proto.instructionlineinfo[pc]if (inst.opcode ~=69)then continue endlocal hits=inst.Ebuffer[line]=if ((buffer[line]or 0)>hits)then buffer[line]else hits endcallback(proto.debugname,proto.linedefined,depth,buffer,size)for i,subid in proto.protos do getcoverage(module,subid,depth+1,callback,size)end endlocal function luau_getcoverage(module,protoid,callback)assert(type(module)=="table","module must be a table")assert(type(protoid)=="number" or type(protoid)=="nil","protoid must be a number or nil")assert(type(callback)=="function ","callback must be a function ")getcoverage(module,protoid,0,callback,getmaxline(module))endlocal function resolveImportConstant(static,count,k0,k1,k2)local res=static[k0]if count<2 or res==nil then return res end res=res[k1]if count<3 or res==nil then return res end res=res[k2]return res endlocal function luau_deserialize(bytecode,luau_settings)if luau_settings==nil then luau_settings=luau_newsettings()else luau_validatesettings(luau_settings)endlocal stream=if type(bytecode)=="string" then buffer_fromstring(bytecode)else bytecode local cursor=0local function readByte()local byte=buffer_readu8(stream,cursor)cursor=cursor+1 return byte endlocal function readWord()local word=buffer_readu32(stream,cursor)cursor=cursor+4 return word endlocal function readFloat()local float=buffer_readf32(stream,cursor)cursor=cursor+4 return float endlocal function readDouble()local double=buffer_readf64(stream,cursor)cursor=cursor+8 return double endlocal function readVarInt()local result=0for i=0,4 do local value=readByte()result=bit32_bor(result,bit32_lshift(bit32_band(value,0x7F),i*7))if not bit32_btest(value,0x80)then break end endreturn result endlocal function readString()local size=readVarInt()if size==0 then return "" else local str=buffer_readstring(stream,cursor,size)cursor=cursor+sizereturn str end endlocal luauVersion=readByte()local typesVersion=0 if luauVersion==0 then error("the provided bytecode is an error message",0)elseif luauVersion<3 or luauVersion>6 then error("the version of the provided bytecode is unsupported",0)elseif luauVersion>=4 then typesVersion=readByte()endlocal stringCount=readVarInt()local stringList=table_create(stringCount)for i=1,stringCount do stringList[i]=readString()endlocal function readInstruction(codeList)local value=readWord()local opcode=bit32_band(luau_settings.decodeOp(value),0xFF)local opinfo=opList[opcode+1]local opname=opinfo[1]local opmode=opinfo[2]local kmode=opinfo[3]local usesAux=opinfo[4]local inst={opcode=opcode;opname=opname;opmode=opmode;kmode=kmode;usesAux=usesAux;}table_insert(codeList,inst)if opmode==1 then inst.A=bit32_band(bit32_rshift(value,8),0xFF)elseif opmode==2 then inst.A=bit32_band(bit32_rshift(value,8),0xFF)inst.B=bit32_band(bit32_rshift(value,16),0xFF)elseif opmode==3 then inst.A=bit32_band(bit32_rshift(value,8),0xFF)inst.B=bit32_band(bit32_rshift(value,16),0xFF)inst.C=bit32_band(bit32_rshift(value,24),0xFF)elseif opmode==4 then inst.A=bit32_band(bit32_rshift(value,8),0xFF)local temp=bit32_band(bit32_rshift(value,16),0xFFFF)inst.D=if temp<0x8000 then temp else temp-0x10000 elseif opmode==5 then local temp=bit32_band(bit32_rshift(value,8),0xFFFFFF)inst.E=if temp<0x800000 then temp else temp-0x1000000 endif usesAux then local aux=readWord()inst.aux=auxtable_insert(codeList,{value=aux,opname="auxvalue"})endreturn usesAux endlocal function checkkmode(inst,k)local kmode=inst.kmodeif kmode==1 then inst.K=k[inst.aux+1]elseif kmode==2 then inst.K=k[inst.C+1]elseif kmode==3 then inst.K=k[inst.D+1]elseif kmode==4 then local extend=inst.aux local count=bit32_rshift(extend,30)local id0=bit32_band(bit32_rshift(extend,20),0x3FF)inst.K0=k[id0+1]inst.KC=count if count==2 then local id1=bit32_band(bit32_rshift(extend,10),0x3FF)inst.K1=k[id1+1]elseif count==3 then local id1=bit32_band(bit32_rshift(extend,10),0x3FF)local id2=bit32_band(bit32_rshift(extend,0),0x3FF)inst.K1=k[id1+1]inst.K2=k[id2+1]end if luau_settings.useImportConstants then inst.K=resolveImportConstant(luau_settings.staticEnvironment,count,inst.K0,inst.K1,inst.K2)end elseif kmode==5 then inst.K=bit32_extract(inst.aux,0,1)==1 inst.KN=bit32_extract(inst.aux,31,1)==1 elseif kmode==6 then inst.K=k[bit32_extract(inst.aux,0,24)+1]inst.KN=bit32_extract(inst.aux,31,1)==1 elseif kmode==7 then inst.K=k[inst.B+1]elseif kmode==8 then inst.K=bit32_band(inst.aux,0xf)end endlocal function readProto(bytecodeid)local maxstacksize=readByte()local numparams=readByte()local nups=readByte()local isvararg=readByte()~=0if luauVersion>=4 then readByte()local typesize=readVarInt();cursor=cursor+typesize;endlocal sizecode=readVarInt()local codelist=table_create(sizecode)local skipnext=false for i=1,sizecode do if skipnext then skipnext=false continue endskipnext=readInstruction(codelist)end local debugcodelist=table_create(sizecode)for i=1,sizecode do debugcodelist[i]=codelist[i].opcode endlocal sizek=readVarInt()local klist=table_create(sizek)for i=1,sizek do local kt=readByte()local kif kt==0 then k=nil elseif kt==1 then k=readByte()~=0 elseif kt==2 then k=readDouble()elseif kt==3 then k=stringList[readVarInt()]elseif kt==4 then k=readWord()elseif kt==5 then local dataLength=readVarInt()k=table_create(dataLength)for i=1,dataLength do k[i]=readVarInt()end elseif kt==6 then k=readVarInt()elseif kt==7 then local x,y,z,w=readFloat(),readFloat(),readFloat(),readFloat()if luau_settings.vectorSize==4 then k=luau_settings.vectorCtor(x,y,z,w)else k=luau_settings.vectorCtor(x,y,z)end endklist[i]=k end for i=1,sizecode do checkkmode(codelist[i],klist)endlocal sizep=readVarInt()local protolist=table_create(sizep)for i=1,sizep do protolist[i]=readVarInt()+1 endlocal linedefined=readVarInt()local debugnameindex=readVarInt()local debugnameif debugnameindex ~=0 then debugname=stringList[debugnameindex]else debugname="(??)" end local lineinfoenabled=readByte()~=0 local instructionlineinfo=nilif lineinfoenabled then local linegaplog2=readByte()local intervals=bit32_rshift((sizecode-1),linegaplog2)+1local lineinfo=table_create(sizecode)local abslineinfo=table_create(intervals)local lastoffset=0 for j=1,sizecode do lastoffset+=readByte()lineinfo[j]=lastoffset endlocal lastline=0 for j=1,intervals do lastline+=readWord()abslineinfo[j]=lastline %(2 ^ 32)endinstructionlineinfo=table_create(sizecode)for i=1,sizecode do table_insert(instructionlineinfo,abslineinfo[bit32_rshift(i-1,linegaplog2)+1]+lineinfo[i])end end if readByte()~=0 then local sizel=readVarInt()for i=1,sizel do readVarInt()readVarInt()readVarInt()readByte()end local sizeupvalues=readVarInt()for i=1,sizeupvalues do readVarInt()end endreturn{maxstacksize=maxstacksize;numparams=numparams;nups=nups;isvararg=isvararg;linedefined=linedefined;debugname=debugname;sizecode=sizecode;code=codelist;debugcode=debugcodelist;sizek=sizek;k=klist;sizep=sizep;protos=protolist;lineinfoenabled=lineinfoenabled;instructionlineinfo=instructionlineinfo;bytecodeid=bytecodeid;}end if typesVersion==3 then local index=readByte()while index ~=0 do readVarInt()index=readByte()end endlocal protoCount=readVarInt()local protoList=table_create(protoCount)for i=1,protoCount do protoList[i]=readProto(i-1)endlocal mainProto=protoList[readVarInt()+1]assert(cursor==buffer_len(stream),"deserializer cursor position mismatch")mainProto.debugname="(main)"return {stringList=stringList;protoList=protoList;mainProto=mainProto;typesVersion=typesVersion;}endlocal function luau_load(module,env,luau_settings)if luau_settings==nil then luau_settings=luau_newsettings()else luau_validatesettings(luau_settings)endif type(module)~="table" then module=luau_deserialize(module,luau_settings)endlocal protolist=module.protoList local mainProto=module.mainProtolocal breakHook=luau_settings.callHooks.breakHook local stepHook=luau_settings.callHooks.stepHook local interruptHook=luau_settings.callHooks.interruptHook local panicHook=luau_settings.callHooks.panicHooklocal alive=truelocal function luau_close()alive=false endlocal function luau_wrapclosure(module,proto,upvals)local function luau_execute(...)local debugging,stack,protos,code,varargs if luau_settings.errorHandling then debugging,stack,protos,code,varargs=... else local passed=table_pack(...)stack=table_create(proto.maxstacksize)varargs={len=0,list={},}table_move(passed,1,proto.numparams,0,stack)if proto.numparams<passed.n then local start=proto.numparams+1 local len=passed.n-proto.numparams varargs.len=len table_move(passed,start,start+len-1,1,varargs.list)end passed=nil debugging={pc=0,name="NONE"}protos=proto.protos code=proto.code endlocal top,pc,open_upvalues,generalized_iterators=-1,1,setmetatable({},{__mode="vs"}),setmetatable({},{__mode="ks"})local constants=proto.k local debugopcodes=proto.debugcode local extensions=luau_settings.extensionslocal handlingBreak=false local inst,op while alive do if not handlingBreak then inst=code[pc]op=inst.opcode endhandlingBreak=falsedebugging.pc=pc debugging.top=top debugging.name=inst.opnamepc+=1if stepHook then stepHook(stack,debugging,proto,module,upvals)endif op==0 then elseif op==1 then if breakHook then local results=table.pack(breakHook(stack,debugging,proto,module,upvals))if results[1]then return table_unpack(results,2,#results)end end pc-=1 op=debugopcodes[pc]handlingBreak=true elseif op==2 then stack[inst.A]=nil elseif op==3 then stack[inst.A]=inst.B==1 pc+=inst.C elseif op==4 then stack[inst.A]=inst.D elseif op==5 then stack[inst.A]=inst.K elseif op==6 then stack[inst.A]=stack[inst.B]elseif op==7 then local kv=inst.Kstack[inst.A]=extensions[kv]or env[kv]pc+=1 elseif op==8 then local kv=inst.K env[kv]=stack[inst.A]pc+=1 elseif op==9 then local uv=upvals[inst.B+1]stack[inst.A]=uv.store[uv.index]elseif op==10 then local uv=upvals[inst.B+1]uv.store[uv.index]=stack[inst.A]elseif op==11 then for i,uv in open_upvalues do if uv.index>=inst.A then uv.value=uv.store[uv.index]uv.store=uv uv.index="value" open_upvalues[i]=nil end end elseif op==12 then if luau_settings.useImportConstants then stack[inst.A]=inst.K else local count=inst.KC local k0=inst.K0 local import=extensions[k0]or env[k0]if count==1 then stack[inst.A]=import elseif count==2 then stack[inst.A]=import[inst.K1]elseif count==3 then stack[inst.A]=import[inst.K1][inst.K2]end endpc+=1 elseif op==13 then stack[inst.A]=stack[inst.B][stack[inst.C]]elseif op==14 then stack[inst.B][stack[inst.C]]=stack[inst.A]elseif op==15 then local index=inst.K stack[inst.A]=stack[inst.B][index]pc+=1 elseif op==16 then local index=inst.K stack[inst.B][index]=stack[inst.A]pc+=1 elseif op==17 then stack[inst.A]=stack[inst.B][inst.C+1]elseif op==18 then stack[inst.B][inst.C+1]=stack[inst.A]elseif op==19 then local newPrototype=protolist[protos[inst.D+1]]local nups=newPrototype.nups local upvalues=table_create(nups)stack[inst.A]=luau_wrapclosure(module,newPrototype,upvalues)for i=1,nups do local pseudo=code[pc]pc+=1local type=pseudo.Aif type==0 then local upvalue={value=stack[pseudo.B],index="value",}upvalue.store=upvalueupvalues[i]=upvalue elseif type==1 then local index=pseudo.B local prev=open_upvalues[index]if prev==nil then prev={index=index,store=stack,}open_upvalues[index]=prev endupvalues[i]=prev elseif type==2 then upvalues[i]=upvals[pseudo.B+1]end end elseif op==20 then local A=inst.A local B=inst.Blocal kv=inst.K local sb=stack[B]stack[A+1]=sb pc+=1 local useFallback=true local useNativeHandler=luau_settings.useNativeNamecallif useNativeHandler then local nativeNamecall=luau_settings.namecallHandlerlocal callInst=code[pc]local callOp=callInst.opcode local callA,callB,callC=callInst.A,callInst.B,callInst.Cif stepHook then stepHook(stack,debugging,proto,module,upvals)endif interruptHook then interruptHook(stack,debugging,proto,module,upvals)endlocal params=if callB==0 then top-callA else callB-1 local ret_list=table_pack(nativeNamecall(kv,table_unpack(stack,callA+1,callA+params)))if ret_list[1]==true then useFallback=false pc+=1inst=callInst op=callOp debugging.pc=pc debugging.name=inst.opnametable_remove(ret_list,1)local ret_num=ret_list.n-1if callC==0 then top=callA+ret_num-1 else ret_num=callC-1 endtable_move(ret_list,1,ret_num,callA,stack)end end if useFallback then stack[A]=sb[kv]end elseif op==21 then if interruptHook then interruptHook(stack,debugging,proto,module,upvals)endlocal A,B,C=inst.A,inst.B,inst.Clocal params=if B==0 then top-A else B-1 local func=stack[A]local ret_list=table_pack(func(table_unpack(stack,A+1,A+params)))local ret_num=ret_list.nif C==0 then top=A+ret_num-1 else ret_num=C-1 endtable_move(ret_list,1,ret_num,A,stack)elseif op==22 then if interruptHook then interruptHook(stack,debugging,proto,module,upvals)endlocal A=inst.A local B=inst.B local b=B-1 local nresultsif b==LUA_MULTRET then nresults=top-A+1 else nresults=B-1 endreturn table_unpack(stack,A,A+nresults-1)elseif op==23 then pc+=inst.D elseif op==24 then if interruptHook then interruptHook(stack,debugging,proto,module,upvals)endpc+=inst.D elseif op==25 then if stack[inst.A]then pc+=inst.D end elseif op==26 then if not stack[inst.A]then pc+=inst.D end elseif op==27 then if stack[inst.A]==stack[inst.aux]then pc+=inst.D else pc+=1 end elseif op==28 then if stack[inst.A]<=stack[inst.aux]then pc+=inst.D else pc+=1 end elseif op==29 then if stack[inst.A]<stack[inst.aux]then pc+=inst.D else pc+=1 end elseif op==30 then if stack[inst.A]==stack[inst.aux]then pc+=1 else pc+=inst.D end elseif op==31 then if stack[inst.A]<=stack[inst.aux]then pc+=1 else pc+=inst.D end elseif op==32 then if stack[inst.A]<stack[inst.aux]then pc+=1 else pc+=inst.D end elseif op==33 then stack[inst.A]=stack[inst.B]+stack[inst.C]elseif op==34 then stack[inst.A]=stack[inst.B]-stack[inst.C]elseif op==35 then stack[inst.A]=stack[inst.B]*stack[inst.C]elseif op==36 then stack[inst.A]=stack[inst.B]/stack[inst.C]elseif op==37 then stack[inst.A]=stack[inst.B]% stack[inst.C]elseif op==38 then stack[inst.A]=stack[inst.B]^ stack[inst.C]elseif op==39 then stack[inst.A]=stack[inst.B]+inst.K elseif op==40 then stack[inst.A]=stack[inst.B]-inst.K elseif op==41 then stack[inst.A]=stack[inst.B]*inst.K elseif op==42 then stack[inst.A]=stack[inst.B]/inst.K elseif op==43 then stack[inst.A]=stack[inst.B]% inst.K elseif op==44 then stack[inst.A]=stack[inst.B]^ inst.K elseif op==45 then local value=stack[inst.B]stack[inst.A]=if value then stack[inst.C]or false else value elseif op==46 then local value=stack[inst.B]stack[inst.A]=if value then value else stack[inst.C]or false elseif op==47 then local value=stack[inst.B]stack[inst.A]=if value then inst.K or false else value elseif op==48 then local value=stack[inst.B]stack[inst.A]=if value then value else inst.K or false elseif op==49 then local B,C=inst.B,inst.C local success,s=pcall(table_concat,stack,"",B,C)if not success then s=stack[B]for i=B+1,C do s ..=stack[i]end endstack[inst.A]=s elseif op==50 then stack[inst.A]=not stack[inst.B]elseif op==51 then stack[inst.A]=-stack[inst.B]elseif op==52 then stack[inst.A]=#stack[inst.B]elseif op==53 then stack[inst.A]=table_create(inst.aux)pc+=1 elseif op==54 then local template=inst.K local serialized={}for _,id in template do serialized[constants[id+1]]=nil end stack[inst.A]=serialized elseif op==55 then local A=inst.A local B=inst.B local c=inst.C-1if c==LUA_MULTRET then c=top-B+1 endtable_move(stack,B,B+c-1,inst.aux,stack[A])pc+=1 elseif op==56 then local A=inst.Alocal limit=stack[A]if not ttisnumber(limit)then local number=tonumber(limit)if number==nil then error("invalid 'for ' limit(number expected)")endstack[A]=number limit=number endlocal step=stack[A+1]if not ttisnumber(step)then local number=tonumber(step)if number==nil then error("invalid 'for ' step(number expected)")endstack[A+1]=number step=number endlocal index=stack[A+2]if not ttisnumber(index)then local number=tonumber(index)if number==nil then error("invalid 'for ' index(number expected)")endstack[A+2]=number index=number endif step>0 then if not(index<=limit)then pc+=inst.D end else if not(limit<=index)then pc+=inst.D end end elseif op==57 then if interruptHook then interruptHook(stack,debugging,proto,module,upvals)endlocal A=inst.A local limit=stack[A]local step=stack[A+1]local index=stack[A+2]+stepstack[A+2]=indexif step>0 then if index<=limit then pc+=inst.D end else if limit<=index then pc+=inst.D end end elseif op==58 then if interruptHook then interruptHook(stack,debugging,proto,module,upvals)endlocal A=inst.A local res=inst.Ktop=A+6local it=stack[A]if (luau_settings.generalizedIteration==false)or ttisfunction(it)then local vals={it(stack[A+1],stack[A+2])}table_move(vals,1,res,A+3,stack)if stack[A+3]~=nil then stack[A+2]=stack[A+3]pc+=inst.D else pc+=1 end else local ok,vals=coroutine_resume(generalized_iterators[inst],it,stack[A+1],stack[A+2])if not ok then error(vals)end if vals==LUA_GENERALIZED_TERMINATOR then generalized_iterators[inst]=nil pc+=1 else table_move(vals,1,res,A+3,stack)stack[A+2]=stack[A+3]pc+=inst.D end end elseif op==59 then if not ttisfunction(stack[inst.A])then error(string_format("attempt to iterate over a %s value",type(stack[inst.A])))endpc+=inst.D elseif op==60 then pc+=1 elseif op==61 then if not ttisfunction(stack[inst.A])then error(string_format("attempt to iterate over a %s value",type(stack[inst.A])))endpc+=inst.D elseif op==63 then local A=inst.A local b=inst.B-1if b==LUA_MULTRET then b=varargs.len top=A+b-1 endtable_move(varargs.list,1,b,A,stack)elseif op==64 then local newPrototype=protolist[inst.K+1]local nups=newPrototype.nups local upvalues=table_create(nups)stack[inst.A]=luau_wrapclosure(module,newPrototype,upvalues)for i=1,nups do local pseudo=code[pc]pc+=1local type=pseudo.A if type==0 then local upvalue={value=stack[pseudo.B],index="value",}upvalue.store=upvalueupvalues[i]=upvalue elseif type==2 then upvalues[i]=upvals[pseudo.B+1]end end elseif op==65 then elseif op==66 then local kv=inst.K stack[inst.A]=kvpc+=1 elseif op==67 then if interruptHook then interruptHook(stack,debugging,proto,module,upvals)endpc+=inst.E elseif op==68 then elseif op==69 then inst.E+=1 elseif op==70 then error("encountered unhandled CAPTURE")elseif op==71 then stack[inst.A]=inst.K-stack[inst.C]elseif op==72 then stack[inst.A]=inst.K/stack[inst.C]elseif op==73 then elseif op==74 then pc+=1 elseif op==75 then pc+=1 elseif op==76 then local iterator=stack[inst.A]if luau_settings.generalizedIteration and not ttisfunction(iterator)then local loopInstruction=code[pc+inst.D]if generalized_iterators[loopInstruction]==nil then local function gen_iterator(...)for r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16,r17,r18,r19,r20,r21,r22,r23,r24,r25,r26,r27,r28,r29,r30,r31,r32,r33,r34,r35,r36,r37,r38,r39,r40,r41,r42,r43,r44,r45,r46,r47,r48,r49,r50,r51,r52,r53,r54,r55,r56,r57,r58,r59,r60,r61,r62,r63,r64,r65,r66,r67,r68,r69,r70,r71,r72,r73,r74,r75,r76,r77,r78,r79,r80,r81,r82,r83,r84,r85,r86,r87,r88,r89,r90,r91,r92,r93,r94,r95,r96,r97,r98,r99,r100,r101,r102,r103,r104,r105,r106,r107,r108,r109,r110,r111,r112,r113,r114,r115,r116,r117,r118,r119,r120,r121,r122,r123,r124,r125,r126,r127,r128,r129,r130,r131,r132,r133,r134,r135,r136,r137,r138,r139,r140,r141,r142,r143,r144,r145,r146,r147,r148,r149,r150,r151,r152,r153,r154,r155,r156,r157,r158,r159,r160,r161,r162,r163,r164,r165,r166,r167,r168,r169,r170,r171,r172,r173,r174,r175,r176,r177,r178,r179,r180,r181,r182,r183,r184,r185,r186,r187,r188,r189,r190,r191,r192,r193,r194,r195,r196,r197,r198,r199,r200 in ... do coroutine_yield({r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16,r17,r18,r19,r20,r21,r22,r23,r24,r25,r26,r27,r28,r29,r30,r31,r32,r33,r34,r35,r36,r37,r38,r39,r40,r41,r42,r43,r44,r45,r46,r47,r48,r49,r50,r51,r52,r53,r54,r55,r56,r57,r58,r59,r60,r61,r62,r63,r64,r65,r66,r67,r68,r69,r70,r71,r72,r73,r74,r75,r76,r77,r78,r79,r80,r81,r82,r83,r84,r85,r86,r87,r88,r89,r90,r91,r92,r93,r94,r95,r96,r97,r98,r99,r100,r101,r102,r103,r104,r105,r106,r107,r108,r109,r110,r111,r112,r113,r114,r115,r116,r117,r118,r119,r120,r121,r122,r123,r124,r125,r126,r127,r128,r129,r130,r131,r132,r133,r134,r135,r136,r137,r138,r139,r140,r141,r142,r143,r144,r145,r146,r147,r148,r149,r150,r151,r152,r153,r154,r155,r156,r157,r158,r159,r160,r161,r162,r163,r164,r165,r166,r167,r168,r169,r170,r171,r172,r173,r174,r175,r176,r177,r178,r179,r180,r181,r182,r183,r184,r185,r186,r187,r188,r189,r190,r191,r192,r193,r194,r195,r196,r197,r198,r199,r200})endcoroutine_yield(LUA_GENERALIZED_TERMINATOR)endgeneralized_iterators[loopInstruction]=coroutine_create(gen_iterator)end endpc+=inst.D elseif op==77 then local kn=inst.KNif(stack[inst.A]==nil)~=kn then pc+=inst.D else pc+=1 end elseif op==78 then local kv=inst.K local kn=inst.KN local ra=stack[inst.A]if (ttisboolean(ra)and(ra==kv))~=kn then pc+=inst.D else pc+=1 end elseif op==79 then local kv=inst.K local kn=inst.KN local ra=stack[inst.A]if (ra==kv)~=kn then pc+=inst.D else pc+=1 end elseif op==80 then local kv=inst.K local kn=inst.KN local ra=stack[inst.A]if (ra==kv)~=kn then pc+=inst.D else pc+=1 end elseif op==81 then stack[inst.A]=stack[inst.B]//stack[inst.C]elseif op==82 then stack[inst.A]=stack[inst.B]//inst.K else error("Unsupported Opcode: " .. inst.opname .. " op: " .. op)end endfor i,uv in open_upvalues do uv.value=uv.store[uv.index]uv.store=uv uv.index="value" open_upvalues[i]=nil endfor i,iter in generalized_iterators do coroutine_close(iter)generalized_iterators[i]=nil end endlocal function wrapped(...)local passed=table_pack(...)local stack=table_create(proto.maxstacksize)local varargs={len=0,list={},}table_move(passed,1,proto.numparams,0,stack)if proto.numparams<passed.n then local start=proto.numparams+1 local len=passed.n-proto.numparams varargs.len=len table_move(passed,start,start+len-1,1,varargs.list)endpassed=nillocal debugging={pc=0,name="NONE"}local result if luau_settings.errorHandling then result=table_pack(pcall(luau_execute,debugging,stack,proto.protos,proto.code,varargs))else result=table_pack(true,luau_execute(debugging,stack,proto.protos,proto.code,varargs))endif result[1]then return table_unpack(result,2,result.n)else local message=result[2]if panicHook then panicHook(message,stack,debugging,proto,module,upvals)endif ttisstring(message)==false then if luau_settings.allowProxyErrors then error(message)else message=type(message)end endif proto.lineinfoenabled then return error(string_format("Fiu VM Error{Name: %s Line: %s PC: %s Opcode: %s}: %s",proto.debugname,proto.instructionlineinfo[debugging.pc],debugging.pc,debugging.name,message),0)else return error(string_format("Fiu VM Error{Name: %s PC: %s Opcode: %s}: %s",proto.debugname,debugging.pc,debugging.name,message),0)end end endif luau_settings.errorHandling then return wrapped else return luau_execute end endreturn luau_wrapclosure(module,mainProto),luau_close end return {luau_load=luau_load,luau_newsettings=luau_newsettings}
end)()

task.spawn(function()
  if getgenv().Hyperion and not getgenv().HyperionDebug then return end
  getgenv().Hyperion = true
  local cloneref = getgenv().cloneref or function(a) return a end
  if not getgenv().cloneref then
    print("[HYPERION]: Cloneref is not found. Using polyfill.")
  end;
  local http = cloneref(game:GetService("HttpService"))
  local tcs = cloneref(game:GetService("TextChatService"))
  local localplr = cloneref(game:GetService("Players")).LocalPlayer
  local accepted;
  local function assets(...)
    return table.concat({ "Hyperion", ... }, "/")
  end
  local function log(...)
    print("[HYPERION]: ", ...)
  end
  makefolder("Hyperion")
  makefolder(assets("modules"))
  makefolder(assets("modules", "og"))
  makefolder(assets("modules", "normal"))
  makefolder(assets("cache"))
  local Obsidian, ThemeManager
  task.spawn(function()
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
    local function loadCached(cachePath, url)
      local cached = isfile(cachePath) and readfile(cachePath)
      if cached and cached ~= "" then
        local chunk = loadstring(cached)
        if chunk then
          local okRun, lib = pcall(chunk)
          if okRun and lib then
            task.spawn(function()
              local ok, fresh = pcall(game.HttpGet, game, url)
              if ok and fresh and fresh ~= cached then
                pcall(writefile, cachePath, fresh)
              end
            end)
            return lib
          end
        end
      end
      local fresh = game:HttpGet(url)
      writefile(cachePath, fresh)
      return loadstring(fresh)()
    end
    Obsidian = loadCached(assets("cache", "Library.lua"), repo .. "Library.lua")
    ThemeManager = loadCached(assets("cache", "ThemeManager.lua"), repo .. "addons/ThemeManager.lua")
  end)
  
  local assetsReady = false
  local modulesReady = false
  local Helpers = {}
  
  task.spawn(function()
    local function createfile(url)
      local path = assets(url)
      if isfile(path) then return end
      writefile(path, game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/assets/" .. url))
    end
    createfile("hyperion_logo.jpg")
    createfile("discord_invite.txt")
    assetsReady = true
  end)
  
  task.spawn(function()
    local CACHE_PATH = assets("modules", ".sha_cache.json")
    local shaCache = {}
    local ok, data = pcall(function() return http:JSONDecode(readfile(CACHE_PATH)) end)
    if ok and type(data) == "table" then shaCache = data end
    
    local remoteNames = {}
    local listingsRemaining = 2
    local pending = 0
    
    for _, subdir in ipairs({ "og", "normal" }) do
      task.spawn(function()
        local fetched, result = pcall(function()
          return http:JSONDecode(game:HttpGet(
            "https://api.github.com/repos/Horizon-Developments/hyperion/contents/assets_encrypted/modules/" .. subdir
          ))
        end)
        if not fetched then
          log("Failed to fetch modules/" .. subdir, result)
          listingsRemaining -= 1
          return
        end
        for _, item in ipairs(result) do
          if item.type ~= "file" then continue end
          local cacheKey = subdir .. "/" .. item.name
          remoteNames[cacheKey] = true
          if shaCache[cacheKey] == item.sha then
            log("Skipped " .. cacheKey)
            continue
          end
          pending += 1
          task.spawn(function()
            pcall(function()
              writefile(assets("modules", subdir, item.name), game:HttpGet(item.download_url))
              shaCache[cacheKey] = item.sha
            end)
            pending -= 1
          end)
        end
        listingsRemaining -= 1
      end)
    end
    
    repeat task.wait() until listingsRemaining <= 0
    repeat task.wait() until pending <= 0

    if next(remoteNames) ~= nil then
      for key in pairs(shaCache) do
        if remoteNames[key] then continue end
        local sub, filename = key:match("^([^/]+)/(.+)$")
        if sub and filename then
          pcall(function() delfile(assets("modules", sub, filename)) end)
        end
        shaCache[key] = nil
        log("Deleted " .. key)
      end
    end
    
    pcall(function() writefile(CACHE_PATH, http:JSONEncode(shaCache)) end)
    modulesReady = true
  end)
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
        if (not cn or not cn:FindFirstChild(localplr.Name)) then return end
        log("SKIPPED CMD ", c, " no enli and not admin ")
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
  repeat task.wait() until Obsidian ~= nil and assetsReady
  local discordInvite = readfile(assets("discord_invite.txt"))
  local Window = Obsidian:CreateWindow({
    Title = "Hyperion (Reborn)",
    Footer = "by horizonscript in discord",
    Icon = "zap",
    ToggleKeybind = Enum.KeyCode.RightShift,
    Center = true,
    AutoShow = true,
  })

  local tabs = {}
  tabs.info = Window:AddTab("Main", "home")
  tabs.settings = Window:AddTab("UI Settings", "settings")
  
  local InfoBox = tabs.info:AddLeftGroupbox("Hyperion")
  InfoBox:AddLabel({ Text = "Join our Discord for suggestions, updates, and help.", DoesWrap = true })
  InfoBox:AddButton({
    Text = "Copy Invite",
    Func = function()
      setclipboard(discordInvite)
      Obsidian:Notify({ Title = "Copied!", Description = "Discord link copied to clipboard.", Time = 3 })
    end,
  })
  InfoBox:AddLabel({ Text = [[By clicking Accept LICENSE you confirm that you have read, understood, and agreed to the Horizon-Developments Proprietary License (https://raw.githubusercontent.com/Horizon-Developments/hyperion/refs/heads/main/LICENSE.md) in full]], DoesWrap = true })
  InfoBox:AddButton({
    Text = "Accept LICENSE",
    Func = function()
      accepted = true
    end
  })
  InfoBox:AddDivider()
  InfoBox:AddLabel({ Text = "About Hyperion: a modular system. Instead of using a separate script, extend it with plugins. Visit #plugins on our Discord to find and share plugins.", DoesWrap = true })
  InfoBox:AddDivider()
  InfoBox:AddLabel({ Text = "Adding a Plugin: place your plugin file in Hyperion/modules/ (located inside your executor's folder).", DoesWrap = true })
  InfoBox:AddDivider()
  InfoBox:AddLabel({ Text = "Creating Your Own Plugin: full documentation is available on #plugins-dev on our Discord server.", DoesWrap = true })
  
  repeat task.wait() until ThemeManager ~= nil
  
  ThemeManager:SetLibrary(Obsidian)
  ThemeManager:SetFolder("Hyperion")
  ThemeManager:SetDefaultTheme({
    FontColor = Color3.fromHex("#ffffff"),
    MainColor = Color3.fromHex("#1a1a1a"),
    AccentColor = Color3.fromHex("#cc0000"),
    BackgroundColor = Color3.fromHex("#0a0a0a"),
    OutlineColor = Color3.fromHex("#cc0000"),
  })
  ThemeManager:ApplyToTab(tabs.settings)
  ThemeManager:LoadDefault()
  
  repeat task.wait() until modulesReady
  repeat task.wait() until accepted
  
  local subfolder = game.PlaceId == 108097274488844 and "og" or "normal"
  local ctx = { Tabs = tabs, Window = Window, Obsidian = Obsidian, Assets = assets, Helpers = Helpers }
  local k2 = game:HttpGet("https://raw.githubusercontent.com/Horizon-Developments/hyperion/main/key.txt")
  
  local function loadModule(name)
    local bin = readfile(assets("modules", subfolder, name))
    local bytecode, err = aead.decrypt("", sha3.sha256(bin:sub(17, 32) .. k2 .. "HYPERION@bS$l2Jul63@TU!^He;,Pg.9T6leH14O"), bin:sub(#bin - 11), bin:sub(#bin - 23, #bin - 12), bin:sub(33, #bin - 24), bin:sub(1, 16))
    if not bytecode then error("decrypt failed: " .. name .. " " .. tostring(err)) end
    local fn = fiu.luau_load(bytecode, getgenv())
    return fn(ctx)
  end
  
  for _, file in ipairs(listfiles(assets("modules", subfolder))) do
    local name = file:match("([^/\\]+)$")
    if not name:match("%.bin$") then continue end
    task.spawn(function()
      local ok, err = pcall(loadModule, name)
      if not ok then warn("[HYPERION]: module error:", name, err) end
    end)
  end
end)