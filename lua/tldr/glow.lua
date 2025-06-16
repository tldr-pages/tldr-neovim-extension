local Config = require("tldr.config")

local M = {}

function M.isExecutable()
    return vim.fn.executable(Config.get("glow")) == 1
end

-- Get system platform information
-- @return string platform name (Darwin, Linux, Windows, etc.)
local function get_platform()
    local handle = io.popen("uname -s")
    if handle == nil then
        return nil
    end
    local result = handle:read("*a"):gsub("\n", "")
    handle:close()

    -- Map uname output to glow release platform names
    local platform_map = {
        ["Linux"] = "Linux",
        ["Darwin"] = "Darwin",
        ["FreeBSD"] = "Freebsd",
        ["NetBSD"] = "Netbsd",
        ["OpenBSD"] = "Openbsd"
    }

    return platform_map[result]
end

-- Get system architecture
-- @return string architecture (x86_64, arm64, etc.)
local function get_architecture()
    local handle = io.popen("uname -m")
    if handle == nil then
        return nil
    end
    local result = handle:read("*a"):gsub("\n", "")
    handle:close()

    -- Map uname output to glow release architecture names
    local arch_map = {
        ["x86_64"] = "x86_64",
        ["amd64"] = "x86_64",
        ["arm64"] = "arm64",
        ["aarch64"] = "arm64",
        ["armv7l"] = "arm",
        ["armv6l"] = "arm",
        ["arm"] = "arm",
        ["i386"] = "i386",
        ["i686"] = "i386"
    }

    return arch_map[result]
end

-- Get the latest release version
-- @return string|nil
local function get_latest_release_version()
    local cmd =
        "curl --silent \"https://api.github.com/repos/charmbracelet/glow/releases/latest\" | grep '\"tag_name\":' | sed -E 's/.*\"v([^\\\"]+)\".*/\\1/'"
    local handle = io.popen(cmd)
    if handle == nil then
        return nil
    end
    local result = handle:read("*a")
    if result == nil then
        return nil
    end
    handle:close()
    result = result:gsub("\n", "")
    
    -- Return nil if result is empty or whitespace only
    if result == "" or result:match("^%s*$") then
        return nil
    end
    
    return result
end

-- Validate if platform and architecture combination is supported
-- @param platform string
-- @param architecture string
-- @return boolean
local function is_supported_combination(platform, architecture)
    local supported_combinations = {
        ["Darwin"] = {"x86_64", "arm64"},
        ["Freebsd"] = {"arm", "arm64", "i386", "x86_64"},
        ["Linux"] = {"arm", "arm64", "i386", "x86_64"},
        ["Netbsd"] = {"arm", "arm64", "i386", "x86_64"},
        ["Openbsd"] = {"x86_64", "arm64"}
    }

    local supported_archs = supported_combinations[platform]
    if not supported_archs then
        return false
    end

    for _, arch in ipairs(supported_archs) do
        if arch == architecture then
            return true
        end
    end

    return false
end

