local Saves, Cached = {}, {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local FolderName = "Dump-" .. HttpService:GenerateGUID(false)

local SourceFolder = FolderName .. "\\Source"
local GameSourceFolder = FolderName .. "\\GameSource"

local Blacklist = {}

local Allowed = {
    workspace,
    game.ReplicatedStorage,
    game.ReplicatedFirst,
    game.Lighting,
    game.StarterPlayer,
    game.StarterGui,
    game.Players,
}

local AgentContent = [[
# This is Roblox Client Exploit Automation

# Game Details

The main Roblox game environments and services used by this project are:

* `Players`
* `ReplicatedFirst`
* `ReplicatedStorage`
* `StarterPlayer`
* `StarterPlayerScripts`
* `Workspace`

# Game Explorer Tree

The complete game Explorer structure is documented in:

`Explorer.txt`

Use `Explorer.txt` as the reference when locating existing Instances, folders, modules, remotes, scripts, and other game objects.

# Required Documentation

**Force to read before working on this project:**

[AGENT.md](https://raw.githubusercontent.com/vita8it/Opengame/refs/heads/main/AGENT.md)

[Icon Lucide](https://github.com/vita8it/Turbopack/blob/main/Components/Lucide.lua)

The rules, coding conventions, framework usage, and project-specific instructions defined in `AGENT.md` must be followed when writing or modifying code for this project.

# Write your Script in "Source" Folder

`Source/` is the working directory for the Agent.

New scripts and modified scripts should be written in `Source/`.

# GameSource

`GameSource/` contains source code dumped from the Roblox game.

Use `GameSource/` as a reference when inspecting existing game scripts.

Do not use `GameSource/` as the Agent working directory.

Do not overwrite existing GameSource files unless explicitly requested.
]]

function Saves:IsAllowed(Object)
    for _, AllowedObject in Allowed do
        if Object == AllowedObject then
            return true
        end

        if Object:IsDescendantOf(AllowedObject) then
            return true
        end
    end

    return false
end

function Saves:IsBlacklisted(Object)
    return Blacklist[Object.Name] == true
end

function Saves:IsScript(Object)
    return Object:IsA("LocalScript")
        or Object:IsA("ModuleScript")
end

function Saves:IsOwnScript(Object)
    if not self:IsScript(Object) then
        return false
    end

    if not LocalPlayer then
        return false
    end

    if not Object:IsDescendantOf(Players) then
        return true
    end

    return Object:IsDescendantOf(LocalPlayer)
end

function Saves:SanitizeName(Name)
    Name = tostring(Name)

    Name = Name:gsub(
        '[<>:"/\\|?*]',
        "_"
    )

    Name = Name:gsub(
        "[%c]",
        "_"
    )

    Name = Name:gsub(
        "[%. ]+$",
        ""
    )

    if Name == "" then
        Name = "_"
    end

    local Reserved = {
        CON = true,
        PRN = true,
        AUX = true,
        NUL = true,

        COM1 = true,
        COM2 = true,
        COM3 = true,
        COM4 = true,
        COM5 = true,
        COM6 = true,
        COM7 = true,
        COM8 = true,
        COM9 = true,

        LPT1 = true,
        LPT2 = true,
        LPT3 = true,
        LPT4 = true,
        LPT5 = true,
        LPT6 = true,
        LPT7 = true,
        LPT8 = true,
        LPT9 = true,
    }

    if Reserved[Name:upper()] then
        Name = "_" .. Name
    end

    return Name
end

function Saves:CreateFolder(Path)
    if isfolder(Path) then
        return true
    end

    local Success, Result = pcall(
        makefolder,
        Path
    )

    if not Success then
        warn(
            "[CreateFolder] Failed:",
            Path,
            Result
        )

        return false
    end

    return true
end

function Saves:WriteFile(Path, Content)
    local Success, Result = pcall(
        writefile,
        Path,
        Content
    )

    if not Success then
        warn(
            "[WriteFile] Failed:",
            Path,
            Result
        )

        return false
    end

    return true
end

function Saves:HasScript(Object)
    if self:IsBlacklisted(Object) then
        return false
    end

    if self:IsScript(Object) then
        return self:IsOwnScript(Object)
    end

    for _, Child in Object:GetChildren() do
        if self:HasScript(Child) then
            return true
        end
    end

    return false
end

function Saves:BuildTree(Object)
    if self:IsBlacklisted(Object) then
        return nil
    end

    local Node = {
        Name = Object.Name,
        ClassName = Object.ClassName,
        Source = Object:GetFullName(),
        Children = {}
    }

    for _, Child in Object:GetChildren() do
        if not self:IsAllowed(Child) then
            continue
        end

        local ChildNode = self:BuildTree(Child)

        if ChildNode then
            Node.Children[
                #Node.Children + 1
            ] = ChildNode
        end
    end

    return Node
end

function Saves:TreeToString(Node, Prefix, IsLast)
    Prefix = Prefix or ""
    IsLast = IsLast == nil and true or IsLast

    local Result = {}

    if Node.Name == "game" then
        Result[#Result + 1] =
            Node.Name
            .. " : ("
            .. Node.ClassName
            .. ")"
    else
        local Branch =
            IsLast and "└── " or "├── "

        Result[#Result + 1] =
            Prefix
            .. Branch
            .. Node.Name
            .. " : ("
            .. Node.ClassName
            .. ")"
    end

    local Children = Node.Children
    local Count = #Children

    for Index, Child in Children do
        local Last = Index == Count

        local ChildPrefix

        if Node.Name == "game" then
            ChildPrefix = ""
        elseif IsLast then
            ChildPrefix = Prefix .. "    "
        else
            ChildPrefix = Prefix .. "│   "
        end

        local ChildResult = self:TreeToString(
            Child,
            ChildPrefix,
            Last
        )

        for Line in string.gmatch(
            ChildResult,
            "[^\n]+"
        ) do
            Result[#Result + 1] = Line
        end
    end

    return table.concat(
        Result,
        "\n"
    )
end

function Saves:GetObjectParts(Object)
    local Parts = {}
    local Current = Object

    while Current and Current ~= game do
        Parts[#Parts + 1] =
            self:SanitizeName(Current.Name)

        Current = Current.Parent
    end

    return Parts
end

function Saves:GetGameSourcePath(Object)
    local Parts = self:GetObjectParts(Object)

    local Path = GameSourceFolder

    for Index = #Parts, 1, -1 do
        Path ..= "\\" .. Parts[Index]
    end

    return Path
end

function Saves:CreateGameSourceFolder(Object)
    local Parts = self:GetObjectParts(Object)

    local Path = GameSourceFolder

    if not self:CreateFolder(FolderName) then
        return nil
    end

    if not self:CreateFolder(GameSourceFolder) then
        return nil
    end

    for Index = #Parts, 1, -1 do
        Path ..= "\\" .. Parts[Index]

        if not self:CreateFolder(Path) then
            return nil
        end
    end

    return Path
end

function Saves:SaveScript(Object)
    if not self:IsScript(Object) then
        return
    end

    if not self:IsAllowed(Object) then
        return
    end

    if not self:IsOwnScript(Object) then
        return
    end

    if self:IsBlacklisted(Object) then
        return
    end

    local Parent = Object.Parent

    if not Parent then
        return
    end

    local FolderPath =
        self:CreateGameSourceFolder(Parent)

    if not FolderPath then
        return
    end

    local FileName =
        self:SanitizeName(Object.Name)
        .. ".lua"

    local FilePath =
        FolderPath
        .. "\\"
        .. FileName

    task.spawn(function()
        local Success, Source = pcall(
            decompile,
            Object
        )

        if not Success then
            warn(
                "[Decompile] Failed:",
                Object:GetFullName(),
                Source
            )

            return
        end

        if type(Source) ~= "string" then
            warn(
                "[Decompile] Invalid source:",
                Object:GetFullName()
            )

            return
        end

        if not self:WriteFile(
            FilePath,
            Source
        ) then
            return
        end

        print(
            "[Decompile] Saved:",
            Object:GetFullName()
        )
    end)

    return FilePath
end

function Saves:BuildFilesystem(Object)
    if self:IsBlacklisted(Object) then
        return
    end

    if self:IsScript(Object) then
        self:SaveScript(Object)
        return
    end

    if not self:HasScript(Object) then
        return
    end

    for _, Child in Object:GetChildren() do
        if not self:IsAllowed(Child) then
            continue
        end

        self:BuildFilesystem(Child)
    end
end

function Saves:SaveExplorer()
    Cached.Tree = {
        Name = "game",
        ClassName = "DataModel",
        Source = "game",
        Children = {}
    }

    for _, Object in Allowed do
        local Node = self:BuildTree(Object)

        if Node then
            Cached.Tree.Children[
                #Cached.Tree.Children + 1
            ] = Node
        end
    end

    Saves.Tree = self:TreeToString(
        Cached.Tree
    )

    local ExplorerPath =
        FolderName .. "\\Explorer.txt"

    if not self:WriteFile(
        ExplorerPath,
        Saves.Tree
    ) then
        return
    end

    print(
        "[Explorer] Saved:",
        ExplorerPath
    )
end

function Saves:SaveAgent()
    local AgentPath =
        FolderName .. "\\AGENT.md"

    if not self:WriteFile(
        AgentPath,
        AgentContent
    ) then
        return false
    end

    print(
        "[Agent] Saved:",
        AgentPath
    )

    return true
end

function Saves:CollectScripts()
    Cached.Builder.Scripts = {}

    for _, Object in game:GetDescendants() do
        if not self:IsScript(Object) then
            continue
        end

        if not self:IsAllowed(Object) then
            continue
        end

        if not self:IsOwnScript(Object) then
            continue
        end

        if self:IsBlacklisted(Object) then
            continue
        end

        local Parent = Object.Parent

        if not Parent then
            continue
        end

        local FilePath =
            self:GetGameSourcePath(Parent)
            .. "\\"
            .. self:SanitizeName(Object.Name)
            .. ".lua"

        Cached.Builder.Scripts[
            #Cached.Builder.Scripts + 1
        ] = {
            Name = Object.Name,
            ClassName = Object.ClassName,
            Path = Object:GetFullName(),
            File = FilePath
        }
    end
end

function Saves:Build()
    Cached.Builder = {
        Name = FolderName,
        Source = SourceFolder,
        GameSource = GameSourceFolder,
        Explorer = nil,
        Agent = FolderName .. "\\AGENT.md",
        Scripts = {}
    }

    if not self:CreateFolder(
        FolderName
    ) then
        error(
            "Unable to create dump folder: "
            .. FolderName
        )
    end

    if not self:CreateFolder(
        SourceFolder
    ) then
        error(
            "Unable to create Source folder: "
            .. SourceFolder
        )
    end

    if not self:CreateFolder(
        GameSourceFolder
    ) then
        error(
            "Unable to create GameSource folder: "
            .. GameSourceFolder
        )
    end

    print(
        "[Dump] Folder:",
        FolderName
    )

    print(
        "[Source] Agent:",
        SourceFolder
    )

    print(
        "[GameSource] Game:",
        GameSourceFolder
    )

    self:SaveAgent()

    self:SaveExplorer()

    Cached.Builder.Explorer =
        Saves.Tree

    for _, Object in Allowed do
        self:BuildFilesystem(Object)
    end

    self:CollectScripts()

    return Cached.Builder
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Game Dumper",
    SubTitle = "by TNK",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 420),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "box" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local CustomFolderName = ""

Tabs.Main:AddInput("FolderNameInput", {
    Title = "Custom Folder Name",
    Default = "",
    Placeholder = "Leave empty for auto-generated GUID",
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        CustomFolderName = Value
    end
})

Tabs.Main:AddButton({
    Title = "Start Full Game Dump",
    Description = "Dumps scripts to Source & GameSource folders + Explorer tree",
    Callback = function()
        Fluent:Notify({
            Title = "Dump Started",
            Content = "Dumping scripts and creating AGENT.md...",
            Duration = 4
        })

        if CustomFolderName ~= "" then
            FolderName = Saves:SanitizeName(CustomFolderName)
            SourceFolder = FolderName .. "\\Source"
            GameSourceFolder = FolderName .. "\\GameSource"
        else
            FolderName = "Dump-" .. HttpService:GenerateGUID(false)
            SourceFolder = FolderName .. "\\Source"
            GameSourceFolder = FolderName .. "\\GameSource"
        end

        task.spawn(function()
            local Success, Result = pcall(function()
                return Saves:Build()
            end)

            if Success then
                Fluent:Notify({
                    Title = "Dump Completed!",
                    Content = "Folder: " .. FolderName .. "\nScripts: " .. tostring(#Result.Scripts),
                    Duration = 6
                })
            else
                Fluent:Notify({
                    Title = "Dump Failed",
                    Content = tostring(Result),
                    Duration = 6
                })
            end
        end)
    end
})

Tabs.Main:AddButton({
    Title = "Dump Explorer Tree Only",
    Description = "Saves Explorer.txt & AGENT.md without decompiling scripts",
    Callback = function()
        if CustomFolderName ~= "" then
            FolderName = Saves:SanitizeName(CustomFolderName)
        else
            FolderName = "Dump-" .. HttpService:GenerateGUID(false)
        end

        Saves:CreateFolder(FolderName)
        Saves:SaveAgent()
        Saves:SaveExplorer()

        Fluent:Notify({
            Title = "Explorer & Agent Saved",
            Content = "Saved to " .. FolderName,
            Duration = 5
        })
    end
})

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("TNKDumper")
SaveManager:SetFolder("TNKDumper/configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Fluent:SetTheme("Darker")

Window:SelectTab(1)

SaveManager:LoadAutoloadConfig()