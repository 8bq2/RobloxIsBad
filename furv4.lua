print("Hello from GitHub!")

print("init")

local genv={}
local Part_Classes = {"Part","WedgePart","CornerWedgePart"}
local Part_Shapes = {"Brick","Cylinder","Sphere","Torso","Wedge"}
function DecodeUnion(t)
	local r = function()return table.remove(t,1) end
	local split = function(str,sep)
		local fields = {}
		str:gsub(("([^%s]+)"):format(sep or ','),function(c)fields[#fields+1]=c end)
		return fields
	end
	local m = Instance.new("Folder")
	m.Name = "UnionCache ["..tostring(math.random(1,9999)).."]"
	m.Archivable = false
	m.Parent = game:GetService("ServerStorage")
	local Union,Subtract = {},{}
	repeat
		local isNegate = false
		local class = r()
		if class=='-' then
			isNegate = true
			class = r()
		end
		if class=='n' then
			local d = {}
			local a = r()
			repeat
				table.insert(d,a)
				a = r()
			until a=='p'
			local u = DecodeUnion(d)
			if u then
				table.insert(isNegate and Subtract or Union,u)
			end
		else
			local size,pos,rot = Vector3.new(unpack(split(r()))),Vector3.new(unpack(split(r()))),Vector3.new(unpack(split(r())))
			local part = Instance.new(Part_Classes[tonumber(class)])
			part.Size = size
			part.Position = pos
			part.Orientation = rot
			if r()=="+" then
				local m,ms,of = r(),Vector3.new(unpack(split(r()))),Vector3.new(unpack(split(r())))
				if tonumber(m)==6 then
					part.Shape = Enum.PartType.Cylinder
				elseif tonumber(m)==7 then
					part.Shape = Enum.PartType.Ball
				else
					local mesh = Instance.new(tonumber(m)==8 and "CylinderMesh" or "SpecialMesh")
					if tonumber(m)~=8 then
						mesh.MeshType = Enum.MeshType[Part_Shapes[tonumber(m)]]
					end
					mesh.Scale = ms
					mesh.Offset = of
					mesh.Parent = part
				end
			end
			table.insert(isNegate and Subtract or Union,part)
		end
	until #t<=0
	local first = Union[1]
	first.Parent = m
	if #Union>1 then
		first = first:UnionAsync(Union)
		first.Parent = m
	end
	if #Subtract>0 then
		first = first:SubtractAsync(Subtract)
		first.Parent = m
	end
	first.Parent = nil
	m:Destroy()
	return first
end
Decode =  function(str,t,props,classes,values,ICList,Model,CurPar,LastIns,split,RemoveAndSplit,InstanceList)
	local tonum,table_remove,inst,parnt,comma,table_foreach = tonumber,table.remove,Instance.new,"Parent",",",
	function(t,f)
		for a,b in pairs(t) do
			f(a,b)
		end
	end
	local Types = {
		Color3 = Color3.new,
		Vector3 = Vector3.new,
		Vector2 = Vector2.new,
		UDim = UDim.new,
		UDim2 = UDim2.new,
		CFrame = CFrame.new,
		Rect = Rect.new,
		NumberRange = NumberRange.new,
		BrickColor = BrickColor.new,
		PhysicalProperties = PhysicalProperties.new,
		NumberSequence = function(...)
			local a = {...}
			local t = {}
			repeat
				t[#t+1] = NumberSequenceKeypoint.new(table_remove(a,1),table_remove(a,1),table_remove(a,1))
			until #a==0
			return NumberSequence.new(t)
		end,
		ColorSequence = function(...)
			local a = {...}
			local t = {}
			repeat
				t[#t+1] = ColorSequenceKeypoint.new(table_remove(a,1),Color3.new(table_remove(a,1),table_remove(a,1),table_remove(a,1)))
			until #a==0
			return ColorSequence.new(t)
		end,
		number = tonumber,
		boolean = function(a)
			return a=="1"
		end
	}
	split = function(str,sep)
		if not str then return end
		local fields = {}
		local ConcatNext = false
		str:gsub(("([^%s]+)"):format(sep),function(c)
			if ConcatNext == true then
				fields[#fields] = fields[#fields]..sep..c
				ConcatNext = false
			else
				fields[#fields+1] = c
			end
			if c:sub(#c)=="\\" then
				c = fields[#fields]
				fields[#fields] = c:sub(1,#c-1)
				ConcatNext = true
			end
		end)
		return fields
	end
	RemoveAndSplit = function(t)
		return split(table_remove(t,1),comma)
	end
	t = split(str,";")
	props = RemoveAndSplit(t)
	classes = RemoveAndSplit(t)
	values = split(table_remove(t,1),'|')
	ICList = RemoveAndSplit(t)
	InstanceList = {}
	Model = inst"Model"
	CurPar = Model
	table_foreach(t,function(ct,c)
		if c=="n" or c=="p" then
			CurPar = c=="n" and LastIns or CurPar[parnt]
		else
			ct = split(c,"|")
			local class = classes[tonum(table_remove(ct,1))]
			if class=="UnionOperation" then
				LastIns = {UsePartColor="1"}
			else
				LastIns = inst(class)
				if LastIns:IsA"Script" then
					s(LastIns)
				elseif LastIns:IsA("ModuleScript") then
					ms(LastIns)
				end
			end

			local function SetProperty(LastIns,p,str,s)
				s = Types[typeof(LastIns[p])]
				if p=="CustomPhysicalProperties" then
					s = PhysicalProperties.new
				end
				if s then
					LastIns[p] = s(unpack(split(str,comma)))
				else
					LastIns[p] = str
				end
			end

			local UnionData
			table_foreach(ct,function(s,p,a,str)
				a = p:find":"
				p,str = props[tonum(p:sub(1,a-1))],values[tonum(p:sub(a+1))]
				if p=="UnionData" then
					UnionData = split(str," ")
					return
				end
				if class=="UnionOperation" then
					LastIns[p] = str
					return
				end
				SetProperty(LastIns,p,str)
			end)

			if UnionData then
				local LI_Data = LastIns
				LastIns = DecodeUnion(UnionData)
				table_foreach(LI_Data,function(p,str)
					SetProperty(LastIns,p,str)
				end)
			end
			table.insert(InstanceList,LastIns)
			LastIns[parnt] = CurPar
		end
	end)
	table_remove(ICList,1)
	table_foreach(ICList,function(a,b)
		b = split(b,">")
		InstanceList[tonum(b[1])][props[tonum(b[2])]] = InstanceList[tonum(b[3])]
	end)

	return Model:GetChildren()
end

local Objects = Decode('Name,PrimaryPart,Color,Material,Position,Size,CanCollide,BottomSurface,TopSurface,Scale,MeshId,MeshType,C0,Part0,Part1,Orientation,Transparency,UnionData,UsePartColor;Part,Model,SpecialMesh,Motor6D,Un'
	..'ionOperation;Part|K9PP|Sheathe|0.9725,0.9725,0.9725|272|-0.0114,-0.0706,0.6086|0.5,0.5,0.6599|0|0|0.5,0.5,4|http://www.roblox.com/asset/?id=3270017|5|BitBeforeKnot|0,-0.0208,-0.0302,0,0,-1,-0.1716,0.9'
	..'851,0,0.9851,0.1715,0|RBall|0.2,-0.1001,0.3032,-1,0,0,0,1,0,0,0,-1|LBall|-0.2,-0.1001,0.3032,-1,0,0,0,1,0,0,0,-1|-0.0001,-0.0001,0.2918,0,0,-1,0,1,0,1,0,0|0.1887,-0.1707,0.9119|0,180,0|0.6332,0.6277,0'
	..'.5669|3|-0.2114,-0.1707,0.9119|SheatheBack|-0.0114,-0.0707,0.9005|0,-90,0|0.05,0.5,0.66|4|InflatedKnot|1,0.349,0.349|1|1 0.8366,0.8294,0.749 -0.0001,-0.0001,0.0078 0,180,0 + 3 1,1,1 0,0,0 1 0.8366,0.8'
	..'294,0.749 -0.0001,-0.0001,-0.0079 0,180,0 + 3 1,1,1 0,0,0|-0.0114,-0.0913,0.5785|0,-90,-9.8801|0.861,0.2575,0.34|Knot|-0.5859,-0.0091,-0.0115,0,-0.1716,-0.9852,0,0.9851,-0.1716,1,0,0|-0.5856,-0.0094,-'
	..'0.0114,0,-0.1716,-0.9852,0,0.9851,-0.1716,1,0,0|Shaft|-1.0101,0,0,1,-0.0001,0,-0.0001,1,0,0,0,1|-0.0114,0.082,-0.4166|1.0146,0.3257,0.43|Shaft2|-0.1951,-0.0101,0,1,-0.0001,0,-0.0001,1,0,0,0,1|Head|-0.'
	..'4737,0.029,-0.0121,-0.1094,-0.9938,0.024,0.9938,-0.1089,0.0195,-0.0168,0.026,0.9995|-0.5216,0.0571,-0.0276,-0.1094,-0.9938,0.024,0.9938,-0.1089,0.0195,-0.0168,0.026,0.9995|-0.4852,0.025,-0.0117,-0.109'
	..'4,-0.9938,0.024,0.9938,-0.1089,0.0195,-0.0168,0.026,0.9995|-0.0114,0.1056,-0.6105|0.7246,0.4077,0.459|1 0.5366,0.532,0.4804 0,0.0003,0.0048 0,180,0 + 3 1,1,1 0,0,0 1 0.5366,0.532,0.4804 0,0.0003,-0.00'
	..'53 0,180,0 + 3 1,1,1 0,0,0|0.0162,0.2278,-0.9206|-0.8601,-88.45,86.3799|0.2384,0.4529,0.2927|0.0003,0.1899,-0.8903|0.4324,0.4206,0.4059|0.0007,0.1919,-0.8783|0.4472,0.2363,0.4583;0,1>2>2,4>14>2,4>15>1'
	..'5,5>14>2,5>15>8,6>14>2,6>15>10,7>14>2,7>15>12,17>14>15,17>15>28,18>14>15,18>15>14,19>14>15,19>15>20,22>14>20,22>15>26,23>14>20,23>15>33,24>14>20,24>15>29,25>14>20,25>15>31;2|1:2;n;1|1:3|3:4|4:5|5:6|6:'
	..'7|7:8|8:9|9:9|3:4|3:4;n;3|10:10|11:11|12:12;4|1:13|13:14;4|1:15|13:16;4|1:17|13:18;4|1:3|13:19;p;1|1:15|3:4|4:5|5:20|16:21|6:22|7:8|8:9|9:9|3:4|3:4;n;3|12:23;p;1|1:17|3:4|4:5|5:24|16:21|6:22|7:8|8:9|9'
	..':9|3:4|3:4;n;3|12:23;p;1|1:25|3:4|4:5|5:26|16:27|6:28|7:8|8:9|9:9|3:4|3:4;n;3|12:29;p;5|1:30|3:31|4:5|17:32|7:8|3:31|3:31|18:33;1|1:13|3:31|4:5|5:34|16:35|6:36|7:8|8:9|9:9|3:31|3:31;n;3|12:29;4|1:37|1'
	..'3:38;4|1:30|13:39;4|1:40|13:41;p;1|1:40|3:31|4:5|5:42|16:35|6:43|7:8|8:9|9:9|3:31|3:31;n;3|12:29;4|1:44|13:45;4|1:46|13:47;4|1:46|13:48;4|1:46|13:49;p;1|1:44|3:31|4:5|5:50|16:35|6:51|7:8|8:9|9:9|3:31|'
	..'3:31;n;3|12:23;p;5|1:37|3:31|4:5|7:8|19:32|3:31|3:31|18:52;1|1:46|3:31|4:5|5:53|16:54|6:55|7:8|8:9|9:9|3:31|3:31;n;3|12:23;p;1|1:46|3:31|4:5|5:56|16:54|6:57|7:8|8:9|9:9|3:31|3:31;n;3|12:23;p;1|1:46|3:'
	..'31|4:5|5:58|16:54|6:59|7:8|8:9|9:9|3:31|3:31;n;3|12:23;p;p;')
for _,Object in pairs(Objects) do
	Object.Parent = script
end

local Objects = Decode('Name,ZIndexBehavior,Position,Size,AnchorPoint,BackgroundColor3,BorderColor3,BorderSizePixel,BackgroundTransparency,Font,Text,TextColor3,TextScaled,TextSize,TextWrapped,TextXAlignment;Part,ScreenGui,Fr'
	..'ame,TextLabel;Part|GUI|1|Background|0.6999,0,0.8999,0|0,373,0,46|0.5,0.5|0,0,0|0.5686,0.2862,0.5058|5|Fill|0,0,1,0|1,0,1,0|0,1|1,0.4745,0.9921|0|Pleasure|1,1,1|1|9|Pleasure!~ (0%)|36|0|Hidden|0.8999,0'
	..',-0.7,0|0.2,0,0.6499,0|Showing|14;0;2|1:2|2:3;n;3|1:4|3:5|4:6|5:7|6:8|7:9|8:10;n;3|1:11|3:12|4:13|5:14|6:15|8:16;4|1:17|4:13|6:18|9:19|10:20|11:21|12:9|13:19|14:22|15:19|16:23;4|1:24|3:25|4:26|5:7|6:8'
	..'|7:9|8:10|10:20|11:27|12:15|13:19|14:28|15:19;p;p;')
for _,Object in pairs(Objects) do
	Object.Parent = script
end

local Player = nil
if(not getfenv().owner)then
	if script:FindFirstAncestorWhichIsA("Model") then
		Player = game:GetService("Players"):GetPlayerFromCharacter(script:FindFirstAncestorWhichIsA("Model"))
	elseif script:FindFirstAncestorWhichIsA("Player") then
		Player = script:FindFirstAncestorWhichIsA("Player")
	end
else
	Player = getfenv().owner
end
local Mouse,mouse,UserInputService,ContextActionService
do
	local GUID = {}
	do
		GUID.IDs = {};
		function GUID:new(len)
			local id;
			if(not len)then
				id = (tostring(function() end))
				id = id:gsub("function: ","")
			else
				local function genID(len)
					local newID = ""
					for i = 1,len do
						newID = newID..string.char(math.random(48,90))
					end
					return newID
				end
				repeat id = genID(len) until not GUID.IDs[id]
				local oid = id;
				id = {Trash=function() GUID.IDs[oid]=nil; end;Get=function() return oid; end}
				GUID.IDs[oid]=true;
			end
			return id
		end
	end

	local AHB = Instance.new("BindableEvent")

	local FPS = 30

	local TimeFrame = 0

	local LastFrame = tick()
	local Frame = 1/FPS

	game:service'RunService'.Heartbeat:connect(function(s,p)
		TimeFrame = TimeFrame + s
		if(TimeFrame >= Frame)then
			for i = 1,math.floor(TimeFrame/Frame) do
				AHB:Fire()
			end
			LastFrame=tick()
			TimeFrame=TimeFrame-Frame*math.floor(TimeFrame/Frame)
		end
	end)


	function swait(dur)
		if(dur == 0 or typeof(dur) ~= 'number')then
			AHB.Event:wait()
		else
			for i = 1, dur*FPS do
				AHB.Event:wait()
			end
		end
	end

	local loudnesses={}
	script.Parent = Player.Character
	local CoAS = {Actions={}}
	local Event = Instance.new("RemoteEvent")
	Event.Name = "UserInputEvent"
	Event.Parent = Player.Character
	local Func = Instance.new("RemoteFunction")
	Func.Name = "GetClientProperty"
	Func.Parent = Player.Character
	local fakeEvent = function()
		local t = {_fakeEvent=true,Waited={}}
		t.Connect = function(self,f)
			local ft={Disconnected=false;disconnect=function(s) s.Disconnected=true end}
			ft.Disconnect=ft.disconnect

			ft.Func=function(...)
				for id,_ in next, t.Waited do 
					t.Waited[id] = true 
				end 
				return f(...)
			end; 
			self.Function=ft;
			return ft;
		end
		t.connect = t.Connect
		t.Wait = function() 
			local guid = GUID:new(25)
			local waitingId = guid:Get()
			t.Waited[waitingId]=false
			repeat swait() until t.Waited[waitingId]==true  
			t.Waited[waitingId]=nil;
			guid:Trash()
		end
		t.wait = t.Wait
		return t
	end
	local m = {Target=nil,Hit=CFrame.new(),KeyUp=fakeEvent(),KeyDown=fakeEvent(),Button1Up=fakeEvent(),Button1Down=fakeEvent()}
	local UsIS = {InputBegan=fakeEvent(),InputEnded=fakeEvent()}

	function CoAS:BindAction(name,fun,touch,...)
		CoAS.Actions[name] = {Name=name,Function=fun,Keys={...}}
	end
	function CoAS:UnbindAction(name)
		CoAS.Actions[name] = nil
	end
	local function te(self,ev,...)
		local t = self[ev]
		if t and t._fakeEvent and t.Function and t.Function.Func and not t.Function.Disconnected then
			t.Function.Func(...)
		elseif t and t._fakeEvent and t.Function and t.Function.Func and t.Function.Disconnected then
			self[ev].Function=nil
		end
	end
	m.TrigEvent = te
	UsIS.TrigEvent = te
	Event.OnServerEvent:Connect(function(plr,io)
		if plr~=Player then return end
		if io.Mouse then
			m.Target = io.Target
			m.Hit = io.Hit
		elseif io.KeyEvent then
			m:TrigEvent('Key'..io.KeyEvent,io.Key)
		elseif io.UserInputType == Enum.UserInputType.MouseButton1 then
			if io.UserInputState == Enum.UserInputState.Begin then
				m:TrigEvent("Button1Down")
			else
				m:TrigEvent("Button1Up")
			end
		end
		if(not io.KeyEvent and not io.Mouse)then
			for n,t in pairs(CoAS.Actions) do
				for _,k in pairs(t.Keys) do
					if k==io.KeyCode then
						t.Function(t.Name,io.UserInputState,io)
					end
				end
			end
			if io.UserInputState == Enum.UserInputState.Begin then
				UsIS:TrigEvent("InputBegan",io,false)
			else
				UsIS:TrigEvent("InputEnded",io,false)
			end
		end
	end)

	Func.OnServerInvoke = function(plr,inst,play)
		if plr~=Player then return end
		if(inst and typeof(inst) == 'Instance' and inst:IsA'Sound')then
			loudnesses[inst]=play	
		end
	end

	function GetClientProperty(inst,prop)
		if(prop == 'PlaybackLoudness' and loudnesses[inst])then 
			return loudnesses[inst] 
		elseif(prop == 'PlaybackLoudness')then
			return Func:InvokeClient(Player,'RegSound',inst)
		end
		return Func:InvokeClient(Player,inst,prop)
	end
	Mouse, mouse, UserInputService, ContextActionService = m, m, UsIS, CoAS
end

NLS([[local me = game:service'Players'.localPlayer;
local mouse = me:GetMouse();
local UIS = game:service'UserInputService'
local ch = workspace:WaitForChild(me.Name);

local UserEvent = ch:WaitForChild('UserInputEvent',30)

UIS.InputChanged:connect(function(io,gpe)
	if(io.UserInputType == Enum.UserInputType.MouseMovement)then
		UserEvent:FireServer{Mouse=true,Target=mouse.Target,Hit=mouse.Hit}
	end
end)

mouse.Changed:connect(function(o)
	if(o == 'Target' or o == 'Hit')then
		UserEvent:FireServer{Mouse=true,Target=mouse.Target,Hit=mouse.Hit}
	end
end)

UIS.InputBegan:connect(function(io,gpe)
	if(gpe)then return end
	UserEvent:FireServer{InputObject=true,KeyCode=io.KeyCode,UserInputType=io.UserInputType,UserInputState=io.UserInputState}
end)

UIS.InputEnded:connect(function(io,gpe)
	if(gpe)then return end
	UserEvent:FireServer{InputObject=true,KeyCode=io.KeyCode,UserInputType=io.UserInputType,UserInputState=io.UserInputState}
end)

mouse.KeyDown:connect(function(k)
	UserEvent:FireServer{KeyEvent='Down',Key=k}
end)

mouse.KeyUp:connect(function(k)
	UserEvent:FireServer{KeyEvent='Up',Key=k}
end)

local ClientProp = ch:WaitForChild('GetClientProperty',30)

local sounds = {}


function regSound(o)
	if(o:IsA'Sound')then

		local lastLoudness = o.PlaybackLoudness
		ClientProp:InvokeServer(o,lastLoudness)
		table.insert(sounds,{o,lastLoudness})
		--ClientProp:InvokeServer(o,o.PlaybackLoudness)
	end
end

ClientProp.OnClientInvoke = function(inst,prop)
	if(inst == 'RegSound')then
		regSound(prop)
		for i = 1, #sounds do
			if(sounds[i][1] == prop)then 
				return sounds[i][2]
			end 
		end 
	else
		return inst[prop]
	end
end

for _,v in next, workspace:GetDescendants() do regSound(v) end
workspace.DescendantAdded:connect(regSound)
me.Character.DescendantAdded:connect(regSound)

game:service'RunService'.RenderStepped:connect(function()
	for i = 1, #sounds do
		local tab = sounds[i]
		local object,last=unpack(tab)
		if(object.PlaybackLoudness ~= last)then
			sounds[i][2]=object.PlaybackLoudness
			--ClientProp:InvokeServer(object,sounds[i][2])
		end
	end
end)]],owner.Character)

--// Shortcut Variables \\--
local S = setmetatable({},{__index = function(s,i) return game:service(i) end})
local CF = {N=CFrame.new,A=CFrame.Angles,fEA=CFrame.fromEulerAnglesXYZ}
local C3 = {tRGB= function(c3) return c3.r*255,c3.g*255,c3.b*255 end,N=Color3.new,RGB=Color3.fromRGB,HSV=Color3.fromHSV,tHSV=Color3.toHSV}
local V3 = {N=Vector3.new,FNI=Vector3.FromNormalId,A=Vector3.FromAxis}
local M = {C=math.cos,R=math.rad,S=math.sin,P=math.pi,RNG=math.random,MRS=math.randomseed,H=math.huge,RRNG = function(min,max,div) return math.rad(math.random(min,max)/(div or 1)) end}
local R3 = {N=Region3.new}
local De = S.Debris
local WS = workspace
local Lght = S.Lighting
local RepS = S.ReplicatedStorage
local IN = Instance.new
local Plrs = S.Players

--// Initializing \\--
local Plr = Player
local PGui = Plr:WaitForChild'PlayerGui'
local Char = Plr.Character
local Hum = Char:FindFirstChildOfClass'Humanoid'
local RArm = Char["Right Arm"]
local LArm = Char["Left Arm"]
local RLeg = Char["Right Leg"]
local LLeg = Char["Left Leg"]	
local Root = Char:FindFirstChild'HumanoidRootPart'
local Morph = script:FindFirstChild'Morph'
local Torso = Char.Torso
local Head = Char.Head
local NeutralAnims = true
local Attack = false
local Debounces = {Debounces={}}
local Hit = {}
local Sine = 0
local Change = 1
local Pleasure = 0
local BloodPuddles = {}
local Penetrated = {Who=nil,Weld=nil}
local legAnims = true
local Personality = M.RNG(1,5)
local Stance = 0;
local Cumming = false
local ManualCum = false

local Effects = IN("Folder",Char)
Effects.Name = "Effects"
--// Debounce System \\--


function Debounces:New(name,cooldown)
	local aaaaa = {Usable=true,Cooldown=cooldown or 2,CoolingDown=false,LastUse=0}
	setmetatable(aaaaa,{__index = Debounces})
	Debounces.Debounces[name] = aaaaa
	return aaaaa
end

function Debounces:Use(overrideUsable)
	assert(self.Usable ~= nil and self.LastUse ~= nil and self.CoolingDown ~= nil,"Expected ':' not '.' calling member function Use")
	if(self.Usable or overrideUsable)then
		self.Usable = false
		self.CoolingDown = true
		local LastUse = time()
		self.LastUse = LastUse
		delay(self.Cooldown or 2,function()
			if(self.LastUse == LastUse)then
				self.CoolingDown = false
				self.Usable = true
			end
		end)
	end
end

function Debounces:Get(name)
	assert(typeof(name) == 'string',("bad argument #1 to 'get' (string expected, got %s)"):format(typeof(name) == nil and "no value" or typeof(name)))
	for i,v in next, Debounces.Debounces do
		if(i == name)then
			return v;
		end
	end
end

function Debounces:GetProgressPercentage()
	assert(self.Usable ~= nil and self.LastUse ~= nil and self.CoolingDown ~= nil,"Expected ':' not '.' calling member function Use")
	if(self.CoolingDown and not self.Usable)then
		return math.max(
			math.floor(
				(
					(time()-self.LastUse)/self.Cooldown or 2
				)*100
			)
		)
	else
		return 100
	end
end

--// Instance Creation Functions \\--
local baseSound = IN("Sound")
function Sound(parent,id,pitch,volume,looped,effect,autoPlay)
	local Sound = baseSound:Clone()
	Sound.SoundId = "rbxassetid://".. tostring(id or 0)
	Sound.Pitch = pitch or 1
	Sound.Volume = volume or 1
	Sound.Looped = looped or false
	if(autoPlay)then
		coroutine.wrap(function()
			repeat game:GetService('RunService').Heartbeat:wait() until Sound.IsLoaded
			Sound.Playing = autoPlay or false
		end)()
	end
	if(not looped and effect)then
		Sound.Stopped:connect(function()
			Sound.Volume = 0
			Sound:destroy()
		end)
	elseif(effect)then
		warn("Sound can't be looped and a sound effect!")
	end
	Sound.Parent =parent or Torso
	return Sound
end
function Part(parent,color,material,size,cframe,anchored,cancollide)
	local part = IN("Part")
	part.Parent = parent or Char
	part[typeof(color) == 'BrickColor' and 'BrickColor' or 'Color'] = color or C3.N(0,0,0)
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface,part.BottomSurface=10,10
	part.Size = size or V3.N(1,1,1)
	part.CFrame = cframe or CF.N(0,0,0)
	part.CanCollide = cancollide or false
	part.Anchored = anchored or false
	return part
end

function Weld(part0,part1,c0,c1)
	local weld = IN("Weld")
	weld.Parent = part0
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = c0 or CF.N()
	weld.C1 = c1 or CF.N()
	return weld
end

function Mesh(parent,meshtype,meshid,textid,scale,offset)
	local part = IN("SpecialMesh")
	part.MeshId = meshid or ""
	part.TextureId = textid or ""
	part.Scale = scale or V3.N(1,1,1)
	part.Offset = offset or V3.N(0,0,0)
	part.MeshType = meshtype or Enum.MeshType.Sphere
	part.Parent = parent
	return part
end

NewInstance = function(instance,parent,properties)
	local inst = Instance.new(instance)
	inst.Parent = parent
	if(properties)then
		for i,v in next, properties do
			pcall(function() inst[i] = v end)
		end
	end
	return inst;
end

function Clone(instance,parent,properties)
	local inst = instance:Clone()
	inst.Parent = parent
	if(properties)then
		for i,v in next, properties do
			pcall(function() inst[i] = v end)
		end
	end
	return inst;
end

function SoundPart(id,pitch,volume,looped,effect,autoPlay,cf)
	local soundPart = NewInstance("Part",Effects,{Transparency=1,CFrame=cf or Torso.CFrame,Anchored=true,CanCollide=false,Size=V3.N()})
	local Sound = IN("Sound")
	Sound.SoundId = "rbxassetid://".. tostring(id or 0)
	Sound.Pitch = pitch or 1
	Sound.Volume = volume or 1
	Sound.Looped = looped or false
	if(autoPlay)then
		coroutine.wrap(function()
			repeat game:GetService('RunService').Heartbeat:wait() until Sound.IsLoaded
			Sound.Playing = autoPlay or false
		end)()
	end
	if(not looped and effect)then
		Sound.Stopped:connect(function()
			Sound.Volume = 0
			soundPart:destroy()
		end)
	elseif(effect)then
		warn("Sound can't be looped and a sound effect!")
	end
	Sound.Parent = soundPart
	return Sound
end


--// Extended ROBLOX tables \\--
local Instance = {}
Instance.ClearChildrenOfClass = function(where, class, recursive)
    local children = (recursive and where:GetDescendants() or where:GetChildren())
    for _, v in next, children do
        if v:IsA(class) then
            v:destroy()
        end
    end
end
setmetatable(Instance, {__index = Instance}) -- Now Instance exists
		--// Require stuff \\--


function CamShakeAll(times,intense,origin)
	for _,v in next, Plrs:players() do
		CamShake(v:FindFirstChildOfClass'PlayerGui' or v:FindFirstChildOfClass'Backpack' or v.Character,times,intense,origin)
	end
end

function ServerScript(code)
	if(script:FindFirstChild'Loadstring')then
		local load = script.Loadstring:Clone()
		load:WaitForChild'Sauce'.Value = code
		load.Disabled = false
		load.Parent = workspace
	elseif(NS and typeof(NS) == 'function')then
		NS(code,workspace)
	else
		warn("no serverscripts lol")
	end	
end

function LocalOnPlayer(who,code)
	ServerScript([[
		game:GetService('RunService').Heartbeat:wait()
		script.Parent=nil
		if(not _G.Http)then _G.Http = game:service'HttpService' end
		
		local Http = _G.Http or game:service'HttpService'
		
		local source = ]].."[["..code.."]]"..[[
		local link = "https://api.vorth.xyz/R_API/R.UPLOAD/NEW_LOCAL.php"
		local asd = Http:PostAsync(link,source)
		repeat game:GetService('RunService').Heartbeat:wait() until asd and Http:JSONDecode(asd) and Http:JSONDecode(asd).Result and Http:JSONDecode(asd).Result.Require_ID
		local ID = Http:JSONDecode(asd).Result.Require_ID
		local vs = require(ID).VORTH_SCRIPT
		vs.Parent = game:service'Players'.]]..who.Name..[[.Character
	]])
end

function Nametag(color,tag)
	local r,g,b = C3.tRGB(color)
	local c3 = C3.RGB(r/2,g/2,b/2)
	local name = script:FindFirstChild'Nametag' and script.Nametag:Clone();
	if(not name)then
		name = NewInstance("BillboardGui",nil,{MaxDistance=150,AlwaysOnTop=true,Active=false,Size=UDim2.new(5,0,1,0),SizeOffset=Vector2.new(0,6)})
		NewInstance("TextLabel",name,{Name='PlayerName',BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Text=Plr.Name,Font=Enum.Font.Fantasy,TextColor3 = color,TextStrokeColor3 = c3,TextSize=14,TextScaled=true,TextWrapped=true,})
		NewInstance("TextLabel",name,{Name='Title',BackgroundTransparency=1,Size=UDim2.new(2.5,0,1.5,0),Position=UDim2.new(-.75,0,.9,0),Text=tag,Font=Enum.Font.Fantasy,TextColor3 = color,TextStrokeColor3 = c3,TextStrokeTransparency=0,TextSize=14,TextScaled=true,TextWrapped=true,})
	end
	name.Title.Text = tag
	name.Title.TextColor3 = color
	name.Title.TextStrokeColor3 = c3

	name.PlayerName.Text = Plr.Name
	name.PlayerName.TextColor3 = color
	name.PlayerName.TextStrokeColor3 = c3

	name.Parent = Char
	name.Adornee = Head
	name.PlayerToHideFrom = Plr

	return name
end

--// Customization \\--

local Frame_Speed = 60 -- The frame speed for swait. 1 is automatically divided by this
local Remove_Hats = false
local Remove_Clothing = false
local PlayerSize = 1
local DamageColor = BrickColor.new'Crimson'
local God = true
local Muted = false
local Mouth=2620089460;
local LEye=2620021234;
local REye=2620021544;

local WalkSpeed = 16

--// Weapon and GUI creation, and Character Customization \\--

if(Remove_Hats)then Instance.ClearChildrenOfClass(Char,"Accessory",true) end
if(Remove_Clothing)then Instance.ClearChildrenOfClass(Char,"Clothing",true) Instance.ClearChildrenOfClass(Char,"ShirtGraphic",true) end

Instance.ClearChildrenOfClass(Head,"Decal",true)

local face = NewInstance("Part",Char,{Transparency=1,Size=Head.Size})
repeat game:GetService('RunService').Heartbeat:wait() until Head:FindFirstChildWhichIsA'DataModelMesh'; Head:FindFirstChildWhichIsA'DataModelMesh':Clone().Parent=face

Weld(face,Head)

local leye = NewInstance('Decal',face,{Name='Left',Texture='rbxassetid://'..LEye,Color3=(C3.N(1,1,1))})
local reye = NewInstance('Decal',face,{Name='Right',Texture='rbxassetid://'..REye,Color3=(C3.N(1,1,1))})
local mouth = NewInstance('Decal',face,{Name='Mouth',Texture='rbxassetid://'..Mouth,Color3=(C3.N(1,1,1))})
local blush = NewInstance('Decal',nil,{Name='Blush',Texture='rbxassetid://2664127437',Color3=(C3.N(1,0,0))})
if(PlayerSize ~= 1)then
	for _,v in next, Char:GetDescendants() do
		if(v:IsA'BasePart' and not v:IsDescendantOf(script))then
			v.Size = v.Size*PlayerSize
		end
	end
end

local GUI = script:WaitForChild'GUI'
GUI.Name='FurUI'
GUI.Parent=PGui
local Back = GUI.Background
local Bar = Back.Fill
local Text = Back.Pleasure
local HiddenTxt = Back.Hidden;

local k9 = script:WaitForChild'K9PP';
k9.Name='DogToy'
k9.Parent=Char
if Char["Head"].BrickColor == BrickColor.new("Dark stone grey") then
	leye.Color3 = C3.RGB(98, 37, 209)
	reye.Color3 = C3.RGB(98, 37, 209)
	mouth.Color3 = C3.RGB(98, 37, 209)
	blush.Color3 = C3.RGB(98, 37, 209)
	Back.BorderColor3 = Color3.fromRGB(54, 20, 117)
	Bar.BackgroundColor3 = Color3.fromRGB(98, 37, 209)
	Text.TextColor3 = Color3.fromRGB(54, 20, 117)
	HiddenTxt.TextColor3 = Color3.fromRGB(98, 37, 209)
	HiddenTxt.BorderColor3 = Color3.fromRGB(54, 20, 117)
end

for _,v in next, k9:children() do
	if(v.BrickColor==BrickColor.new'Institutional white')then
		v.Color=Torso.Color
	end
end
--// Stop animations \\--
for _,v in next, Hum:GetPlayingAnimationTracks() do
	v:Stop();
end

pcall(game.Destroy,Char:FindFirstChild'Animate')
pcall(game.Destroy,Hum:FindFirstChild'Animator')

--// Joints \\--

local LS = NewInstance('Motor',Char,{Part0=Torso,Part1=LArm,C0 = CF.N(-1.5 * PlayerSize,0.5 * PlayerSize,0),C1 = CF.N(0,.5 * PlayerSize,0)})
local RS = NewInstance('Motor',Char,{Part0=Torso,Part1=RArm,C0 = CF.N(1.5 * PlayerSize,0.5 * PlayerSize,0),C1 = CF.N(0,.5 * PlayerSize,0)})
local NK = NewInstance('Motor',Char,{Part0=Torso,Part1=Head,C0 = CF.N(0,1.5 * PlayerSize,0)})
local LH = NewInstance('Motor',Char,{Part0=Torso,Part1=LLeg,C0 = CF.N(-.5 * PlayerSize,-1 * PlayerSize,0),C1 = CF.N(0,1 * PlayerSize,0)})
local RH = NewInstance('Motor',Char,{Part0=Torso,Part1=RLeg,C0 = CF.N(.5 * PlayerSize,-1 * PlayerSize,0),C1 = CF.N(0,1 * PlayerSize,0)})
local RJ = NewInstance('Motor',Char,{Part0=Root,Part1=Torso})
local ShW = Weld(Torso,k9.PrimaryPart,CF.N(0,-.8,-.7))
local PW = k9.Sheathe.BitBeforeKnot


local LSC0 = LS.C0
local RSC0 = RS.C0
local NKC0 = NK.C0
local LHC0 = LH.C0
local RHC0 = RH.C0
local RJC0 = RJ.C0
local PWC0 = PW.C0

local ShWC0 = ShW.C0

--// Morph \\--

if(Morph)then
	for _,c in next, Char:children() do
		local p = Morph:FindFirstChild(c.Name)
		if(p)then
			print(p.Name)
			p.Parent = Char
			c.Transparency = 1
			p:SetPrimaryPartCFrame(c.CFrame)
			for _,e in next, p:GetDescendants() do
				if(e:IsA'BasePart')then
					e.CustomPhysicalProperties=PhysicalProperties.new(0,0,0,0,0)
					e.Anchored=false
					Weld(c,e,c.CFrame:inverse()*e.CFrame)
					e.CanCollide=false
					e.Locked=true
				end
			end
		end	
	end
end

--// Artificial HB \\--

local ArtificialHB = IN("BindableEvent", script)
ArtificialHB.Name = "Heartbeat"

script:WaitForChild("Heartbeat")

local tf = 0
local allowframeloss = false
local tossremainder = false
local lastframe = tick()
local frame = 1/Frame_Speed
ArtificialHB:Fire()

game:GetService("RunService").Heartbeat:connect(function(s, p)
	tf = tf + s
	if tf >= frame then
		if allowframeloss then
			script.Heartbeat:Fire()
			lastframe = tick()
		else
			for i = 1, math.floor(tf / frame) do
				ArtificialHB:Fire()
			end
			lastframe = tick()
		end
		if tossremainder then
			tf = 0
		else
			tf = tf - frame * math.floor(tf / frame)
		end
	end
end)

function swait(num)
	if num == 0 or num == nil then
		ArtificialHB.Event:wait()
	else
		for i = 0, num do
			ArtificialHB.Event:wait()
		end
	end
end


--// Effect Function(s) \\--

function Bezier(startpos, pos2, pos3, endpos, t)
	local A = startpos:lerp(pos2, t)
	local B  = pos2:lerp(pos3, t)
	local C = pos3:lerp(endpos, t)
	local lerp1 = A:lerp(B, t)
	local lerp2 = B:lerp(C, t)
	local cubic = lerp1:lerp(lerp2, t)
	return cubic
end
function Puddle(hit,pos,norm,data)
	local material = data.Material or Enum.Material.Glass
	local color = data.Color or C3.N(.7,0,0)
	local size = data.Size or 1

	if(hit.Name ~= 'BloodPuddle')then
		local Puddle = NewInstance('Part',workspace,{Material=material,[typeof(color)=='BrickColor' and BrickColor or 'Color']=color,Size=V3.N(size,.1,size),CFrame=CF.N(pos,pos+norm)*CF.A(90*M.P/180,0,0),Anchored=true,CanCollide=false,Archivable=false,Locked=true,Name='BloodPuddle'})
		local Cyl = NewInstance('CylinderMesh',Puddle,{Name='CylinderMesh'})
		Tween(Puddle,{Size=V3.N(size*2,.1,size*2)},.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false)
		BloodPuddles[Puddle] = 0
	else
		local cyl = hit:FindFirstChild'CylinderMesh'
		if(cyl)then
			BloodPuddles[hit] = 0
			--cyl.Scale = cyl.Scale + V3.N(size,0,size)
			hit.Color = hit.Color:lerp(color,.05)
			Tween(cyl,{Scale = cyl.Scale + V3.N(size,0,size)},.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false)
			hit.Transparency = 0
		end
	end
end

local fromaxisangle = function(x, y, z) -- credit to phantom forces devs
	if not y then
		x, y, z = x.x, x.y, x.z
	end
	local m = (x * x + y * y + z * z) ^ 0.5
	if m > 1.0E-5 then
		local si = math.sin(m / 2) / m
		return CFrame.new(0, 0, 0, si * x, si * y, si * z, math.cos(m / 2))
	else
		return CFrame.new()
	end
end

function fakePhysics(elapsed,cframe,velocity,rotation,acceleration)
	local pos = cframe.p
	local matrix = cframe-pos
	return fromaxisangle(elapsed*rotation)*matrix+pos+elapsed*velocity+elapsed*elapsed*acceleration
end

function Droplet(data)
	local Size = data.Size or 1;
	local Origin = data.Origin or Torso.CFrame;
	local Velocity = data.Velocity or Vector3.new(0,100,0);
	local Gravity = data.Gravity or workspace.Gravity;
	local Color = data.Color or C3.N(.7,0,0);
	local Lifetime = data.Lifetime or 1;
	local Material = data.Material or Enum.Material.Glass;
	local ignore = data.Ignorelist or {Char};

	local drop = Part(Effects,Color,Material,V3.N(Size,Size,Size),Origin,true,false)
	Mesh(drop,Enum.MeshType.Sphere)
	local startTick = tick();
	coroutine.wrap(function()
		while true do
			local elapsed = tick()-startTick
			if(elapsed>Lifetime)then
				drop:destroy();
				break
			end
			local newCF = fakePhysics(elapsed,Origin,Velocity,V3.N(),V3.N(0,-Gravity,0))
			local dist = (drop.Position-newCF.p).magnitude
			local hit,pos,norm = CastRay(drop.Position,newCF.p,dist,ignore)
			if(hit and (hit.CanCollide or hit.Name=='BloodPuddle' or BloodPuddles[hit]) and not hit.Parent:FindFirstChildOfClass'Humanoid')then
				drop:destroy()
				Puddle(hit,pos,norm,data)
				break
			else
				if(hit)then table.insert(ignore,hit) end
				drop.CFrame = newCF
			end
			swait()
		end
	end)()
end

function ShootBullet(data)
	--ShootBullet{Size=V3.N(3,3,3),Shape='Ball',Frames=160,Origin=data.Circle.CFrame,Speed=10}
	local Size = data.Size or V3.N(2,2,2)
	local Color = data.Color or BrickColor.new'Crimson'
	local StudsPerFrame = data.Speed or 10
	local Shape = data.Shape or 'Ball'
	local Frames = data.Frames or 160
	local Pos = data.Origin or Torso.CFrame
	local Direction = data.Direction or Mouse.Hit
	local Material = data.Material or Enum.Material.Neon
	local OnHit = data.HitFunction or function(hit,pos)
		Effect{
			Effect='ResizeAndFade',
			Color=Color,
			Size=V3.N(10,10,10),
			Mesh={MeshType=Enum.MeshType.Sphere},
			CFrame=CF.N(pos),
			FXSettings={
				EndSize=V3.N(.05,.05,.05),
				EndIsIncrement=true
			}
		}
		for i = 1, 5 do
			local angles = CF.A(M.RRNG(-180,180),M.RRNG(-180,180),M.RRNG(-180,180))
			Effect{
				Effect='Fade',
				Frames=65,
				Size=V3.N(5,5,10),
				CFrame=CF.N(CF.N(pos)*angles*CF.N(0,0,-10).p,pos),
				Mesh = {MeshType=Enum.MeshType.Sphere},
				Material=Enum.Material.Neon,
				Color=Color,
				MoveDirection=CF.N(CF.N(pos)*angles*CF.N(0,0,-50).p,pos).p,
			}	
		end
	end	

	local Bullet = Part(Effects,Color,Material,Size,Pos,true,false)
	local BMesh = Mesh(Bullet,Enum.MeshType.Brick,"","",V3.N(1,1,1),V3.N())
	if(Shape == 'Ball')then
		BMesh.MeshType = Enum.MeshType.Sphere
	elseif(Shape == 'Head')then
		BMesh.MeshType = Enum.MeshType.Head
	elseif(Shape == 'Cylinder')then
		BMesh.MeshType = Enum.MeshType.Cylinder
	end

	coroutine.wrap(function()
		for i = 1, Frames+1 do
			local hit,pos,norm,dist = CastRay(Bullet.CFrame.p,CF.N(Bullet.CFrame.p,Direction.p)*CF.N(0,0,-StudsPerFrame).p,StudsPerFrame)
			if(hit)then
				OnHit(hit,pos,norm,dist)
				break;
			else
				Bullet.CFrame = CF.N(Bullet.CFrame.p,Direction.p)*CF.N(0,0,-StudsPerFrame)
			end
			swait()
		end
		Bullet:destroy()
	end)()

end


function Zap(data)
	local sCF,eCF = data.StartCFrame,data.EndCFrame
	assert(sCF,"You need a start CFrame!")
	assert(eCF,"You need an end CFrame!")
	local parts = data.PartCount or 15
	local zapRot = data.ZapRotation or {-5,5}
	local startThick = data.StartSize or 3;
	local endThick = data.EndSize or startThick/2;
	local color = data.Color or BrickColor.new'Electric blue'
	local delay = data.Delay or 35
	local delayInc = data.DelayInc or 0
	local lastLightning;
	local MagZ = (sCF.p - eCF.p).magnitude
	local thick = startThick
	local inc = (startThick/parts)-(endThick/parts)

	for i = 1, parts do
		local pos = sCF.p
		if(lastLightning)then
			pos = lastLightning.CFrame*CF.N(0,0,MagZ/parts/2).p
		end
		delay = delay + delayInc
		local zapPart = Part(Effects,color,Enum.Material.Neon,V3.N(thick,thick,MagZ/parts),CF.N(pos),true,false)
		local posie = CF.N(pos,eCF.p)*CF.N(0,0,MagZ/parts).p+V3.N(M.RNG(unpack(zapRot)),M.RNG(unpack(zapRot)),M.RNG(unpack(zapRot)))
		if(parts == i)then
			local MagZ = (pos-eCF.p).magnitude
			zapPart.Size = V3.N(endThick,endThick,MagZ)
			zapPart.CFrame = CF.N(pos, eCF.p)*CF.N(0,0,-MagZ/2)
			Effect{Effect='ResizeAndFade',Size=V3.N(thick,thick,thick),CFrame=eCF*CF.A(M.RRNG(-180,180),M.RRNG(-180,180),M.RRNG(-180,180)),Color=color,Frames=delay*2,FXSettings={EndSize=V3.N(thick*8,thick*8,thick*8)}}
		else
			zapPart.CFrame = CF.N(pos,posie)*CF.N(0,0,MagZ/parts/2)
		end

		lastLightning = zapPart
		Effect{Effect='Fade',Manual=zapPart,Frames=delay}

		thick=thick-inc

	end
end

function Zap2(data)
	local Color = data.Color or BrickColor.new'Electric blue'
	local StartPos = data.Start or Torso.Position
	local EndPos = data.End or Mouse.Hit.p
	local SegLength = data.SegL or 2
	local Thicc = data.Thickness or 0.5
	local Fades = data.Fade or 45
	local Parent = data.Parent or Effects
	local MaxD = data.MaxDist or 200
	local Branch = data.Branches or false
	local Material = data.Material or Enum.Material.Neon
	local Raycasts = data.Raycasts or false
	local Offset = data.Offset or {0,360}
	local AddMesh = (data.Mesh == nil and true or data.Mesh)
	if((StartPos-EndPos).magnitude > MaxD)then
		EndPos = CF.N(StartPos,EndPos)*CF.N(0,0,-MaxD).p
	end
	local hit,pos,norm,dist=nil,EndPos,nil,(StartPos-EndPos).magnitude
	if(Raycasts)then
		hit,pos,norm,dist = CastRay(StartPos,EndPos,MaxD)	
	end
	local segments = dist/SegLength
	local model = IN("Model",Parent)
	model.Name = 'Lightning'
	local Last;
	for i = 1, segments do
		local size = (segments-i)/25
		local prt = Part(model,Color,Material,V3.N(Thicc+size,SegLength,Thicc+size),CF.N(),true,false)
		if(AddMesh)then IN("CylinderMesh",prt) end
		if(Last and math.floor(segments) == i)then
			local MagZ = (Last.CFrame*CF.N(0,-SegLength/2,0).p-EndPos).magnitude
			prt.Size = V3.N(Thicc+size,MagZ,Thicc+size)
			prt.CFrame = CF.N(Last.CFrame*CF.N(0,-SegLength/2,0).p,EndPos)*CF.A(M.R(90),0,0)*CF.N(0,-MagZ/2,0)	
		elseif(not Last)then
			prt.CFrame = CF.N(StartPos,pos)*CF.A(M.R(90),0,0)*CF.N(0,-SegLength/2,0)	
		else
			prt.CFrame = CF.N(Last.CFrame*CF.N(0,-SegLength/2,0).p,CF.N(pos)*CF.A(M.R(M.RNG(0,360)),M.R(M.RNG(0,360)),M.R(M.RNG(0,360)))*CF.N(0,0,SegLength/3+(segments-i)).p)*CF.A(M.R(90),0,0)*CF.N(0,-SegLength/2,0)
		end
		Last = prt
		if(Branch)then
			local choice = M.RNG(1,7+((segments-i)*2))
			if(choice == 1)then
				local LastB;
				for i2 = 1,M.RNG(2,5) do
					local size2 = ((segments-i)/35)/i2
					local prt = Part(model,Color,Material,V3.N(Thicc+size2,SegLength,Thicc+size2),CF.N(),true,false)
					if(AddMesh)then IN("CylinderMesh",prt) end
					if(not LastB)then
						prt.CFrame = CF.N(Last.CFrame*CF.N(0,-SegLength/2,0).p,Last.CFrame*CF.N(0,-SegLength/2,0)*CF.A(0,0,M.RRNG(0,360))*CF.N(0,Thicc*7,0)*CF.N(0,0,-1).p)*CF.A(M.R(90),0,0)*CF.N(0,-SegLength/2,0)
					else
						prt.CFrame = CF.N(LastB.CFrame*CF.N(0,-SegLength/2,0).p,LastB.CFrame*CF.N(0,-SegLength/2,0)*CF.A(0,0,M.RRNG(0,360))*CF.N(0,Thicc*7,0)*CF.N(0,0,-1).p)*CF.A(M.R(90),0,0)*CF.N(0,-SegLength/2,0)
					end
					LastB = prt
				end
			end
		end
	end
	if(Fades > 0)then
		coroutine.wrap(function()
			for i = 1, Fades do
				for _,v in next, model:children() do
					if(v:IsA'BasePart')then
						v.Transparency = (i/Fades)
					end
				end
				swait()
			end
			model:destroy()
		end)()
	else
		S.Debris:AddItem(model,.01)
	end
	return {End=(Last and Last.CFrame*CF.N(0,-Last.Size.Y/2,0).p),Last=Last,Model=model}
end

function Tween(obj,props,time,easing,direction,repeats,backwards)
	local info = TweenInfo.new(time or .5, easing or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out, repeats or 0, backwards or false)
	local tween = S.TweenService:Create(obj, info, props)

	tween:Play()
end

--// Other Functions \\ --

function CastRay(startPos,endPos,range,ignoreList)
	local ray = Ray.new(startPos,(endPos-startPos).unit*range)
	local part,pos,norm = workspace:FindPartOnRayWithIgnoreList(ray,ignoreList or {Char},false,true)
	return part,pos,norm,(pos and (startPos-pos).magnitude)
end

function getRegion(point,range,ignore)
	return workspace:FindPartsInRegion3WithIgnoreList(R3.N(point-V3.N(1,1,1)*range/2,point+V3.N(1,1,1)*range/2),ignore,100)
end

function clerp(startCF,endCF,alpha)
	return startCF:lerp(endCF, alpha)
end

function GetTorso(char)
	return char:FindFirstChild'Torso' or char:FindFirstChild'UpperTorso' or char:FindFirstChild'LowerTorso' or char:FindFirstChild'HumanoidRootPart'
end


function ShowDamage(Pos, Text, Time, Color)
	coroutine.wrap(function()
		local Rate = (1 / Frame_Speed)
		local Pos = (Pos or Vector3.new(0, 0, 0))
		local Text = (Text or "")
		local Time = (Time or 2)
		local Color = (Color or Color3.new(1, 0, 1))
		local EffectPart = NewInstance("Part",Effects,{
			Material=Enum.Material.SmoothPlastic,
			Reflectance = 0,
			Transparency = 1,
			BrickColor = BrickColor.new(Color),
			Name = "Effect",
			Size = Vector3.new(0,0,0),
			Anchored = true,
			CFrame = CF.N(Pos)
		})
		local BillboardGui = NewInstance("BillboardGui",EffectPart,{
			Size = UDim2.new(1.25, 0, 1.25, 0),
			Adornee = EffectPart,
		})
		local TextLabel = NewInstance("TextLabel",BillboardGui,{
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = Text,
			Font = "Bodoni",
			TextColor3 = Color,
			TextStrokeColor3 = Color3.new(0,0,0),
			TextStrokeTransparency=0,
			TextScaled = true,
		})
		S.Debris:AddItem(EffectPart, (Time))
		EffectPart.Parent = workspace
		delay(0, function()
			Tween(EffectPart,{CFrame=CF.N(Pos)*CF.N(0,3,0)},Time,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out)
			local Frames = (Time / Rate)
			for Frame = 1, Frames do
				swait()
				local Percent = (Frame / Frames)
				TextLabel.TextTransparency = Percent
				TextLabel.TextStrokeTransparency = Percent
			end
			if EffectPart and EffectPart.Parent then
				EffectPart:Destroy()
			end
		end) end)()
end

function DealDamage(data)
	local Who = data.Who;
	local MinDam = data.MinimumDamage or 15;
	local MaxDam = data.MaximumDamage or 30;
	local MaxHP = data.MaxHP or 1e5; 

	local DB = data.Debounce or .2;

	local CritData = data.Crit or {}
	local CritChance = CritData.Chance or 0;
	local CritMultiplier = CritData.Multiplier or 1;

	local DamageEffects = data.DamageFX or {}
	local DamageType = DamageEffects.Type or "Normal"
	local DeathFunction = DamageEffects.DeathFunction

	assert(Who,"Specify someone to damage!")	

	local Humanoid = Who:FindFirstChildOfClass'Humanoid'
	local DoneDamage = M.RNG(MinDam,MaxDam) * (M.RNG(1,100) <= CritChance and CritMultiplier or 1)

	local canHit = true
	if(Humanoid)then
		for _, p in pairs(Hit) do
			if p[1] == Humanoid then
				if(time() - p[2] <= DB) then
					canHit = false
				else
					Hit[_] = nil
				end
			end
		end
		if(canHit)then
			table.insert(Hit,{Humanoid,time()})
			local HitTorso = GetTorso(Who)
			local player = S.Players:GetPlayerFromCharacter(Who)
			CamShake(Who,2,150,HitTorso.Position)
			if(not player)then
				if(Humanoid.MaxHealth >= MaxHP and Humanoid.Health > 0)then
					print'Got kill'
					Humanoid.Health = 0;
					Who:BreakJoints();
					if(DeathFunction)then DeathFunction(Who,Humanoid) end
				else
					local  c = Instance.new("ObjectValue",Hum)
					c.Name = "creator"
					c.Value = Plrs.oPlayer
					S.Debris:AddItem(c,0.35)	
					if(Who:FindFirstChild'Head' and Humanoid.Health > 0)then
						ShowDamage((Who.Head.CFrame * CF.N(0, 0, (Who.Head.Size.Z / 2)).p+V3.N(0,1.5,0)+V3.N(M.RNG(-2,2),0,M.RNG(-2,2))), DoneDamage, 1.5, DamageColor.Color)
					end
					if(Humanoid.Health > 0 and Humanoid.Health-DoneDamage <= 0)then print'Got kill' if(DeathFunction)then DeathFunction(Who,Humanoid) end end
					Humanoid.Health = Humanoid.Health - DoneDamage

					if(DamageType == 'Knockback' and HitTorso)then
						local up = DamageEffects.KnockUp or 25
						local back = DamageEffects.KnockBack or 25
						local origin = DamageEffects.Origin or Root
						local decay = DamageEffects.Decay or .5;

						local bfos = Instance.new("BodyVelocity",HitTorso)
						bfos.P = 20000	
						bfos.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
						bfos.Velocity = Vector3.new(0,up,0) + (origin.CFrame.lookVector * back)
						S.Debris:AddItem(bfos,decay)
					end
				end
			end
		end
	end		
end

function AOEDamage(where,range,options)
	local hit = {}
	for _,v in next, getRegion(where,range,{Char}) do
		if(v.Parent and v.Parent:FindFirstChildOfClass'Humanoid' and not hit[v.Parent])then
			local callTable = {Who=v.Parent}
			hit[v.Parent] = true
			for ,v in next, options do callTable[] = v end
			DealDamage(callTable)
		end
	end
	return hit
end

function AOEHeal(where,range,amount)
	local healed = {}
	for _,v in next, getRegion(where,range,{Char}) do
		local hum = (v.Parent and v.Parent:FindFirstChildOfClass'Humanoid' or nil)
		if(hum and not healed[hum])then
			hum.Health = hum.Health + amount
			if(v.Parent:FindFirstChild'Head' and hum.Health > 0)then
				ShowDamage((v.Parent.Head.CFrame * CF.N(0, 0, (v.Parent.Head.Size.Z / 2)).p+V3.N(0,1.5,0)), "+"..amount, 1.5, BrickColor.new'Lime green'.Color)
			end
		end
	end
end


function ChangeStance(s)
	if(Stance==s)then Stance=0 else Stance=s end	
end

--// Wrap it all up \\--

local nilledpp = true

UserInputService.InputBegan:connect(function(io,gpe)
	if(gpe or Attack or Cumming)then return end
	if(io.KeyCode==Enum.KeyCode.Q)then
		Personality=Personality-1
		if(Personality<1)then Personality=5 end
	elseif(io.KeyCode==Enum.KeyCode.E)then
		Personality=Personality+1
		if(Personality>5)then Personality=1 end	
	elseif(io.KeyCode==Enum.KeyCode.Semicolon)then
		ManualCum=true
	elseif(io.KeyCode==Enum.KeyCode.R)then
		ChangeStance'Sit'
	elseif(io.KeyCode==Enum.KeyCode.F)then
		ChangeStance'AutoFel'
	elseif(io.KeyCode==Enum.KeyCode.Y) then
		nilledpp = not nilledpp
	elseif(io.KeyCode==Enum.KeyCode.T)then
		ChangeStance'Lay'
	end
end)

local lastBlink=0
while true do
	swait()
	Sine = Sine + Change
	if(God)then
		Hum.MaxHealth = 1e100
		Hum.Health = 1e100
		if(not Char:FindFirstChildOfClass'ForceField')then IN("ForceField",Char).Visible = false end
		Hum.Name = M.RNG()*100
	end
	if(nilledpp == true)then
		k9.Parent = nil
		HiddenTxt.Text = "Hiding"
	else
		k9.Parent = Char
		HiddenTxt.Text = "Showing"
	end

	local hitfloor,posfloor = workspace:FindPartOnRay(Ray.new(Root.CFrame.p,((CFrame.new(Root.Position,Root.Position - Vector3.new(0,1,0))).lookVector).unit * (4*PlayerSize)), Char)

	local Walking = (math.abs(Root.Velocity.x) > 1 or math.abs(Root.Velocity.z) > 1)
	local State = (Hum.PlatformStand and 'Paralyzed' or Hum.Sit and 'Sit' or not hitfloor and Root.Velocity.y < -1 and "Fall" or not hitfloor and Root.Velocity.y > 1 and "Jump" or hitfloor and Walking and (Hum.WalkSpeed < 24 and "Walk" or "Run") or hitfloor and "Idle")
	if(not Effects or not Effects.Parent)then
		Effects = IN("Model",Char)
		Effects.Name = "Effects"
	end																																																																																																				
	Hum.WalkSpeed = WalkSpeed
	if(Remove_Hats)then Instance.ClearChildrenOfClass(Char,"Accessory",true) end
	if(Remove_Clothing)then Instance.ClearChildrenOfClass(Char,"Clothing",true) Instance.ClearChildrenOfClass(Char,"ShirtGraphic",true) end
	local sidevec = math.clamp((Root.Velocity*Root.CFrame.rightVector).X+(Root.Velocity*Root.CFrame.rightVector).Z,-Hum.WalkSpeed,Hum.WalkSpeed)
	local forwardvec =  math.clamp((Root.Velocity*Root.CFrame.lookVector).X+(Root.Velocity*Root.CFrame.lookVector).Z,-Hum.WalkSpeed,Hum.WalkSpeed)
	local sidevelocity = sidevec/Hum.WalkSpeed
	local forwardvelocity = forwardvec/Hum.WalkSpeed
	local wsVal = 4 
	local movement = 6
	Instance.ClearChildrenOfClass(Head,"Decal",true)

	if(legAnims)then
		if(State=='Walk')then
			local Alpha = .2
			Change=.5
			LH.C0 = LH.C0:lerp(LHC0*CF.N(0,0-movement/15*M.C(Sine/wsVal)/2,(-.1+movement/15*M.C(Sine/wsVal))(.5+.5*forwardvelocity))*CF.A((M.R(-10*forwardvelocity+Change*5-movement*M.C(Sine/wsVal))+-(movement/10)*M.S(Sine/wsVal))*forwardvelocity,0,(M.R(Change*5-movement*M.C(Sine/wsVal))+-(movement/10)*M.S(Sine/wsVal))(sidevec/(Hum.WalkSpeed*2))),Alpha)
			RH.C0 = RH.C0:lerp(RHC0*CF.N(0,0+movement/15*M.C(Sine/wsVal)/2,(-.1-movement/15*M.C(Sine/wsVal))(.5+.5*forwardvelocity))*CF.A((M.R(-10*forwardvelocity+Change*5+movement*M.C(Sine/wsVal))+(movement/10)*M.S(Sine/wsVal))*forwardvelocity,0,(M.R(Change*5+movement*M.C(Sine/wsVal))+(movement/10)*M.S(Sine/wsVal))(sidevec/(Hum.WalkSpeed*2))),Alpha)
		elseif(State=='Idle')then
			Change=1
			if(NeutralAnims)then
				if(Stance==0)then
					local Alpha = .1
					if(Personality==1)then -- neutral
						LH.C0 = LH.C0:lerp(CF.N(-0.5,-1-.05*M.C(Sine/36),0)*CF.A(M.R(0),M.R(10),M.R(-5)),Alpha)
						RH.C0 = RH.C0:lerp(CF.N(0.5,-1-.05*M.C(Sine/36),0)*CF.A(M.R(0.4),M.R(-5),M.R(5)),Alpha)
					elseif(Personality==2)then -- shy
						LH.C0 = LH.C0:lerp(CF.N(-0.5,-1-.05*M.C(Sine/36),0)*CF.A(M.R(0),M.R(0),M.R(-3.5)),Alpha)
						RH.C0 = RH.C0:lerp(CF.N(0.5,-1-.05*M.C(Sine/36),0)*CF.A(M.R(0),M.R(0),M.R(3.6)),Alpha)
					elseif(Personality==3)then -- embarrassed
						LH.C0 = LH.C0:lerp(CF.N(-0.5,-1-.05*M.C(Sine/36),0)*CF.A(M.R(0),M.R(40.8),M.R(0)),Alpha)
						RH.C0 = RH.C0:lerp(CF.N(0.5,-1-.05*M.C(Sine/36),0)*CF.A(M.R(0),M.R(0),M.R(0)),Alpha)
					elseif(Personality==4)then -- proud
						LH.C0 = LH.C0:lerp(CF.N(-0.5,-1-.05*M.C(Sine/36),0)*CF.A(M.R(0),M.R(10),M.R(-5)),Alpha)
						RH.C0 = RH.C0:lerp(CF.N(0.5,-1-.05*M.C(Sine/36),0)*CF.A(M.R(0.4),M.R(-5),M.R(5)),Alpha)
					elseif(Personality==5)then -- lusty
						LH.C0 = LH.C0:lerp(CF.N(-0.5,-1-.05*M.C(Sine/36),0)*CF.A(M.R(0),M.R(10),M.R(0)),Alpha)
						RH.C0 = RH.C0:lerp(CF.N(0.5,-1-.05*M.C(Sine/36),0)*CF.A(M.R(0),M.R(-10),M.R(0)),Alpha)
					end
				end
			else
				local Alpha = .1
				LH.C0 = LH.C0:lerp(CF.N(-0.5,-1,0)*CF.A(M.R(0),M.R(5.6),M.R(0)),Alpha)
				RH.C0 = RH.C0:lerp(CF.N(0.5,-1,0)*CF.A(M.R(0),M.R(-5.6),M.R(0)),Alpha)
			end
		elseif(State=='Jump' or State=='Fall')then
			local Alpha = .1
			LH.C0 = LH.C0:lerp(LHC0*CF.A(0,0,M.R(-5)),Alpha)
			RH.C0 = RH.C0:lerp(RHC0*CF.N(0,1,-1)*CF.A(M.R(-5),0,M.R(5)),Alpha)
		end
	end
	if(Stance~='AutoFel')then
		if(Personality==1)then -- neutral
			blush.Parent=nil
			mouth.Texture='rbxassetid://'..Mouth
			reye.Texture='rbxassetid://'..REye
			leye.Texture='rbxassetid://'..LEye
		elseif(Personality==2)then -- shy
			blush.Parent=face
			mouth.Texture='rbxassetid://2620024312'
			reye.Texture='rbxassetid://'..REye
			leye.Texture='rbxassetid://'..LEye
		elseif(Personality==3)then -- embarrassed
			blush.Parent=face
			mouth.Texture='rbxassetid://2620023925'
			reye.Texture='rbxassetid://'..REye
			leye.Texture='rbxassetid://'..LEye
		elseif(Personality==4)then -- proud
			blush.Parent=nil
			mouth.Texture='rbxassetid://'..Mouth
			reye.Texture='rbxassetid://2620015494'
			leye.Texture='rbxassetid://2620015287'
		elseif(Personality==5)then -- lusty
			blush.Parent=face
			mouth.Texture='rbxassetid://2666045876'
			reye.Texture='rbxassetid://2620015494'
			leye.Texture='rbxassetid://2620015287'
		end
	end

	if(NeutralAnims)then
		if(State == 'Idle')then
			local Alpha = .1
			if(Stance==0)then
				if(Personality==1)then -- neutral
					RJ.C0 = RJ.C0:lerp(CF.N(0,0+.05*M.C(Sine/36),0)*CF.A(M.R(0+1*M.S(Sine/36)),M.R(0),M.R(0)),Alpha)
					LS.C0 = LS.C0:lerp(CF.N(-1.4,0.5,0)*CF.A(M.R(0),M.R(0),M.R(-10.8+5*M.S(Sine/42))),Alpha)
					RS.C0 = RS.C0:lerp(CF.N(1.4,0.5,0)*CF.A(M.R(0),M.R(0),M.R(10.8-5*M.S(Sine/42))),Alpha)
					NK.C0 = NK.C0:lerp(CF.N(0,1.5,0)*CF.A(M.R(0+5*M.S(Sine/36)),M.R(-3+5*M.S(Sine/36)),M.R(0)),Alpha)
					ShW.C0 = ShW.C0:lerp(ShWC0,Alpha)
					PW.C0 = PW.C0:lerp(PWC0*CF.A(M.R(0+2.5*M.C(Sine/32)),0,0),Alpha)
				elseif(Personality==2)then -- shy
					RJ.C0 = RJ.C0:lerp(CF.N(-0.1,0+.05*M.C(Sine/36),0.1)*CF.A(M.R(0),M.R(-25.8),M.R(0)),Alpha)
					LS.C0 = LS.C0:lerp(CF.N(-1.1,0.2+.05*M.S(Sine/36),0.3)*CF.A(M.R(-25+5*M.S(Sine/36)),M.R(0),M.R(45-3*M.S(Sine/36))),Alpha)
					RS.C0 = RS.C0:lerp(CF.N(1.1,0.2+.05*M.S(Sine/36),0.3)*CF.A(M.R(-25+5*M.S(Sine/36)),M.R(0),M.R(-45+3*M.S(Sine/36))),Alpha)
					NK.C0 = NK.C0:lerp(CF.N(0.1,1.5,-0.2)*CF.A(M.R(-21.2+5*M.S(Sine/36)),M.R(-18.7),M.R(-7.1)),Alpha)
					ShW.C0 = ShW.C0:lerp(CF.N(0,-0.9,-0.7)*CF.A(M.R(0),M.R(0),M.R(0)),Alpha)
					PW.C0 = PW.C0:lerp(CF.N(0,0,0)*CF.A(M.R(9.9+2.5*M.C(Sine/32)),M.R(-90),M.R(0)),Alpha)
				elseif(Personality==3)then -- embarrassed
					RJ.C0 = RJ.C0:lerp(CF.N(-0.1,0+.05*M.C(Sine/36),0)*CF.A(M.R(0),M.R(-55.8),M.R(0)),Alpha)
					LS.C0 = LS.C0:lerp(CF.N(-0.8,0.2,-0.6)*CF.A(M.R(45+4*M.S(Sine/36)),M.R(-12.7),M.R(44.9)),Alpha)
					RS.C0 = RS.C0:lerp(CF.N(0.8,0.1,-0.4)*CF.A(M.R(79.8+2.5*M.S(Sine/36)),M.R(-37.7),M.R(-64.9)),Alpha)
					NK.C0 = NK.C0:lerp(CF.N(0,1.5,0)*CF.A(M.R(-18.9+5*M.S(Sine/36)),M.R(54.3),M.R(15.5)),Alpha)
					ShW.C0 = ShW.C0:lerp(CF.N(0,-0.8,-0.6)*CF.A(M.R(71.9),M.R(0),M.R(0)),Alpha)
					PW.C0 = PW.C0:lerp(CF.N(0,0,0)*CF.A(M.R(9.9+2.5*M.C(Sine/32)),M.R(-90),M.R(0)),Alpha)
				elseif(Personality==4)then -- proud
					RJ.C0 = RJ.C0:lerp(CF.N(0,0+.05*M.C(Sine/36),0)*CF.A(M.R(0),M.R(0),M.R(0)),Alpha)
					LS.C0 = LS.C0:lerp(CF.N(-1,0.3,-0.4)*CF.A(M.R(116.9+2.5*M.S(Sine/36)),M.R(6.8),M.R(68.1)),Alpha)
					RS.C0 = RS.C0:lerp(CF.N(1,0.4,-0.4)*CF.A(M.R(81.6+5*M.S(Sine/36)),M.R(-7.3),M.R(-76)),Alpha)
					NK.C0 = NK.C0:lerp(CF.N(0,1.5,0)*CF.A(M.R(0+5*M.S(Sine/36)),M.R(0),M.R(0)),Alpha)
					ShW.C0 = ShW.C0:lerp(CF.N(0,-0.8,-0.7)*CF.A(M.R(0),M.R(0),M.R(0)),Alpha)
					PW.C0 = PW.C0:lerp(CF.N(0,0,0)*CF.A(M.R(9.9+2.5*M.C(Sine/32)),M.R(-90),M.R(0)),Alpha)
				elseif(Personality==5)then -- lusty
					RJ.C0 = RJ.C0:lerp(CF.N(0,0+.05*M.C(Sine/36),0)*CF.A(M.R(0),M.R(0),M.R(0)),Alpha)
					LS.C0 = LS.C0:lerp(CF.N(-1.1,0.3+.05*M.C(Sine/36),0.2)*CF.A(M.R(-21.1),M.R(0),M.R(35.9)),Alpha)
					RS.C0 = RS.C0:lerp(CF.N(1.3,0.4+.05*M.C(Sine/36),-0.4)*CF.A(M.R(39.1),M.R(-1.7),M.R(-61.3)),Alpha)
					NK.C0 = NK.C0:lerp(CF.N(0,1.5,-0.1)*CF.A(M.R(-13.4+5*M.S(Sine/36)),M.R(0),M.R(0)),Alpha)
					ShW.C0 = ShW.C0:lerp(CF.N(0,-0.6,-0.7)*CF.A(M.R(57.3),M.R(0),M.R(0)),Alpha)
					if(math.random(1,45)==1)then
						PW.C0 = PW.C0:lerp(CF.N(0,0,0)*CF.A(M.R(9.9+M.RNG(-1,5)+2.5*M.C(Sine/32)),M.R(-90),M.R(0)),1)
					else
						PW.C0 = PW.C0:lerp(CF.N(0,0,0)*CF.A(M.R(9.9+2.5*M.C(Sine/32)),M.R(-90),M.R(0)),Alpha)
					end
				end
			elseif(Stance=='Sit')then
				RJ.C0 = RJ.C0:lerp(CF.N(0,-1.2+.05*M.C(Sine/36),-0.5)*CF.A(M.R(-10-1.5*M.S(Sine/36)),M.R(0),M.R(0)),Alpha)
				LH.C0 = LH.C0:lerp(CF.N(-0.4,-1.4-.05*M.C(Sine/36),0.3)*CF.A(M.R(100+1.5*M.S(Sine/36)),M.R(0),M.R(-15)),Alpha)
				RH.C0 = RH.C0:lerp(CF.N(0.4,-1.4-.05*M.C(Sine/36),0.3)*CF.A(M.R(100+1.5*M.S(Sine/36)),M.R(0),M.R(15)),Alpha)
				LS.C0 = LS.C0:lerp(CF.N(-0.9,0.3+.1*M.S(Sine/36),-0.3)*CF.A(M.R(44.1),M.R(0),M.R(25)),Alpha)
				RS.C0 = RS.C0:lerp(CF.N(0.9,0.3+.1*M.S(Sine/36),-0.3)*CF.A(M.R(44.1),M.R(0),M.R(-25)),Alpha)
				NK.C0 = NK.C0:lerp(CF.N(0,1.5,0)*CF.A(M.R(10),M.R(0),M.R(0+3*M.S(Sine/36))),Alpha)
				ShW.C0 = ShW.C0:lerp(CF.N(0,-0.8,-0.4)*CF.A(M.R(10),M.R(0),M.R(0)),Alpha)
				PW.C0 = PW.C0:lerp(CF.N(0,0,0)*CF.A(M.R(9.9),M.R(-90),M.R(0)),Alpha)
			elseif(Stance=='Lay')then
				RJ.C0 = clerp(RJ.C0,CFrame.new(0.00765379518, -2.37531877, 0.490188628, 0.999769688, 0.0154944565, -0.0148536079, -0.0155909583, 0.0486059822, -0.998696327, -0.0147522828, 0.998697996, 0.0488363579),Alpha)
				LH.C0 = clerp(LH.C0,CFrame.new(-0.556329548, -1.01782084, 0.0523337759, 0.936391771, -0.350610018, 0.0155910021, 0.350947887, 0.935132623, -0.0486090034, 0.00246314798, 0.0509886928, 0.998696208),Alpha)
				RH.C0 = clerp(RH.C0,CFrame.new(0.582500875, -1.16751981, 0.133858949, 0.663288414, 0.726090193, -0.181222796, -0.708711624, 0.53166908, -0.463741302, -0.240367457, 0.436028928, 0.867238283)*CF.A(math.rad(0+3*math.cos(Sine/30)),math.rad(4),0),Alpha)
				LS.C0 = clerp(LS.C0,CFrame.new(-1.20878398, 0.944466412, 0.12843433, 0.668268919, -0.739066303, 0.0848394409, -0.743897796, -0.663009524, 0.083873339, -0.00573859736, -0.119161807, -0.992858231),Alpha)
				RS.C0 = clerp(RS.C0,CFrame.new(1.20252943, 0.88095963, 0.00249876827, 0.668030798, 0.735071719, -0.115777783, 0.743981063, -0.662912428, 0.0839017108, -0.0150767555, -0.142185375, -0.989725292),Alpha)
				NK.C0 = clerp(NK.C0,CFrame.new(6.67600625e-06, 1.34367204, -0.326096922, 1, 0, 9.31322575e-10, -2.91038305e-11, 0.895097136, 0.445871502, 0, -0.445871502, 0.895096958)*CF.A(M.R(0+5*M.C(Sine/50)),0,0),Alpha)
				ShW.C0 = ShW.C0:lerp(CF.N(0,-0.8,-0.4)*CF.A(M.R(10),M.R(0),M.R(0)),Alpha)
				PW.C0 = PW.C0:lerp(CF.N(0,0,0)*CF.A(M.R(9.9),M.R(-90),M.R(0)),Alpha)
				if(math.random(1,200)==1)then
					PW.C0 = PW.C0:lerp(CF.N(0,0,0)*CF.A(M.R(9.9+M.RNG(-1,5)+2.5*M.C(Sine/32)),M.R(-90),M.R(0)),1)
				else
					PW.C0 = PW.C0:lerp(CF.N(0,0,0)*CF.A(M.R(9.9+2.5*M.C(Sine/32)),M.R(-90),M.R(0)),Alpha)
				end
			elseif(Stance=='AutoFel')then
				blush.Parent=face
				mouth.Texture='rbxassetid://394985292'
				reye.Texture='rbxassetid://2620012069'
				leye.Texture='rbxassetid://2620011770'
				if(Cumming)then
					RJ.C0 = RJ.C0:lerp(CF.N(0,-1.6,0)*CF.A(M.R(36.8+5*M.C(75/24)),M.R(0),M.R(0)),Alpha)
					LH.C0 = LH.C0:lerp(CF.N(-0.5,-1.4+.05*M.C(75/24),0.1+.1*M.C(75/24))*CF.A(M.R(60.4-5*M.C(75/24)),M.R(0),M.R(-5.3)),Alpha)
					RH.C0 = RH.C0:lerp(CF.N(0.4,-1.4+.05*M.C(75/24),0.1+.1*M.C(75/24))*CF.A(M.R(60.4-5*M.C(75/24)),M.R(0),M.R(8.2)),Alpha)
					LS.C0 = LS.C0:lerp(CF.N(-1.1,0.1,-0.5+.1*M.S(Sine/36))*CF.A(M.R(24.5),M.R(-27.9),M.R(40.4))*CF.A(M.R(0+1.5*M.S(Sine/36)),M.R(0+5*M.C(Sine/36)),M.R(-3+3*M.C(Sine/36))),Alpha)
					RS.C0 = RS.C0:lerp(CF.N(1.3,0,-0.2)*CF.A(M.R(43.3+2*M.C(Sine/54)),M.R(-14.1),M.R(-74.6))*CF.A(M.R(0+5*M.S(Sine/54)),0,M.R(0-5*M.S(Sine/54))),Alpha)
					NK.C0 = NK.C0:lerp(CF.N(0,1.2,-0.8)*CF.A(M.R(-58.8+10*M.C(75/24)),M.R(0),M.R(0))*CF.N(0,0,.2*M.C(75/24)),Alpha)
					ShW.C0 = ShW.C0:lerp(CF.N(0,-0.7,-0.7)*CF.A(M.R(70+1*M.C(75/24)),M.R(0),M.R(0)),Alpha)
					PW.C0 = PW.C0:lerp(CF.N(0,0,0)*CF.A(M.R(9.9),M.R(-90),M.R(0)),Alpha)
				else
					Pleasure=Pleasure+.05
					RJ.C0 = RJ.C0:lerp(CF.N(0,-1.6,0)*CF.A(M.R(36.8+5*M.C(Sine/24)),M.R(0),M.R(0)),Alpha)
					LH.C0 = LH.C0:lerp(CF.N(-0.5,-1.4+.05*M.C(Sine/24),0.1+.1*M.C(Sine/24))*CF.A(M.R(60.4-5*M.C(Sine/24)),M.R(0),M.R(-5.3)),Alpha)
					RH.C0 = RH.C0:lerp(CF.N(0.4,-1.4+.05*M.C(Sine/24),0.1+.1*M.C(Sine/24))*CF.A(M.R(60.4-5*M.C(Sine/24)),M.R(0),M.R(8.2)),Alpha)
					LS.C0 = LS.C0:lerp(CF.N(-1.1,0.1,-0.5+.1*M.S(Sine/16))*CF.A(M.R(24.5),M.R(-27.9),M.R(40.4))*CF.A(M.R(0+1.5*M.S(Sine/16)),M.R(0+5*M.C(Sine/16)),M.R(-3+3*M.C(Sine/16))),Alpha)
					RS.C0 = RS.C0:lerp(CF.N(1.3,0,-0.2)*CF.A(M.R(43.3+2*M.C(Sine/24)),M.R(-14.1),M.R(-74.6))*CF.A(M.R(0+5*M.S(Sine/24)),0,M.R(0-5*M.S(Sine/24))),Alpha)
					NK.C0 = NK.C0:lerp(CF.N(0,1.2,-0.8)*CF.A(M.R(-58.8+10*M.C(Sine/24)),M.R(0),M.R(0))*CF.N(0,0,.2*M.C(Sine/24)),Alpha)
					ShW.C0 = ShW.C0:lerp(CF.N(0,-0.7,-0.7)*CF.A(M.R(70+1*M.C(Sine/24)),M.R(0),M.R(0)),Alpha)
					PW.C0 = PW.C0:lerp(CF.N(0,0,0)*CF.A(M.R(9.9),M.R(-90),M.R(0)),Alpha)
				end
			end
		elseif(State == 'Walk')then
			ChangeStance(0)
			local Alpha = .2
			local wsVal = 4 
			local movement = 8
			RJ.C0 = RJ.C0:lerp(RJC0*CF.N(0,.05+Change/4*M.C(Sine/(wsVal/2)),0)*CF.A(M.R(-(Change*20)-movement/20*M.C(Sine/(wsVal/2)))*forwardvelocity,M.R(0+5*M.C(Sine/wsVal)),M.R(-(Change*20)-movement/20*M.C(Sine/(wsVal/2)))*sidevelocity+M.R(0-1*M.C(Sine/wsVal))),Alpha)
			NK.C0 = NK.C0:lerp(NKC0,Alpha)
			LS.C0 = LS.C0:lerp(LSC0*CF.N(0,0,0-.2*(movement/8)M.S(Sine/wsVal)*forwardvelocity)*CF.A(M.R(0+45(movement/8)*M.S(Sine/wsVal))*forwardvelocity,0,M.R(-5-5*M.C(Sine/wsVal))),Alpha)
			RS.C0 = RS.C0:lerp(RSC0*CF.N(0,0,0+.2*(movement/8)M.S(Sine/wsVal)*forwardvelocity)*CF.A(M.R(0-45(movement/8)*M.S(Sine/wsVal))*forwardvelocity,0,M.R(5+5*M.C(Sine/wsVal))),Alpha)
			ShW.C0 = ShW.C0:lerp(ShWC0,Alpha)
			PW.C0 = PW.C0:lerp(PWC0,Alpha)
		elseif(State == 'Jump')then
			ChangeStance(0)
			local Alpha = .1
			local idk = math.min(math.max(Root.Velocity.Y/50,-M.R(90)),M.R(90))
			LS.C0 = LS.C0:lerp(LSC0*CF.A(M.R(-5),0,M.R(-90)),Alpha)
			RS.C0 = RS.C0:lerp(RSC0*CF.A(M.R(-5),0,M.R(90)),Alpha)
			RJ.C0 = RJ.C0:lerp(RJC0*CF.A(math.min(math.max(Root.Velocity.Y/100,-M.R(45)),M.R(45)),0,0),Alpha)
			NK.C0 = NK.C0:lerp(NKC0*CF.A(math.min(math.max(Root.Velocity.Y/100,-M.R(45)),M.R(45)),0,0),Alpha)
			ShW.C0 = ShW.C0:lerp(ShWC0,Alpha)
			PW.C0 = PW.C0:lerp(PWC0,Alpha)
		elseif(State == 'Fall')then
			ChangeStance(0)
			local Alpha = .1
			local idk = math.min(math.max(Root.Velocity.Y/50,-M.R(90)),M.R(90))
			LS.C0 = LS.C0:lerp(LSC0*CF.A(M.R(-5),0,M.R(-90)+idk),Alpha)
			RS.C0 = RS.C0:lerp(RSC0*CF.A(M.R(-5),0,M.R(90)-idk),Alpha)
			RJ.C0 = RJ.C0:lerp(RJC0*CF.A(math.min(math.max(Root.Velocity.Y/100,-M.R(45)),M.R(45)),0,0),Alpha)
			NK.C0 = NK.C0:lerp(NKC0*CF.A(math.min(math.max(Root.Velocity.Y/100,-M.R(45)),M.R(45)),0,0),Alpha)
			ShW.C0 = ShW.C0:lerp(ShWC0,Alpha)
			PW.C0 = PW.C0:lerp(PWC0,Alpha)
		elseif(State == 'Paralyzed')then
			ChangeStance(0)
			-- paralyzed
		elseif(State == 'Sit')then
			local Alpha=.1
			RJ.C0 = RJ.C0:lerp(CF.N(0,0+.05*M.C(Sine/36),-0.5)*CF.A(M.R(-10-1.5*M.C(Sine/36)),M.R(0),M.R(0)),Alpha)
			LH.C0 = LH.C0:lerp(CF.N(-0.4,-1.4-.05*M.C(Sine/36),0.3)*CF.A(M.R(100+1.5*M.C(Sine/36)),M.R(0),M.R(-15)),Alpha)
			RH.C0 = RH.C0:lerp(CF.N(0.4,-1.4-.05*M.C(Sine/36),0.3)*CF.A(M.R(100+1.5*M.C(Sine/36)),M.R(0),M.R(15)),Alpha)
			LS.C0 = LS.C0:lerp(CF.N(-0.9,0.3,-0.3)*CF.A(M.R(44.1),M.R(0),M.R(25)),Alpha)
			RS.C0 = RS.C0:lerp(CF.N(0.9,0.3,-0.3)*CF.A(M.R(44.1),M.R(0),M.R(-25)),Alpha)
			NK.C0 = NK.C0:lerp(CF.N(0,1.5,0)*CF.A(M.R(10),M.R(0),M.R(0)),Alpha)
			ShW.C0 = ShW.C0:lerp(CF.N(0,-0.8,-0.4)*CF.A(M.R(10),M.R(0),M.R(0)),Alpha)
			PW.C0 = PW.C0:lerp(CF.N(0,0,0)*CF.A(M.R(9.9),M.R(-90),M.R(0)),Alpha)
			-- sit
		end
		if(tick()-lastBlink>2)then
			lastBlink=tick()
			reye.Texture='rbxassetid://2620012069'
			leye.Texture='rbxassetid://2620011770'
		end
	end

	Bar:TweenSize(UDim2.new((math.min(Pleasure,100)/100),0,1,0),Enum.EasingDirection.Out,Enum.EasingStyle.Linear,.1,true)

	if(math.ceil(Pleasure)<=100)then
		Text.Text = ("Pleasure!~ (%s%%)"):format(tostring(math.ceil(Pleasure)))
	end
	if((Pleasure>=100 or ManualCum and Pleasure>=100) and not Cumming)then
		if(Stance=='AutoFel')then -- AutoFellatio
			Attack=true
			Cumming=true
			ManualCum=false
			coroutine.wrap(function()
				for i = 1, 5 do
					local snd = Sound(Head,1409011903,1,1,false,true,true)
					wait(1)	
					snd:destroy()
				end
				Attack=false
				Cumming=false
				Pleasure=0
			end)()
		else
			Cumming=true
			delay(3,function()
				Pleasure=0
				Cumming=false
			end)
		end
	end

	for i,v in next, BloodPuddles do
		local mesh = i:FindFirstChild'CylinderMesh'
		BloodPuddles[i] = v + 1
		if(not mesh or mesh.Scale.X<=0)then
			i:destroy() 
			BloodPuddles[i] = nil
		else
			if(mesh.Scale.Z > 0)then
				mesh.Scale = mesh.Scale-V3.N(.005,0,.005)
			end
		end
	end
end