-- Download the latest release
-- @return nil
function M.install()
    local version = get_latest_release_version()
    if version == nil then
        vim.notify("Error: Could not get latest release", vim.log.levels.ERROR)
        return
    end

    local platform = get_platform()
    local architecture = get_architecture()

    -- Check if platform or architecture detection failed
    if platform == nil then
        vim.notify("Could not determine platform. Attempting installation via Go...", vim.log.levels.WARN)
        return M.install_with_go()
    end

    if architecture == nil then
        vim.notify("Could not determine system architecture. Attempting installation via Go...", vim.log.levels.WARN)
        return M.install_with_go()
    end

    -- Validate platform/architecture combination
    if not is_supported_combination(platform, architecture) then
        vim.notify(string.format("Error: Unsupported platform/architecture combination: %s/%s", platform, architecture),
            vim.log.levels.ERROR)
        vim.notify("Attempting installation via Go as fallback...", vim.log.levels.WARN)
        return M.install_with_go()
    end

    -- Construct download URL
    local download_url = string.format(
        "https://github.com/charmbracelet/glow/releases/download/v%s/glow_%s_%s_%s.tar.gz", version, version, platform,
        architecture)

    vim.notify("Downloading glow for " .. platform .. " " .. architecture .. "...", vim.log.levels.INFO)

    -- Create unique temporary files to avoid conflicts
    local tmp_prefix = "/tmp/glow_" .. os.time() .. "_" .. math.random(1000, 9999)
    local tmp_archive = tmp_prefix .. ".tar.gz"
    local tmp_dir = tmp_prefix .. "_extract"
    
    -- Create extraction directory
    vim.fn.mkdir(tmp_dir, "p")

    -- Download the archive
    local download_cmd = "curl -L -o " .. vim.fn.shellescape(tmp_archive) .. " " .. vim.fn.shellescape(download_url)
    local download_result = vim.fn.system(download_cmd)

    if vim.v.shell_error ~= 0 then
        vim.notify("Error: Failed to download glow. Please check your internet connection and try again.",
            vim.log.levels.ERROR)
        vim.fn.system("rm -rf " .. vim.fn.shellescape(tmp_archive) .. " " .. vim.fn.shellescape(tmp_dir))
        return
    end

    -- Extract the archive
    local extract_result = vim.fn.system("tar -xzf " .. vim.fn.shellescape(tmp_archive) .. " -C " .. vim.fn.shellescape(tmp_dir))
    if vim.v.shell_error ~= 0 then
        vim.notify("Error: Failed to extract glow archive", vim.log.levels.ERROR)
        vim.fn.system("rm -rf " .. vim.fn.shellescape(tmp_archive) .. " " .. vim.fn.shellescape(tmp_dir))
        return
    end

    -- Determine source binary name - it's inside a subdirectory
    local binary_subdir = string.format("glow_%s_%s_%s", version, platform, architecture)
    local source_binary = tmp_dir .. "/" .. binary_subdir .. "/glow"

    -- Check if extracted binary exists
    if vim.fn.filereadable(source_binary) == 0 then
        vim.notify("Error: Extracted binary not found at " .. source_binary, vim.log.levels.ERROR)
        vim.fn.system("rm -rf " .. vim.fn.shellescape(tmp_archive) .. " " .. vim.fn.shellescape(tmp_dir))
        return
    end

    -- Move binary to destination
    local dest_path = Config.get("glow")
    
    -- Ensure destination directory exists
    local dest_dir = vim.fn.fnamemodify(dest_path, ":h")
    if vim.fn.isdirectory(dest_dir) == 0 then
        vim.fn.mkdir(dest_dir, "p")
    end
    
    local move_cmd = "mv " .. vim.fn.shellescape(source_binary) .. " " .. vim.fn.shellescape(dest_path)
    local move_result = vim.fn.system(move_cmd)

    if vim.v.shell_error ~= 0 then
        vim.notify("Error: Failed to move glow binary to " .. dest_path, vim.log.levels.ERROR)
        vim.fn.system("rm -rf " .. vim.fn.shellescape(tmp_archive) .. " " .. vim.fn.shellescape(tmp_dir))
        return
    end

    -- Make executable (not needed on Windows, but won't hurt)
    vim.fn.system("chmod +x " .. vim.fn.shellescape(dest_path))

    -- Clean up
    vim.fn.system("rm -rf " .. vim.fn.shellescape(tmp_archive) .. " " .. vim.fn.shellescape(tmp_dir))

    vim.notify("Successfully installed glow to " .. dest_path, vim.log.levels.INFO)
end

-- Install glow using Go as a fallback method
-- @return nil
function M.install_with_go()
    -- Check if Go is available
    if vim.fn.executable("go") == 0 then
        vim.notify("Error: Go is not installed or not in PATH. Cannot install glow.", vim.log.levels.ERROR)
        vim.notify(
            "Please install Go from https://golang.org/ or install glow manually from https://github.com/charmbracelet/glow",
            vim.log.levels.INFO)
        vim.notify("Supported platforms for manual installation: Darwin, Freebsd, Linux, Netbsd, Openbsd",
            vim.log.levels.INFO)
        return
    end

    vim.notify("Installing glow using Go...", vim.log.levels.INFO)

    -- Install glow using go install
    local install_cmd = "go install github.com/charmbracelet/glow@latest"
    local install_result = vim.fn.system(install_cmd)

    if vim.v.shell_error ~= 0 then
        vim.notify("Error: Failed to install glow using Go.", vim.log.levels.ERROR)
        vim.notify("Go install output: " .. install_result, vim.log.levels.ERROR)
        vim.notify("Please try installing glow manually from https://github.com/charmbracelet/glow", vim.log.levels.INFO)
        return
    end

    -- Find the installed glow binary in GOPATH/GOBIN
    local home = os.getenv("HOME")
    if not home then
        vim.notify("Error: HOME environment variable not set", vim.log.levels.ERROR)
        return
    end
    
    local gopath = os.getenv("GOPATH") or (home .. "/go")
    local gobin = os.getenv("GOBIN") or (gopath .. "/bin")
    local glow_source = gobin .. "/glow"

    -- Check if the binary was installed
    if vim.fn.filereadable(glow_source) == 0 then
        vim.notify("Error: glow binary not found after Go installation at " .. glow_source, vim.log.levels.ERROR)
        vim.notify("Check your GOPATH/GOBIN configuration.", vim.log.levels.INFO)
        return
    end

    -- Copy to the configured location
    local dest_path = Config.get("glow")
    
    -- Ensure destination directory exists
    local dest_dir = vim.fn.fnamemodify(dest_path, ":h")
    if vim.fn.isdirectory(dest_dir) == 0 then
        vim.fn.mkdir(dest_dir, "p")
    end
    
    local copy_cmd = "cp " .. vim.fn.shellescape(glow_source) .. " " .. vim.fn.shellescape(dest_path)
    local copy_result = vim.fn.system(copy_cmd)

    if vim.v.shell_error ~= 0 then
        vim.notify("Error: Failed to copy glow binary to " .. dest_path, vim.log.levels.ERROR)
        vim.notify("You may need to manually copy from " .. glow_source .. " to " .. dest_path, vim.log.levels.INFO)
        return
    end

    -- Make executable
    vim.fn.system("chmod +x " .. vim.fn.shellescape(dest_path))

    vim.notify("Successfully installed glow using Go to " .. dest_path, vim.log.levels.INFO)
end

local function tmp_file()
    local tmp_dir = vim.fn.tempname()
    vim.fn.mkdir(tmp_dir, "p")
    return tmp_dir .. "/tldr.md"
end

-- Render markdown with glow
-- @param lines table list of lines
-- @return table rendered lines
function M.render(lines)
    local tmp = tmp_file()
    local file = io.open(tmp, "w")

    if file == nil then
        vim.notify("Error: Could not open file " .. tmp, vim.log.levels.ERROR)
        return lines
    end

    for _, line in ipairs(lines) do
        file:write(line .. "\n")
    end
    file:close()

    local result = vim.fn.systemlist(Config.get("glow") .. " --width=100 -s " .. Config.get("theme") .. " " .. tmp)
    vim.fn.delete(tmp)

    return result
end

-- Get detailed platform information for debugging
-- @return table
function M.get_platform_info()
    local platform = get_platform()
    local architecture = get_architecture()
    return {
        platform = platform,
        architecture = architecture,
        supported = platform ~= nil and architecture ~= nil and is_supported_combination(platform, architecture)
    }
end

return M

